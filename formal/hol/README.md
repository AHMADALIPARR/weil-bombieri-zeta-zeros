# Higher-Order Logic Formalization

Isabelle/HOL theories that machine-check the linear-algebra core of the
Weil–Bombieri rank-trace certificates.

## Files

| File | Content |
|------|---------|
| `WeilBombieriRankTrace.thy` | Theorem `bombieri_rank_trace_bound`: for real eigenvalues λ_i, if tr = Σ λ_i > 0 and tr2 = Σ λ_i² > 0 then the number of strictly positive eigenvalues satisfies n₊ ≥ tr² / tr2. |

## How to check

```bash
isabelle build -d formal/hol -v -c WeilBombieriRankTrace
```

or open the theory in Isabelle/jEdit / VS Code Isabelle extension and
export the theorem.

## Status

- The algebraic inequality is formalized and ready for checking.
- Floating-point directed rounding (the actual implementation in
  `uuie/uuie_kernel.c`) is **not** yet inside the logic; that remains
  open problem 6.
- The theory deliberately stays elementary so that it can be ported to
  HOL4 or Lean if desired.

Primary analytic source remains Alpoge & Furman, arXiv:2608.13637.
