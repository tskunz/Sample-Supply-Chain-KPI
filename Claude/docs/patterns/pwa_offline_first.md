# PWA Offline-First — Implementation Pattern

> **For Claude Code:** Read this when implementing service worker and offline capabilities.

## The Core Strategy: Cache on Cook Start

This app is used outdoors next to a smoker. Cell service may be spotty. The design
principle is: **fetch what you need when you start the cook, then run offline.**

### What Needs Network
- Weather API fetch (one call at cook start)
- That's it for V1. All physics runs client-side.

### What Runs Offline
- All predictions (physics kernel + Monte Carlo)
- Probe logging
- Intervention logging
- Post-cook report generation
- Cook history viewing

## Service Worker Architecture

```
┌─────────────────────────────────────────┐
│  App Shell (cached on install)          │
│  ├── index.html                         │
│  ├── app.js (bundled React)             │
│  ├── styles.css                         │
│  └── physics worker (Web Worker)        │
├─────────────────────────────────────────┤
│  Runtime Cache                          │
│  ├── Weather data (cached per cook)     │
│  └── Equipment profiles                 │
├─────────────────────────────────────────┤
│  Persistent Storage                     │
│  ├── Cook logs (IndexedDB or SQLite)    │
│  └── User preferences                  │
└─────────────────────────────────────────┘
```

### Registration
```javascript
// In main app entry
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js')
    .then(reg => console.log('SW registered'))
    .catch(err => console.error('SW failed:', err));
}
```

### Service Worker Strategy
```javascript
// sw.js

const CACHE_NAME = 'pitmaster-v1';
const APP_SHELL = [
  '/',
  '/index.html',
  '/static/js/bundle.js',
  '/static/css/main.css',
  '/manifest.json',
];

// Install: cache app shell
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(APP_SHELL))
  );
});

// Fetch: app shell from cache, API calls network-first with cache fallback
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);

  if (url.pathname.startsWith('/api/weather')) {
    // Network-first for weather, fall back to cached
    event.respondWith(
      fetch(event.request)
        .then(response => {
          const clone = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
          return response;
        })
        .catch(() => caches.match(event.request))
    );
  } else {
    // Cache-first for app shell
    event.respondWith(
      caches.match(event.request)
        .then(response => response || fetch(event.request))
    );
  }
});
```

## Web Worker for Physics (Performance)

Monte Carlo with 5,000 iterations should NOT block the UI thread.
Run the physics engine in a Web Worker.

```javascript
// physics.worker.js
self.onmessage = function(e) {
  const { params, equipment, weather } = e.data;
  // Run Monte Carlo (compiled from Python via Pyodide, or rewritten in JS)
  const result = runMonteCarlo(params, equipment, weather);
  self.postMessage(result);
};

// In React component
const worker = new Worker('/physics.worker.js');
worker.postMessage({ params, equipment, weather });
worker.onmessage = (e) => {
  setPrediction(e.data);  // Update UI with results
};
```

### Architecture Decision: Python Backend vs Client-Side JS
Two valid approaches for V1:

**Option A: Python backend (FastAPI) + React frontend**
- Physics stays in Python (NumPy/SciPy)
- Predictions require API call → not truly offline
- Simpler physics code, harder offline story

**Option B: Physics in JavaScript (Web Worker) + Python for data only**
- Physics rewritten in JS (or compiled via Pyodide)
- Truly offline predictions after initial load
- Harder to maintain two physics implementations

**Recommended for V1:** Option A with weather caching. The "offline" requirement
means the physics API endpoint should also be cacheable — cache the prediction
result for the current cook parameters. If the user goes offline mid-cook, the
initial prediction is still available. Live updates (Phase 3) will need network.

## PWA Manifest

```json
{
  "name": "The Predictive Pitmaster",
  "short_name": "Pitmaster",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#1a1a1a",
  "theme_color": "#ff6b35",
  "icons": [
    { "src": "/icons/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
```

## Mobile-First UX Constraints
- **High contrast:** Used in direct sunlight. Dark background with bright text/elements.
- **Large touch targets:** Minimum 48x48px. User is wearing BBQ gloves.
- **No tiny inputs:** Temperature entry should use large number pad, not keyboard.
- **Orientation:** Support both portrait and landscape. Nerd Mode timeline benefits from landscape.
