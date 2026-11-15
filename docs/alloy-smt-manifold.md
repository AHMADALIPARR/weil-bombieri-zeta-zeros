# Alloy + SMT Two-Layer Verification

Combining Alloy (bounded relational SAT/UNSAT) with SMT (QF_FP for exact IEEE-754 binary64 rounding and QF_NRA for nonlinear real arithmetic) splits the verification problem cleanly:

| Layer | Tool | Role |
|-------|------|------|
| Discrete structure | Alloy (`formal/qsvt_manifold.als`) | SAT/UNSAT on parent-child cell containment, recursive manifold invariants, rounding-slip and unsound-prefactor witnesses |
| Continuous pruning | SMT QF_NRA (`formal/recursive_manifold_prune.py`) | Incremental push/pop unsat checks over $(\alpha_C, g)$ boxes; emit Horn-ready certified cells |
| Bit-exact FP | SMT QF_FP (`formal/fp_rounding_witness.smt2`) | Prove RNE can undercut the exact quotient while RTP stays above |

## Alloy commands

```text
run FindRoundingSlip        → SAT   (truncating division under-reports ceiling)
run FindUnsoundPrefactor    → SAT   (C=1 below Zolotarev floor)
check HardenedManifoldSound → UNSAT (hardened GSLW invariant holds on children)
```

Integer scaling by 20 maps $0.05\mapsto 1$, $2.70\mapsto 54$, $3.00\mapsto 60$ exactly. Signed 14-bit `Int` prevents wrap-around on products up to $4\times 60\times 14=3360$.

## SMT floating-point witness

```bash
z3 formal/fp_rounding_witness.smt2
# expected: sat, q_rne = 2.0, q_rtp > 2.0
```

Constructs exact binary64 values $\alpha_C = 0.5+3\cdot 2^{-53}$ and $g = 0.25+2^{-54}$ and proves RNE rounds the quotient down to $2.0$ while RTP rounds strictly above.

## Recursive manifold pruner

```bash
python3 formal/recursive_manifold_prune.py > horn/certified_manifold_cells.pl
```

- **Prune** — whole box unsat for `valid_qsvt` → discard.
- **Certify** — negated invariant unsat → emit `smt_certified_cell/6`.
- **Subdivide** — boundary → bisect widest axis, recurse.

Uses the constructive GSLW prefactor $C=4$ and a rational upper bound on $\ln(10^6)$.

## Horn wiring

```prolog
:- consult('horn/certified_manifold_cells.pl').
:- consult('horn/smt_manifold_cert.pl').

?- qsvt_smt_manifold_cert(2.70, 0.15, Q).
% succeeds with Q =< 1024

?- qsvt_smt_manifold_cert(2.70, 0.05, Q).
% fails — constructive degree ~2985 exceeds QueryCap
```

`verified_weil_smt_witness/4` combines the classical rank-trace / Jacobi certificate with membership in an SMT-certified cell.
