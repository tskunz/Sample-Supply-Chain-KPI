# 1D Heat Diffusion for Meat — Physics Reference

> **For Claude Code:** Read this before implementing the physics kernel (Build Step 1).
> Do NOT substitute your own values. If a value is missing here, FLAG IT.

## The Core Equation

Fourier's Law of Heat Conduction (1D, surface to center):

```
∂T/∂t = α × (∂²T/∂x²)
```

- `T` = temperature at position x and time t
- `α` = thermal diffusivity (m²/s) — **the** critical parameter
- `x` = distance from surface toward geometric center (thickest axis)

### Why 1D, Not 3D
Dominant thermal gradient is surface-to-center along the thickest axis. Dominant
error sources are biological (fat, moisture, connective tissue), NOT geometric.
1D is sufficient through Phase 2. Only revisit if residual analysis implicates
geometry as a primary error source. (Resolved Question #10)

## Implementation: Explicit Finite Difference

Use forward Euler on a 1D spatial grid. SciPy's `solve_ivp` is overkill — explicit
method is simpler, fast enough for 5,000 Monte Carlo iterations, and easier to inject
stochastic noise into.

### Stability Condition (CRITICAL)
```
dt ≤ dx² / (2 × α)
```
Always enforce this. If violated, simulation explodes. Use `dt = 0.9 × dx² / (2 × α)`.

### Boundary Conditions
- **Surface (x=0):** Fixed at smoker setpoint temperature (convective BC possible in V2+)
- **Center (x=L):** Symmetry condition — zero flux (∂T/∂x = 0)

### Spatial Discretization
- `dx` = 0.001 m (1mm) — sufficient resolution for meat geometry
- `nx` = int(half_thickness / dx) + 1

## Thermal Diffusivity Values

> **TODO: Populate from Singh & Heldman, "Introduction to Food Engineering," 5th ed.**
> Also cross-reference: Rahman, "Food Properties Handbook," 2nd ed.

| Protein | Lean (×10⁻⁷ m²/s) | Moderate Fat | High Fat | Source |
|---------|-------------------|-------------|----------|--------|
| Beef    | TODO              | TODO        | TODO     |        |
| Pork    | TODO              | TODO        | TODO     |        |
| Poultry | TODO              | TODO        | TODO     |        |
| Lamb    | TODO              | TODO        | TODO     |        |

### Grade-to-Fat Mapping
| User-Facing Grade | Fat Level   | Rationale |
|-------------------|-------------|-----------|
| Select            | Lean        | Minimal intramuscular fat |
| Choice            | Moderate    | Moderate marbling |
| Prime             | High Fat    | Significant marbling |
| Wagyu             | High Fat    | Treat as high_fat, refine empirically |

### Physical Intuition
- α = k / (ρ × cp) — conductivity / (density × specific heat)
- Fat has LOWER thermal conductivity than lean muscle
- Higher marbling → lower effective α → longer cook
- This is why Prime brisket cooks slower than Select at same weight/thickness

## Stochastic Variation for Monte Carlo (Build Step 2)

> **TODO: Confirm CV range from Singh Table footnotes or other source**

- Add ±__% uniform noise to α per iteration
- This captures biological variability (marbling distribution isn't uniform)
- Additional noise sources: initial temp uncertainty (±__°F), thickness measurement (±__%)

## Implementation Skeleton

```python
import numpy as np

def simulate_heat_diffusion(
    half_thickness_m: float,     # surface to center distance, meters
    T_surface: float,            # smoker setpoint, °F
    T_initial: float,            # meat starting temp, °F
    alpha: float,                # thermal diffusivity, m²/s
    T_target: float,             # pull temp, °F
    dx: float = 0.001,           # spatial step, meters (1mm)
) -> float:
    """
    Simulate 1D heat diffusion from surface to center.
    Returns estimated cook time in minutes.
    """
    nx = int(half_thickness_m / dx) + 1
    T = np.full(nx, T_initial, dtype=np.float64)

    # Stability-constrained time step
    dt = 0.9 * dx**2 / (2 * alpha)  # seconds
    r = alpha * dt / dx**2           # must be ≤ 0.5

    elapsed = 0.0
    while T[-1] < T_target:         # T[-1] = center node
        T_new = T.copy()
        # Interior nodes: forward Euler
        T_new[1:-1] = T[1:-1] + r * (T[:-2] - 2*T[1:-1] + T[2:])
        # Boundary: surface = smoker temp
        T_new[0] = T_surface
        # Boundary: center symmetry (zero flux)
        T_new[-1] = T_new[-2]
        T = T_new
        elapsed += dt

    return elapsed / 60.0  # convert seconds to minutes
```

## Open Questions
- [ ] What is the convective heat transfer coefficient for different smoker types?
      (Needed for convective BC upgrade in V2+, not blocking for V1)
- [ ] Should we model fat cap as a separate layer with different α?
      (Adds complexity — test if residuals justify it)
