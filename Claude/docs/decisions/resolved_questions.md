# Resolved Technical Decisions — Quick Reference

> **For Claude Code:** Check this BEFORE making any architecture or modeling decision.
> These questions were resolved by committee (Claude, Grok, ChatGPT, Gemini).
> Do NOT revisit these decisions unless explicitly asked.

| # | Decision | Resolution | Do NOT Do Instead |
|---|----------|-----------|-------------------|
| 1 | **Stall trigger logic** | Logistic transition function. Replace with empirical fit over time. | Don't use hard threshold or step function |
| 2 | **Feature multicollinearity (altitude × humidity)** | Tree models handle natively. Standardize for interpretability. SHAP post-training. | Don't drop correlated features or use PCA in V1 |
| 3 | **Bayesian updating frequency** | Event-driven: on probe reading or slope deviation > 5°F threshold. | Don't use fixed-interval updates (e.g., every 5 min) |
| 4 | **Probe integration path** | Manual V1 → Manufacturer API V2 → No native Bluetooth. | Don't build Bluetooth in any early phase |
| 5 | **Thermal diffusivity sources** | Empirical > journals > handbooks > USDA. Start textbook, replace measured. | Don't use USDA tables as primary source |
| 6 | **Quality scoring bias** | Anchored 1–10 + binary "serve to guests" (V1) → pairwise comparison (V2+). | Don't use unanchored scales or complex rubrics in V1 |
| 7 | **Tech stack** | PWA through Phase 2 minimum. No native app discussion until Phase 3+. | Don't build native iOS/Android |
| 8 | **Layer 2 model choice** | Bayesian linear (15–30 cooks) → XGBoost (30+). Not XGBoost from start. | Don't start with XGBoost — not enough data |
| 9 | **Biological variability placement** | Stochastic noise in Layer 1, not deferred to Layer 3. | Don't model bio variability only in Monte Carlo |
| 10 | **1D vs 3D FEA** | 1D sufficient. Dominant errors are biological, not geometric. | Don't build 3D finite element model |
| 11 | **Fire-out vs stall discrimination** | Monitor ambient temp; alert if > 25°F below setpoint for > 15 min. Phase 3. | Don't build fire-out detection in Phase 1 |
| 12 | **Stall modeling approach** | Dual system: hazard-based probability (logistic) + deterministic slope detection override. Prediction AND detection. | Don't rely on prediction alone or detection alone |
| 13 | **Intervention recommendations at stall** | Non-judgmental wrap prompt with tradeoff quantification. Wrap type adjusts evaporative cooling coefficient. Decision logged as structured training data. | Don't recommend "always wrap" or make judgmental prompts |
