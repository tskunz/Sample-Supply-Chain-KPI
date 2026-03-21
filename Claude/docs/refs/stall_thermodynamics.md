# Stall Thermodynamics — Physics Reference

> **For Claude Code:** Read this before implementing Build Steps 6-8 (stall model,
> detection override, intervention recommendations). Do NOT invent stall coefficients.

## What Is the Stall?

The "stall" is a plateau in internal temperature (typically 150-170°F) during low-and-slow
cooking. It occurs when evaporative cooling from surface moisture equals heat input from
the smoker. The meat is literally sweating.

This is NOT a mystery — it's latent heat of vaporization. The energy that would raise
the temperature is instead used to convert liquid water to vapor at the meat surface.

## The Hazard Model (Build Step 6)

Stall onset probability at time t:

```
P(stall at t) = σ(Z)

where σ = logistic function: 1 / (1 + e^(-Z))

Z = β₀ + β₁(humidity) + β₂(wind_speed) + β₃(thickness)
    + β₄(temp_slope) + β₅(-|current_temp - 160|)
```

### Temperature Gating (CRITICAL — Build This First)
```python
if internal_temp < 140:
    return 0.0    # Too early — evaporation hasn't dominated yet
elif internal_temp > 185:
    return 0.0    # Past stall zone — evaporation phase complete
else:
    return logistic(Z)  # Run hazard model
```
This eliminates false positives. Do NOT skip this.

### Physics-Informed Prior Coefficients (V1 — Hardcoded)

These are directionally correct starting values. Phase 2 residual learner refines them.

| Variable | Coeff | Direction | Physical Rationale |
|----------|-------|-----------|-------------------|
| Intercept (β₀)          | -3.0  | —       | Base rate: stall is not the default state |
| Humidity (β₁)           | +0.02 | Higher → more evaporative cooling | Wet-bulb effect |
| Wind speed (β₂)         | +0.1  | More airflow → more surface evaporation | Convective mass transfer |
| Thickness (β₃)          | +0.5  | Thicker → more water reservoir | More moisture to evaporate |
| Temp slope (β₄)         | -4.0  | Fast-rising temp → NOT stalling | Direct contradiction of stall |
| Dist from 160°F (β₅)    | +0.15 | Closer to 160 → higher likelihood | Stall zone center ~155–165°F |

> **TODO: Validate/refine these priors against Greg Blonder's instrumented stall data**
> Source: genuineideasperbottle.com — physicist who characterized BBQ stall empirically

## Stall Detection Override (Build Step 7)

Deterministic fallback regardless of hazard model output:

```
IF temp_slope < 0.02°F/min for ≥ 10 consecutive minutes of logged readings
→ STALL DETECTED (override probability to 1.0)
```

### Slope Calculation
```python
def calculate_slope(readings: list[tuple[float, float]]) -> float:
    """
    readings: list of (timestamp_minutes, temp_F)
    Returns: °F/min (linear regression slope over window)
    """
    # Use last N readings (at least 10 minutes of data)
    # Simple linear regression: slope = Σ(xi-x̄)(yi-ȳ) / Σ(xi-x̄)²
    ...
```

## Wrap Science (Build Step 8)

### Smoke Absorption Stops at ~140-150°F

> **TODO: Cite Harold McGee "On Food and Cooking" + USDA myoglobin research**

Smoke ring = NO₂ and CO reacting with myoglobin in surface meat.
This reaction stops when surface proteins denature at ~140-150°F.
Since stall occurs at 150-170°F, **smoke flavor is locked in by stall onset.**
Wrapping at stall does NOT sacrifice meaningful smoke.

This fact is critical for the intervention recommendation messaging.

### Evaporative Cooling Coefficients by Wrap Type

> **TODO: Research and populate — these are the values that adjust the physics model
> when user selects a wrap option. Need source or derive from empirical data.**

| Wrap Type | Evaporation Reduction | Mechanism | Source |
|-----------|----------------------|-----------|--------|
| No wrap (bare)     | 0% (baseline)  | Full surface evaporation | — |
| Butcher paper      | ~60% reduction | Semi-permeable, allows some vapor escape | TODO |
| Foil boat          | ~40-50%        | Partial coverage, top bark exposed | TODO |
| Foil (Texas Crutch)| ~95%           | Near-total steam containment | TODO |

### Post-Wrap Model Adjustment
When user wraps:
1. Reduce evaporative cooling coefficient by wrap-type factor
2. Recalculate stall exit prediction with new evaporation rate
3. Update finish time estimate immediately
4. Narrow uncertainty bands (wrapping removes a major variance source)

### Stall Duration Estimates

> **TODO: Populate from Blonder's data or other empirical source**

| Condition | Typical Duration (unwrapped) | Source |
|-----------|------------------------------|--------|
| Low humidity, calm wind  | TODO | |
| High humidity, windy     | TODO | |
| Thick cut (>4 inches)    | TODO | |
| Thin cut (<2 inches)     | TODO | |

## Open Questions
- [ ] What is the actual evaporative mass flux rate at the meat surface during stall?
      (Would allow physics-based stall duration prediction instead of empirical)
- [ ] How does fuel type (charcoal vs wood vs pellet) affect stall behavior?
      (Moisture content of fuel → humidity inside cooking chamber)
- [ ] Blonder's data: does he publish raw temperature curves we could digitize?
