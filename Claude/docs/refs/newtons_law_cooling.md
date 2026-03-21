# Newton's Law of Cooling — Rest Phase Reference

> **For Claude Code:** Read this before implementing Build Step 15 (hold phase calculator).

## The Physics

After pulling meat from the smoker, temperature continues to rise (carryover cooking)
then decays toward ambient. Newton's Law of Cooling models this decay:

```
T(t) = T_ambient + (T_initial - T_ambient) × e^(-k × t)
```

- `T(t)` = meat temperature at time t
- `T_ambient` = environment temperature (cooler, Cambro, room, oven)
- `T_initial` = temperature when removed from smoker (pull temp)
- `k` = cooling constant (depends on insulation, meat mass, geometry)
- `t` = time since removed from heat

## Carryover Cooking

Meat temperature RISES after pulling due to thermal gradient — the exterior is hotter
than the center, and heat continues conducting inward.

> **TODO: Research typical carryover rise by cut size**

| Cut | Typical Carryover | Duration | Source |
|-----|-------------------|----------|--------|
| Brisket (12+ lb) | TODO (~5-10°F?) | TODO (~15-30 min?) | |
| Pork butt (8 lb)  | TODO | TODO | |
| Ribs               | TODO (~minimal) | TODO | |

## Rest Environment Constants

> **TODO: Populate cooling constant k from empirical data or research.
> Meathead Goldwyn (amazingribs.com) has published instrumented rest data.**

| Environment | T_ambient (°F) | k estimate (1/min) | Notes | Source |
|-------------|---------------|-------------------|-------|--------|
| Countertop (no wrap) | ~70 | TODO | Fastest cooling | |
| Wrapped in towel     | ~70 | TODO | Moderate insulation | |
| Cooler (no heat source) | ~70 initial, rising | TODO | Excellent insulation | |
| Cambro              | ~70 initial, rising | TODO | Commercial insulation | |
| Oven at 150°F       | 150 | TODO | Active hold — near-constant | |

### Safety Floor
- **145°F** is the USDA minimum safe holding temperature for meat
- Rest calculation must alert when predicted temp drops below 145°F
- For passive holds (cooler/Cambro), calculate and display safe hold duration

## Implementation Skeleton

```python
import numpy as np

def rest_temperature(
    T_pull: float,           # pull temp, °F
    T_ambient: float,        # rest environment temp, °F
    k: float,                # cooling constant, 1/min
    carryover_rise: float,   # expected carryover, °F
    time_minutes: float,     # time since pull
) -> float:
    """
    Model rest phase temperature.
    Phase 1: carryover rise (simplified as linear ramp).
    Phase 2: exponential decay per Newton's Law.
    """
    # Simplified carryover model
    carryover_duration = 20.0  # minutes — TODO: make this a function of mass
    if time_minutes < carryover_duration:
        # Linear rise to peak
        T_peak = T_pull + carryover_rise
        return T_pull + (carryover_rise * time_minutes / carryover_duration)
    else:
        # Exponential decay from peak
        T_peak = T_pull + carryover_rise
        t_decay = time_minutes - carryover_duration
        return T_ambient + (T_peak - T_ambient) * np.exp(-k * t_decay)


def safe_hold_duration(
    T_pull: float,
    T_ambient: float,
    k: float,
    carryover_rise: float,
    T_safety: float = 145.0,  # °F — USDA minimum
) -> float:
    """Returns minutes until meat drops below safety floor."""
    # Solve: T_safety = T_ambient + (T_peak - T_ambient) * exp(-k * t)
    T_peak = T_pull + carryover_rise
    if T_ambient >= T_safety:
        return float('inf')  # Active hold above safety floor
    if T_peak <= T_safety:
        return 0.0  # Already below — shouldn't happen if pulled correctly
    import math
    t_decay = -math.log((T_safety - T_ambient) / (T_peak - T_ambient)) / k
    carryover_duration = 20.0  # TODO: match above
    return carryover_duration + t_decay
```

## Open Questions
- [ ] Is exponential decay sufficient or does meat's internal thermal gradient
      make a lumped-capacitance model inaccurate for large cuts?
- [ ] How does wrapping material (foil vs butcher paper vs bare) affect k during rest?
- [ ] Cooler/Cambro environments have rising ambient — model as piecewise?
