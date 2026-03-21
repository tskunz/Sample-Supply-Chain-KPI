# TJ Data Kitchen — The Predictive Pitmaster

## Project Identity
Uncertainty planner for BBQ cook times. Physics-informed simulation, NOT a prediction engine.
Messaging: "We quantify uncertainty so you can plan dinner." NOT "We predict your cook time."

## Scope: Phase 1 MVP ONLY
- Layers 1 (Physics Kernel) + 3 (Monte Carlo) only. Layer 2 is STUBBED (no ML).
- BBQ/Smoking only. No sous vide, no oven roasting.
- Personal tool. No auth, no multi-user, no app store.
- PWA only. Mobile-first. Offline-capable after initial weather fetch.

## Tech Stack
- **Frontend:** React — mobile-first responsive PWA, service worker for offline
- **Backend:** Python (FastAPI)
- **Simulation:** NumPy/SciPy (physics kernel + Monte Carlo)
- **Weather:** OpenWeather API (free tier)
- **Storage:** SQLite for cook logs
- **Deployment:** PWA with service worker

## Documentation Strategy (FOLLOW THIS ORDER)
1. **Project Bible:** `tj_data_kitchen_v1_2_FINAL_MERGED.md` — architecture decisions,
   build order, data schema, design constraints. READ FIRST for any architecture question.
2. **Domain References:** `docs/refs/` — physics formulas, food science constants, API
   contracts. **READ BEFORE writing any simulation, physics, or API integration code.**
3. **Implementation Patterns:** `docs/patterns/` — tested code patterns for this project.
4. **Resolved Decisions:** `docs/decisions/resolved_questions.md` — 13 committee-resolved
   technical questions. Check BEFORE making any architecture or modeling decision.
5. **Built-in Knowledge:** NumPy, SciPy, FastAPI, React, SQLite — you know these.
   Do NOT web search for standard library syntax.
6. **Web Search:** LAST RESORT — only for novel bugs or version-specific breaking changes.

## Critical Rule: Domain Constants
**If a physics constant, coefficient, or food science value is NOT in `docs/refs/`, FLAG IT.**
Do NOT guess. Do NOT substitute training knowledge for domain-specific values.
Say: "I need a value for [X] — it's not in the reference docs."

## Build Order (from Project Bible Section 13)
1. Physics kernel (1D heat diffusion, textbook diffusivity per protein/cut)
2. Biological noise (stochastic variability in diffusivity parameters)
3. Altitude correction (boiling point from user location)
4. Monte Carlo wrapper (5,000 iterations, noisy inputs)
5. Backward planner ("Dinner at X" → "Start at Y", include rest time)
6. Stall hazard model (logistic, physics-informed priors, temp-gated 140–185°F)
7. Stall detection override (slope monitor, dT/dt < 0.02°F/min for ≥10 min)
8. Intervention recommendations (wrap prompt, tradeoff display, model adjustment)
9. Weather API integration (ambient, humidity, wind, altitude — cache for offline)
10. Equipment profiles (5 presets + custom, each defines variance params)
11. Cook logging interface (all Section 7D fields, structured wrap events)
12. Normal Person Mode (single screen default, stall messaging, wrap prompt)
13. Nerd Mode (timeline, confidence bands, stall probability gauge, slope chart)
14. Post-cook report (predicted vs actual, residuals, auto-save to history)
15. Hold phase calculator (Newton's Law of Cooling for rest)

## What NOT to Build
- No Bluetooth probe integration
- No real-time Bayesian updating (Phase 3)
- No live dashboard (Phase 3)
- No fire-out detection (Phase 3)
- No sous vide or oven modules (Phase 4)
- No community features (Phase 4)
- No user auth or multi-user
- No app store deployment
- No ML models — Layer 2 is STUBBED with message: "Collecting data — X more cooks needed"

## Coding Standards
- Python: Type hints on all functions. Docstrings on public functions.
- Physics code: Include unit comments on every numeric value (e.g., `# m²/s`, `# °F`).
- Tests: `pytest tests/` after any logic changes. Physics kernel needs unit tests with
  known analytical solutions (e.g., semi-infinite solid with constant surface temp).
- Commits: Commit after each build step completes. Message format: `feat(step-N): description`
- Data persistence: Every cook logged, stored locally, exportable as CSV/JSON.

## UX Constraints
- **Mobile-first.** Used outdoors next to a smoker in sunlight. High contrast, large touch targets.
- **Two modes from day one.** Normal Person Mode is DEFAULT. Nerd Mode behind labeled toggle.
- **Intervention prompts are non-judgmental.** Wrap and no-wrap are both valid choices.
- **Offline-capable.** Core predictions work without internet after initial weather fetch.

## Growing the Reference Docs
When you discover something during implementation that required a web search and will be
needed again, ADD it to the appropriate file in `docs/refs/`. Format:
Source → Key values → Physical intuition → Implementation sketch → Uncertainty bounds.
