# Monte Carlo Simulation — Implementation Patterns

> **For Claude Code:** Read this before implementing Build Step 4 (Monte Carlo wrapper).

## Architecture

Monte Carlo is Layer 3. It wraps the Layer 1 physics kernel and produces the uncertainty
bands that DEFINE the product. This is what makes it an uncertainty planner, not a
point predictor.

```
For each of 5,000 iterations:
    1. Sample noisy inputs (diffusivity, thickness, smoker temp, weather)
    2. Run physics kernel with noisy inputs
    3. Record predicted finish time
→ Output: 10th, 50th, 90th percentile finish times
```

## Input Noise Sources

Each iteration perturbs these inputs. All noise parameters should come from
`docs/refs/food_science_constants.md` — do NOT invent distributions.

| Input | Distribution | Noise Range | Rationale |
|-------|-------------|-------------|-----------|
| Thermal diffusivity (α) | Uniform | ±TODO% of base value | Biological variability |
| Meat thickness | Normal | σ = TODO | Measurement uncertainty |
| Initial meat temp | Normal | σ = TODO °F | Fridge variance |
| Smoker temp setpoint | See equipment profiles | Varies by equipment | Equipment stability |
| Wind speed | Normal | ±TODO of fetched value | Weather API uncertainty |
| Humidity | Normal | ±TODO of fetched value | Weather API uncertainty |

### Equipment-Specific Smoker Temp Noise

| Equipment Type | Temp Noise Model | σ (°F) | Notes |
|---------------|-----------------|--------|-------|
| Offset stick-burner | Normal | ~25-30 | Massive swings, high skill floor |
| Pellet grill | Normal | ~5-8 | PID-controlled, tight |
| Kamado | Normal | ~8-12 | Great insulation |
| Weber Smokey Mountain | Normal | ~12-18 | Well-characterized baseline |
| Custom | User-defined | User input | Manual variance entry |

## Implementation Pattern

```python
import numpy as np
from dataclasses import dataclass

@dataclass
class MonteCarloResult:
    p10: float   # minutes — optimistic estimate
    p50: float   # minutes — median estimate
    p90: float   # minutes — conservative estimate
    all_times: np.ndarray  # raw results for distribution plots (Nerd Mode)

def run_monte_carlo(
    base_params: dict,        # deterministic inputs from user
    equipment_profile: dict,  # variance parameters for this smoker type
    weather: dict,            # fetched weather data
    n_iterations: int = 5000,
    seed: int | None = None,
) -> MonteCarloResult:
    """
    Run Monte Carlo simulation over physics kernel.
    Returns percentile estimates for finish time.
    """
    rng = np.random.default_rng(seed)
    finish_times = np.zeros(n_iterations)

    for i in range(n_iterations):
        # Sample noisy inputs
        noisy = perturb_inputs(base_params, equipment_profile, weather, rng)

        # Run physics kernel with noisy inputs
        # NOTE: This includes stall model — stall onset varies per iteration
        finish_times[i] = simulate_cook_with_stall(noisy)

    return MonteCarloResult(
        p10=float(np.percentile(finish_times, 10)),
        p50=float(np.percentile(finish_times, 50)),
        p90=float(np.percentile(finish_times, 90)),
        all_times=finish_times,
    )
```

## Performance Notes

- 5,000 iterations is computationally trivial for 1D heat diffusion (~seconds)
- V1: Fixed 5,000 iterations (converges reliably at this problem scale)
- V2+: Adaptive convergence — stop when CI width stabilizes < 1 min over last 500 samples
- Physics kernel should be vectorizable but start with loop for clarity, optimize if needed

## Output Format for UX

### Normal Person Mode
```
Finish: p50 as primary display
Confidence: "HIGH" if (p90 - p10) < 60 min, "MEDIUM" if < 120, "LOW" if > 120
Start time: backward-planned from p90 (conservative) to target dinner time
```

### Nerd Mode
```
Full distribution histogram
10th / 50th / 90th percentile lines
Phase breakdown: time-in-smoke, time-in-stall, time-in-rest
Confidence band width over time (narrowing as cook progresses — Phase 3)
```

## Backward Planning (Build Step 5)

This is the PRIMARY UX entry point for Normal Person Mode.

```python
def backward_plan(
    target_eat_time: datetime,
    mc_result: MonteCarloResult,
    rest_duration_min: float,   # from hold phase calculator
    fire_startup_min: float = 30,  # time to get smoker to temp
) -> datetime:
    """
    Work backwards from 'dinner at 6 PM' to 'start fire at X'.
    Uses p90 (conservative) to ensure dinner is on time.
    """
    total_minutes = mc_result.p90 + rest_duration_min + fire_startup_min
    start_time = target_eat_time - timedelta(minutes=total_minutes)
    return start_time
```

## Seed Reproducibility
- Allow optional seed for debugging and testing
- In production, use `None` (random seed each run)
- For post-cook reports, save the seed used so the user can reproduce the prediction
