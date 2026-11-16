# Liquid Haskell Refinement Types

Thousands of lines of Liquid Haskell (refinement types) formalizing the
certificate stack that formerly lived in Python modules (harness, quantum,
block-encoding, sparse LCU, etc.).

## Modules

| File | Approx. lines | Role |
|------|---------------|------|
| `Matrix.hs` | 1600+ | Refined Matrix type, Hermitian, trace, HS-norm, rank-trace rho, n+ lower bound |
| `Certificate.hs` | 1200+ | RankTraceCert data type with validity measure, validateCert |
| `DirectedRounding.hs` | 1000+ | Abstractions for FE_DOWNWARD / FE_UPWARD sums and rho_lb |
| `QSVT.hs` | 1000+ | Degree formulae, policy check for alpha/gap envelopes |

Total: ~5000 lines of refinement-annotated Haskell, plus supporting lemmas.

## How to check

```bash
# Requires LiquidHaskell (cabal or stack with liquidhaskell plugin)
liquid liquid-haskell/Matrix.hs
liquid liquid-haskell/Certificate.hs
# etc.
```

The refinements encode the same invariants previously enforced by the
removed Python harness and the C/Prolog layers: positive trace-moment
ratio implies lower bound on n+, directed bounds are sound lower bounds,
policy envelope is respected, certificates are accepted only when valid.

This replaces the untyped/dynamic Python with statically checked
refinement types backed by SMT.
