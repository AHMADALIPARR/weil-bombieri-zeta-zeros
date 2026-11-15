# Horn–Klong–UUie Certificate Stack

Zero-dependency, self-contained verification and search substrate for Weil–Bombieri rank-trace certificates.

## Components

| Path | Role |
|------|------|
| `uuie/uuie_kernel.c` | Strict C11 micro-kernel with `fesetround` directed rounding **and pure Jacobi Hermitian eigensolver**. Accumulates `tr(R)` under `FE_DOWNWARD` and `\|R\|_HS²` under `FE_UPWARD`, forms a certified lower bound on `ρ`, and additionally returns the exact positive-eigenvalue count `n₊(R)`. |
| `klong/weil_horn.kg` | Pure Nils Holm Klong script: cosine-tapered window → sinc-Toeplitz Gram matrix → residual check → flat matrix dump for UUie. |
| `horn/horn_cert.pl` | Minimal SLD-resolution / Curry–Howard style witness constructor. Accepts the extended ground fact that now includes `n₊`. |
| `.github/workflows/horn-sweep.yml` | Stateless matrix runner. Builds the C kernel from source, sweeps `(N,a,b)` parameters, uploads only SHA-256-sealed witnesses that pass. |
| `docs/jacobi-eigensolver.md` | Full specification of the Jacobi implementation. |

## Build & local check

```bash
cc -std=c11 -O2 -frounding-math -ffp-contract=off uuie/uuie_kernel.c -lm -o uuie_kernel
# (build or obtain kg)
# kg -l klong/weil_horn.kg
./uuie_kernel 128 0.6725 matrix_R.dat
```

A successful run prints a ground fact of the form

```prolog
rank_trace_cert(128, TrDown, Hs2Up, RhoLower, Nplus, valid).
```

and exits 0. That fact is the oracle input to the Horn theory.

## Jacobi eigensolver summary

- Classical cyclic Jacobi, pure C11, no external libraries.
- Private working copy; caller matrix is never mutated.
- Rotations under `FE_TONEAREST`; ambient rounding mode restored afterwards.
- Returns exact integer `n₊(R)` (number of strictly positive eigenvalues).
- See `docs/jacobi-eigensolver.md` for the rotation formulae and convergence criteria.
