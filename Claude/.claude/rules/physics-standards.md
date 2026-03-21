---
globs: ["**/physics/**", "**/tests/test_*"]
---

# Physics Code Rules

- Every numeric literal MUST have a unit comment: `alpha = 1.28e-7  # m²/s`
- ALL constants imported from `physics/constants.py` — zero magic numbers in simulation code
- If a constant is not in `physics/constants.py`, check `docs/refs/`. If not there, FLAG IT.
- Type hints on all function signatures
- Docstrings on all public functions including: purpose, units of each parameter, units of return value
- Run `pytest tests/` after any change to physics modules
