# Horn–Klong–UUie Certificate Stack

Zero-dependency, self-contained verification and search substrate for Weil–Bombieri rank-trace certificates.

## Components

| Path | Role |
|------|------|
| `uuie/uuie_kernel.c` | Strict C11 micro-kernel with `fesetround` directed rounding. Accumulates `tr(R)` under `FE_DOWNWARD` and `\|R\|_HS²` under `FE_UPWARD`, then forms a certified lower bound on `ρ = (tr R)² / (N · \|R\|_HS²)`. Emits a ground Horn fact. |
| `klong/weil_horn.kg` | Pure Nils Holm Klong script: cosine-tapered window → sinc-Toeplitz Gram matrix → residual check → flat matrix dump for UUie. |
| `horn/horn_cert.pl` | Minimal SLD-resolution / Curry–Howard style witness constructor. Turns successful UUie ground facts into typed proof terms for `simple_critical(Rho)` and `distinct(RhoD)`. |
| `.github/workflows/horn-sweep.yml` | Stateless matrix runner. Builds the C kernel from source, sweeps `(N,a,b)` parameters, uploads only SHA-256-sealed witnesses that pass. |

## Build & local check

```bash
cc -std=c11 -O2 -frounding-math -ffp-contract=off uuie/uuie_kernel.c -lm -o uuie_kernel
# (build or obtain kg)
# kg -l klong/weil_horn.kg
./uuie_kernel 128 0.6725 matrix_R.dat
```

A successful run prints a ground fact of the form

```prolog
rank_trace_cert(128, TrDown, Hs2Up, RhoLower, valid).
```

and exits 0. That fact is the oracle input to the Horn theory.

## Next possible extension

Add a Jacobi Hermitian eigensolver (still pure C99/C11, directed-rounding aware) inside `uuie_kernel.c` so that exact `n₊(R)` can be counted in addition to the analytic lower bound `(tr R)² / \|R\|_HS²`.
