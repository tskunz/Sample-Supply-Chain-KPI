# OpenWeather API — Contract Reference

> **For Claude Code:** Read this before implementing Build Step 9 (Weather API integration).
> Use the EXACT endpoints and response fields documented here.

## Plan: Free Tier (v2.5)
- **Rate limit:** 60 calls/minute, 1,000 calls/day
- **Cost:** $0
- **Endpoint:** `api.openweathermap.org/data/2.5/weather`

This is sufficient for Phase 1. We fetch once at cook start and cache.

## Current Weather Endpoint

```
GET https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={API_KEY}&units=imperial
```

### Response Fields We Need

```json
{
  "main": {
    "temp": 72.5,          // °F (with units=imperial)
    "humidity": 65,        // % relative humidity
    "pressure": 1013.25    // hPa (sea level pressure)
  },
  "wind": {
    "speed": 8.2,          // mph (with units=imperial)
    "gust": 12.1           // mph — may be absent
  },
  "coord": {
    "lat": 32.78,
    "lon": -96.80
  }
}
```

### Fields We Extract

| Our Field | API Path | Unit | Used For |
|-----------|----------|------|----------|
| ambient_temp | main.temp | °F | Heat loss calculation |
| humidity | main.humidity | % | Stall prediction (β₁) |
| pressure | main.pressure | hPa | Altitude derivation |
| wind_speed | main.wind.speed | mph | Stall prediction (β₂), convective cooling |
| wind_gust | main.wind.gust | mph | Monte Carlo noise (if present) |

## Altitude from Pressure

OpenWeather free tier does NOT return altitude directly. Derive from pressure:

```python
def altitude_from_pressure(pressure_hpa: float) -> float:
    """
    Hypsometric formula: approximate altitude from sea-level pressure.
    Returns altitude in feet.
    """
    # Standard atmosphere: P = P0 * (1 - 0.0000225577 * h)^5.25588
    # Inverted: h = (1 - (P/P0)^(1/5.25588)) / 0.0000225577
    P0 = 1013.25  # standard sea-level pressure, hPa
    h_meters = (1 - (pressure_hpa / P0) ** (1 / 5.25588)) / 0.0000225577
    return h_meters * 3.28084  # meters to feet
```

**Note:** This is approximate. If the user's GPS provides altitude directly,
prefer that over the pressure derivation. Fallback chain:
1. Device GPS altitude (if available via browser Geolocation API)
2. Pressure-derived altitude (from OpenWeather)
3. User manual input

## Caching Strategy (Offline-First)

```python
# On cook start:
# 1. Fetch current weather
# 2. Cache response to SQLite: weather_cache table
# 3. Set up 30-minute polling interval
# 4. If network unavailable, use cached data — core predictions still work

# Cache schema:
# weather_cache(cook_id, timestamp, temp_f, humidity_pct, wind_mph, 
#               wind_gust_mph, pressure_hpa, altitude_ft)
```

### PWA Service Worker Strategy
- Weather fetch is the ONLY network-dependent feature in V1
- If offline at cook start: prompt user to enter ambient temp, humidity, wind manually
- All physics calculations run client-side — no server dependency for predictions

## Error Handling

```python
# API errors to handle:
# 401 — Invalid API key
# 429 — Rate limit exceeded (60/min or 1000/day)
# 5xx — Server error
#
# On any error: fall back to manual input, do NOT block cook start
# The app must ALWAYS allow starting a cook, even without weather data
```

## Future: OpenWeather One Call 3.0 (Phase 2+)
- Costs: 1,000 calls/day free, then $0.0015/call
- Adds: hourly forecast (useful for long cooks), historical weather
- Endpoint: `api.openweathermap.org/data/3.0/onecall`
- Would enable: weather forecast integration for 12+ hour cook planning
- NOT needed for Phase 1
