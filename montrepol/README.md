# Montrepol

A small, honest Haskell workspace for the analytic and linear-algebraic pieces
that sit under the Weil–Bombieri certificate.

## Packages

| Package | Role |
| --- | --- |
| `mp-analytic` | Zeta, primes, Bernoulli, explicit formula |
| `mp-linalg` | Hermitian matrices, rank-trace, participation |
| `mp-lie` | Root systems for the window family |
| `mp-seq` | Recurrences used by the form factor |
| `mp-check` | Property tests |
| `mp-gate` | Static scan that no numeric claim is a string literal |

## How to build

```
cabal build all
cabal test all
```

## Honesty

See `VERIFICATION.md` for what is checked and what is not. See `CONFORMANCE.md`
for the external obligations. The gate in `mp-gate` fails the build if a source
file hardcodes a number that should have been computed.
