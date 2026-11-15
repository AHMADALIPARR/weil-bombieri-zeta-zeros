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
| `harness/harness.py` | Zero-bloat PyTorch + Llama-3 + `libcbqn.so` FFI loop (strict XML extraction, deterministic generation) |
| `prompts/muse_system_contract.xml` | Bare-metal system prompt for the Muse agent (emits pure CBQN kernels only) |
| `docs/` | Notes on constraints (conjugate symmetry, unit-band support, numerical stability) |

## Quick Start (CBQN probe)

```bash
# Requires a CBQN installation
cbqn kernels/weil_probe.bqn
```

The probe evaluates

$$
\frac{(\operatorname{Tr} R)^2}{n \cdot \|R\|_{\mathrm{HS}}^2}
$$

for an $n=128$ cosine-tapered weight vector and a sinc Toeplitz kernel.

## Synthesis Loop Outline

1. Build `libcbqn.so` (`make shared-o3` inside a CBQN clone).
2. Load Llama-3 (or local GGUF) in raw `transformers` / `torch`.
3. Feed the Muse system contract; parse `<cbqn_kernel>` blocks.
4. Evaluate the returned scalar via FFI; accept only witnesses with `ratio > 0.6725` that also satisfy the three hard constraints.
5. Record SHA-256 of successful kernels.

## Constraints Enforced by the Kernel

1. Conjugate symmetry: $R = +\texttt{⍉}R$
2. Unit-band support truncation on the Fourier grid
3. Exact rational / floating-point stability (no NaN / Inf)

## License

Research code. See individual files for any additional notices.
