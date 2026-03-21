# FastAPI Project Structure — Implementation Pattern

> **For Claude Code:** Follow this directory layout when scaffolding the backend.

## Directory Layout

```
backend/
├── main.py                     # FastAPI app entry, CORS, middleware
├── config.py                   # Settings, API keys, feature flags
├── database.py                 # SQLite connection, init from schema
├── models/
│   ├── __init__.py
│   ├── cook.py                 # Pydantic models for cook sessions
│   ├── prediction.py           # Pydantic models for MC results
│   └── weather.py              # Pydantic models for weather data
├── routers/
│   ├── __init__.py
│   ├── cooks.py                # CRUD for cook sessions
│   ├── predictions.py          # Run simulation, return results
│   └── weather.py              # Fetch + cache weather
├── physics/
│   ├── __init__.py
│   ├── heat_diffusion.py       # 1D Fourier solver (Build Step 1)
│   ├── stall_model.py          # Hazard model + detection (Build Steps 6-7)
│   ├── monte_carlo.py          # MC wrapper (Build Step 4)
│   ├── backward_planner.py     # Dinner-at-X logic (Build Step 5)
│   ├── rest_phase.py           # Newton's cooling (Build Step 15)
│   ├── interventions.py        # Wrap adjustment logic (Build Step 8)
│   └── constants.py            # ALL physics constants from docs/refs/
├── services/
│   ├── __init__.py
│   ├── weather_service.py      # OpenWeather client + caching
│   └── equipment.py            # Equipment profile lookups
└── tests/
    ├── test_heat_diffusion.py  # Known analytical solutions
    ├── test_stall_model.py     # Boundary conditions, gating
    ├── test_monte_carlo.py     # Convergence, seed reproducibility
    ├── test_backward_planner.py
    └── test_rest_phase.py
```

## Key Principles

### constants.py Is the Single Source of Truth
ALL physics constants, thermal diffusivity values, equipment profiles, and coefficients
live in `physics/constants.py`. This file is populated FROM `docs/refs/` files.
No magic numbers anywhere else in the codebase.

```python
# physics/constants.py
# ALL values traced to docs/refs/ sources. See each ref file for citations.

THERMAL_DIFFUSIVITY = { ... }    # from docs/refs/food_science_constants.md
STALL_COEFFICIENTS = { ... }     # from docs/refs/stall_thermodynamics.md
WRAP_EVAPORATION = { ... }       # from docs/refs/stall_thermodynamics.md
TARGET_TEMPS = { ... }           # from docs/refs/food_science_constants.md
EQUIPMENT_PROFILES = { ... }     # from Project Bible Section 6
```

### Router Pattern
```python
# routers/predictions.py
from fastapi import APIRouter, HTTPException
from ..physics.monte_carlo import run_monte_carlo
from ..models.prediction import PredictionRequest, PredictionResponse

router = APIRouter(prefix="/api/predictions", tags=["predictions"])

@router.post("/", response_model=PredictionResponse)
async def create_prediction(request: PredictionRequest):
    """Run Monte Carlo simulation and return uncertainty bands."""
    ...
```

### CORS for PWA
```python
# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Predictive Pitmaster API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Tighten in production
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Database Init
```python
# database.py
import sqlite3
from pathlib import Path

DB_PATH = Path("data/pitmaster.db")
SCHEMA_PATH = Path("docs/patterns/sqlite_cook_log_schema.sql")

def init_db():
    DB_PATH.parent.mkdir(exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.executescript(SCHEMA_PATH.read_text())
    conn.close()
```

## Testing Strategy

Physics kernel tests should use **known analytical solutions**:
- Semi-infinite solid with constant surface temp → exact erf() solution
- Verify finite difference converges to analytical as dx → 0
- Stall model: test temperature gating returns 0 outside 140-185°F
- Monte Carlo: verify p10 < p50 < p90 for any valid input
- Backward planner: verify start_time < dinner_time for all cases
- Rest phase: verify temp monotonically decreases after carryover peak
