# Constraints & Open Directions

## Hard Constraints (must hold for any accepted witness)

1. **Conjugate symmetry**  
   `R == +⍉R`  (Hermitian / real-symmetric in the discrete setting).

2. **Unit-band support truncation**  
   Fourier transforms of the underlying test functions remain supported in a bandwidth-one interval (or a controlled multi-band extension).

3. **Numerical stability**  
   The final scalar expression evaluates to a finite `f64` with no NaN or Inf. Prefer exact rational constructions where possible; otherwise use high-precision intermediates before the final division.

## Target Metric

$$
ratio(R) = \frac{(\operatorname{Tr} R)^2}{N \cdot \operatorname{Tr}(R^2)} > 0.6725
$$

This is the quantity that lower-bounds the positive-eigenvalue fraction $n_+(R)/N$ via the Bombieri rank-trace argument.

## Open Directions (from Alpöge–Furman)

- Higher-dimensional discretized Weil–Bombieri Hermitian kernels beyond bandwidth one.
- Multi-band test-function families.
- Tighter trace-moment inequalities over finite Toeplitz / Hankel grids.
- Systematic inverse engineering of the weight vector $w$ (or the full Gram structure) guided by the target spectral ratio.
