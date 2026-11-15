# Pure C11 Jacobi Hermitian Eigensolver (UUie)

Zero-dependency, directed-rounding-aware implementation living inside `uuie/uuie_kernel.c`.

## Algorithm

Classical **cyclic Jacobi** method for real symmetric matrices (the Hermitian case reduces to this after the conjugate-symmetry check already performed by the certificate routine).

### Rotation formula

For an off-diagonal pair \((p,q)\):

$$
\tau = \frac{A_{qq}-A_{pp}}{2A_{pq}},\qquad
t = \frac{\operatorname{sign}(\tau)}{|\tau|+\sqrt{1+\tau^2}},\qquad
c = \frac{1}{\sqrt{1+t^2}},\qquad
s = tc.
$$

The similarity update is the standard 2-sided Givens rotation that annihilates the \((p,q)\) entry.

### Convergence

- Maximum sweeps: 64 (far more than enough for the modest dimensions used in the rank-trace certificates, typically \(N\le 256\)).
- Termination when the off-diagonal Frobenius norm falls below `1e-15` times a crude scale of the matrix.

### Directed rounding discipline

- All Jacobi rotations themselves are performed under `FE_TONEAREST`.
- The ambient rounding mode of the caller is saved and restored, so the subsequent analytic bound
  \(\rho = (\operatorname{tr} R)^2/(N\cdot\|R\|_{\mathrm{HS}}^2)\)
  remains under the strict `FE_DOWNWARD` / `FE_UPWARD` regime already established by the certificate function.

## API

```c
int uuie_jacobi_hermitian(double *A, int N, double *out_evals);
```

- `A`          – row-major real symmetric matrix (a private copy is made; the caller’s buffer is never mutated).
- `N`          – dimension.
- `out_evals`  – optional array of length `N` that receives the eigenvalues; may be `NULL`.
- **returns**  – the number of **strictly positive** eigenvalues \(n_+(R)\), or a negative value on allocation failure.

## Integration with the certificate

`uuie_verify_certificate` now returns both:

1. the directed-rounding lower bound on the analytic ratio, and
2. the exact integer \(n_+(R)\) obtained from the Jacobi diagonalisation.

The ground Horn fact emitted by the CLI therefore has the extended shape

```prolog
rank_trace_cert(N, TrDown, Hs2Up, RhoLower, Nplus, valid|reject).
```

The Horn layer can consequently reason about either the analytic bound or the true positive-eigenvalue count (or both).

## Build flags (unchanged)

```bash
cc -std=c11 -O2 -frounding-math -ffp-contract=off uuie/uuie_kernel.c -lm -o uuie_kernel
```

No external libraries beyond `-lm`. No operator-overloading, no C++.
