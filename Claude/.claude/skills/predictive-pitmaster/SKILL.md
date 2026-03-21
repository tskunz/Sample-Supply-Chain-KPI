# Predictive Pitmaster — Physics Simulation Skill

## When to Activate
Use this skill when implementing or modifying:
- Heat diffusion solver
- Stall hazard model
- Monte Carlo simulation
- Backward planner
- Rest phase calculator
- Any physics constant or coefficient

## Mandatory Pre-Implementation Steps
1. Read the relevant file in `docs/refs/` for the specific physics domain
2. Check `docs/decisions/resolved_questions.md` for related architectural decisions
3. Verify all constants come from `physics/constants.py` (no magic numbers)
4. If a constant is missing from the ref docs, **STOP and ask** — do not guess

## Physics Code Checklist
- [ ] All numeric values have unit comments (e.g., `# m²/s`, `# °F`, `# minutes`)
- [ ] Stability condition enforced for finite difference (dt ≤ dx²/(2α))
- [ ] Temperature gating on stall model (returns 0 outside 140-185°F)
- [ ] Monte Carlo produces p10 < p50 < p90 for all valid inputs
- [ ] Backward planner uses p90 (conservative) for start time calculation
- [ ] Rest phase respects 145°F safety floor

## Testing Requirements
- Heat diffusion: compare against analytical erf() solution for semi-infinite solid
- Stall model: test all temperature gating boundaries
- Monte Carlo: test seed reproducibility, convergence at 5,000 iterations
- Run `pytest tests/` after any physics code change

## Constants Flow
```
docs/refs/*.md (source of truth, with citations)
    ↓ manually transcribed
physics/constants.py (code-level constants, traced to refs)
    ↓ imported
physics/*.py (simulation modules — NEVER hardcode values here)
```
