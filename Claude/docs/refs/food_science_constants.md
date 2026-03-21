# Food Science Constants — Implementation Reference

> **For Claude Code:** This is the constants lookup table. Use these values directly.
> Do NOT substitute your own estimates. If a value is marked TODO, FLAG IT.

## Thermal Diffusivity by Protein

> **TODO: Populate from research papers. See heat_diffusion_physics.md for full context.**

Placeholder structure — fill after research phase:

```python
# THERMAL_DIFFUSIVITY[protein][fat_level] → α in m²/s
THERMAL_DIFFUSIVITY = {
    "beef": {
        "lean":     None,  # TODO: Singh & Heldman Table 4.2
        "moderate":  None,  # TODO
        "high_fat": None,  # TODO
    },
    "pork": {
        "lean":     None,  # TODO
        "moderate":  None,  # TODO
        "high_fat": None,  # TODO
    },
    "poultry": {
        "lean":     None,  # TODO
        "moderate":  None,  # TODO
        "high_fat": None,  # TODO
    },
    "lamb": {
        "lean":     None,  # TODO
        "moderate":  None,  # TODO
        "high_fat": None,  # TODO
    },
}
```

### Grade-to-Fat Mapping
```python
GRADE_TO_FAT = {
    "select": "lean",
    "choice": "moderate",
    "prime": "high_fat",
    "wagyu": "high_fat",
}
```

## Altitude → Boiling Point Correction

This one is well-established physics. Safe to use directly.

```python
def boiling_point_f(altitude_ft: float) -> float:
    """Boiling point of water adjusted for altitude.
    Standard: 212°F at sea level, drops ~1.5°F per 1,000 ft."""
    return 212.0 - (1.5 * altitude_ft / 1000.0)
```

- Sea level: 212°F
- Denver (5,280 ft): ~204°F
- Mexico City (7,350 ft): ~201°F

This caps the maximum surface temperature in the physics model. At altitude,
evaporative cooling becomes even more significant because the boiling point is lower.

## Specific Heat Capacity (cp)

> **TODO: Populate from Singh & Heldman or Rahman**

| Material | cp (J/(kg·K)) | Notes | Source |
|----------|---------------|-------|--------|
| Lean beef    | TODO | | |
| Fat tissue   | TODO | Lower than lean | |
| Bone         | TODO | Much lower — insulator | |
| Water        | 4,186 | Reference value | Standard |

## Thermal Conductivity (k)

> **TODO: Populate from research**

| Material | k (W/(m·K)) | Notes | Source |
|----------|-------------|-------|--------|
| Lean muscle  | TODO | ~0.4-0.5 typical | |
| Fat          | TODO | ~0.15-0.2 typical (insulator) | |
| Bone         | TODO | | |

## Density (ρ)

> **TODO: Populate from research**

| Material | ρ (kg/m³) | Notes | Source |
|----------|----------|-------|--------|
| Lean beef    | TODO | ~1,050-1,100 typical | |
| Fat tissue   | TODO | ~900-950 typical (less dense) | |

## Relationship Check
α = k / (ρ × cp). When you populate the individual values above, verify that
the calculated α matches the directly-measured α from the diffusivity table.
Discrepancies indicate measurement uncertainty — use directly-measured α as primary.

## Target Internal Temperatures

Well-established values. Safe to use directly.

```python
TARGET_TEMPS = {
    "beef_brisket": {"target": 203, "unit": "°F", "notes": "Collagen breakdown complete"},
    "pork_butt": {"target": 205, "unit": "°F", "notes": "Pullable at 195-205"},
    "pork_ribs": {"target": 195, "unit": "°F", "notes": "Bend test supplementary"},
    "chicken_whole": {"target": 165, "unit": "°F", "notes": "USDA minimum, thigh preferred"},
    "chicken_breast": {"target": 165, "unit": "°F", "notes": "USDA minimum"},
    "turkey_breast": {"target": 165, "unit": "°F", "notes": "Some prefer 155 + hold"},
    "lamb_shoulder": {"target": 200, "unit": "°F", "notes": "Similar to pork butt"},
}
```

## Collagen Breakdown Temperature Range

> **TODO: Cite McGee or other source for collagen → gelatin conversion kinetics**

- Collagen begins denaturing: ~160°F
- Rapid conversion to gelatin: ~180-205°F
- This is why brisket target is 203°F — it's not about "doneness," it's about
  collagen melting into gelatin for tenderness

## Myoglobin Denaturation (Smoke Ring Science)

> **TODO: Cite source — Harold McGee + USDA research**

- Myoglobin reacts with NO₂ and CO from smoke → pink smoke ring
- Reaction effectively stops at ~140-150°F (surface protein denaturation)
- Smoke ring depth is locked in by the time the stall begins
- Implication: wrapping at stall onset does NOT sacrifice smoke flavor

## Water Activity and Evaporation

> **TODO: Research — needed for physics-based stall duration modeling**

- Surface water activity during stall: ~__
- Evaporative mass flux rate: ~__ g/(m²·s) at typical stall conditions
- Latent heat of vaporization of water at 160°F: ~__ J/g
