# Weil–Bombieri Zeta Zeros

Research toolchain targeting the finite-dimensional Hermitian positivity bounds of Alpöge–Furman (arXiv:2608.13637).

**Goal:** Construct discrete $N \times N$ Hermitian kernels $R$ (induced by compactly supported test weights) that maximize the trace-moment ratio

$$
ratio(R) = \frac{(\operatorname{Tr} R)^2}{N \cdot \operatorname{Tr}(R^2)}
$$

and thereby push the unconditional lower bound on the proportion of simple zeros on the critical line strictly above the $0.6725$ ceiling obtained with bandwidth-one test functions.

## Research Target

- **Paper:** Levent Alpöge & Ralph Furman, *More than two thirds of the zeros of the Riemann zeta function are simple and on the critical line*, arXiv:2608.13637 (August 2026).
- **Core mechanism:** Weil explicit formula $\to$ Hermitian quadratic form $W(f,g)$ combined with Montgomery pair-correlation form factor (extended unconditionally by Baluyot–Goldston–Suriajaya–Turnage-Butterbaugh and Goldston–Suriajaya) + Bombieri finite-dimensional rank-trace argument.
- **Bottleneck noted by the authors:** bandwidth-one Fourier support hits an asymptotic ceiling near two-thirds. Open directions: higher-dimensional discretized Weil–Bombieri kernels, multi-band test families, tighter trace-moment inequalities over Toeplitz/Hankel grids.

## Repository Layout

| Path | Description |
|------|-------------|
| `kernels/weil_probe.bqn` | Starter discretized Toeplitz/Hankel probe (cosine-tapered weights, sinc kernel) |
| `harness/harness.py` | Zero-bloat PyTorch + Llama-3 + `libcbqn.so` FFI loop (legacy) |
| `prompts/muse_system_contract.xml` | Bare-metal system prompt for the Muse agent |
| `uuie/uuie_kernel.c` | **Zero-dependency C11 directed-rounding micro-kernel** – certified lower bound on $\rho$ |
| `klong/weil_horn.kg` | **Pure Klong** Toeplitz/Hankel compression + residual emitter |
| `horn/horn_cert.pl` | Curry–Howard / SLD Horn verifier that turns UUie ground facts into proof terms |
| `.github/workflows/horn-sweep.yml` | Stateless GitHub Actions matrix runner for certificate sweeps |
| `docs/horn-klong-uuie.md` | Full description of the self-contained verification stack |
| `docs/constraints.md` | Hard constraints (conjugate symmetry, unit-band, stability) |

## Preferred Verification Path (Horn–Klong–UUie)

The modern, zero-dependency substrate:

1. Klong builds the discretized window and sinc-Toeplitz Gram matrix $R$.
2. UUie evaluates a **directed-rounding** lower bound on $\rho = (\operatorname{tr} R)^2 / (N \cdot \|R\|_{\mathrm{HS}}^2)$ (trace under `FE_DOWNWARD`, HS-norm under `FE_UPWARD`).
3. Successful runs emit a ground Horn fact `rank_trace_cert(...)`.
4. The Prolog/Horn layer constructs a typed proof term for `simple_critical(Rho)`.
5. GitHub Actions sweeps the $(N,a,b)$ parameter space and retains only SHA-256-sealed witnesses.

See `docs/horn-klong-uuie.md` for compile flags and local usage.

## Constraints Enforced

1. Conjugate symmetry: $R = R^\dagger$
2. Unit-band support truncation on the Fourier grid
3. Exact rational / floating-point stability (no NaN / Inf) + directed-rounding certification

## License

Research code. See individual files for any additional notices.
