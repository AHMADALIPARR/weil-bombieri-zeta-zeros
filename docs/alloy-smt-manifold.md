# Alloy + SMT Two-Layer Verification

Combining Alloy (bounded relational SAT/UNSAT) with SMT (QF_FP for exact IEEE-754 binary64 rounding and QF_NRA for nonlinear real arithmetic) splits the verification problem cleanly:

| Layer | Tool | Role |
|-------|------|------|
| Discrete structure | Alloy (`formal/qsvt_manifold.als`) | SAT/UNSAT on parent-child cell containment, recursive manifold invariants, rounding-slip and unsound-prefactor witnesses |
| Continuous pruning | SMT QF_NRA (generator `formal/recursive_manifold_prune.py`, removed on this branch) | Incremental push/pop unsat checks over $(\alpha_C, g)$ boxes; emit Horn-ready certified cells |
| Bit-exact FP | SMT QF_FP (`formal/fp_rounding_witness.smt2`) | Prove RNE can undercut the exact quotient while RTP stays above |

## Alloy commands (expected results; not re-run in the 2026-11-15 pass)

```text
run FindRoundingSlip        → SAT   (truncating division under-reports ceiling)
run FindUnsoundPrefactor    → SAT   (C=1 below Zolotarev floor)
check HardenedManifoldSound → UNSAT (hardened GSLW invariant holds on children)
```

Integer scaling by 20 maps $0.05\mapsto 1$, $2.70\mapsto 54$, $3.00\mapsto 60$ exactly. Signed 14-bit `Int` prevents wrap-around on products up to $4\times 60\times 14=3360$.

## SMT floating-point witness

```bash
z3 formal/fp_rounding_witness.smt2
# expected: sat, plus a model for alpha, gap, q_rne, q_rtp
```

The file does not fix $\alpha_C$ and $g$; it asks the solver for any normal binary64 pair in the policy range ($0.05 \le g \le \alpha_C \le 3$) whose RNE quotient is strictly below its RTP quotient. With Z3 5.4.1 (run 2026-11-15) the result was `sat`, with `q_rne` and `q_rtp` differing in the last significand bit (`...c463` vs `...c464`). The model values depend on the solver version.

## Recursive manifold pruner

The generator `formal/recursive_manifold_prune.py` was removed from this branch (owner request: no Python). `horn/smt_manifold_cert.pl` still consumes `smt_certified_cell/6` facts, but no remaining file produces them. The description below is of the removed tool.

- **Prune** — whole box unsat for `valid_qsvt` → discard.
- **Certify** — negated invariant unsat → emit `smt_certified_cell/6`.
- **Subdivide** — boundary → bisect widest axis, recurse.

Uses the constructive GSLW prefactor $C=4$ and a rational upper bound on $\ln(10^6)$.

## Horn wiring

```prolog
:- consult('horn/certified_manifold_cells.pl').
:- consult('horn/smt_manifold_cert.pl').

?- qsvt_smt_manifold_cert(2.70, 0.15, Q).
% fails with the cells the removed generator produced on 2026-11-15 (default
% depth 7): no certified cell contained this point. The nearest cell at
% alpha 2.70 was [2.63125, 3.0] x [0.234375, 0.41875] with Q bound 708.

?- qsvt_smt_manifold_cert(2.70, 0.05, Q).
% fails — constructive degree ~2985 exceeds QueryCap
```

`verified_weil_smt_witness/4` combines the classical rank-trace / Jacobi certificate with membership in an SMT-certified cell.
