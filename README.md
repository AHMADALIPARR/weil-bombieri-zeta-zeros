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
| `kernels/weil_probe.bqn` | Starter discretized Toeplitz/Hankel probe |
| `harness/harness.py` | Legacy PyTorch + Llama-3 + CBQN loop |
| `prompts/muse_system_contract.xml` | Muse agent system contract |
| `uuie/uuie_kernel.c` | **C11 directed-rounding oracle + certified Jacobi $n_+(R)$** (Gershgorin margin) |
| `klong/weil_horn.kg` | Pure Klong compression; includes exact **Montgomery–Taylor window** `psi_mt` |
| `horn/horn_cert.pl` | Curry–Howard / SLD Horn verifier |
| `quantum/berry_keating_qsvt.py` | **QSVT projector + discrete Berry–Keating Hamiltonian** (pure PyTorch) |
| `.github/workflows/horn-sweep.yml` | Stateless certificate sweep |
| `docs/horn-klong-uuie.md` | Verification stack |
| `docs/jacobi-eigensolver.md` | Jacobi specification |
| `docs/quantum-bridge.md` | Mapping $R\mapsto\hat H_{\mathrm{BK}}\mapsto$ QSVT/QPE |
| `docs/constraints.md` | Hard constraints |

## Preferred Verification Path (Horn–Klong–UUie)

1. Klong builds the discretized window (parametric or Montgomery–Taylor) and the sinc-Toeplitz Gram matrix $R$.
2. UUie returns a directed-rounding lower bound on $\rho$ **and** a certified exact $n_+(R)$ (Jacobi + Gershgorin safety margin).
3. Successful runs emit an extended ground Horn fact.
4. The Horn layer constructs typed proof terms for `simple_critical` / `simple_critical_exact`.
5. GitHub Actions retains only SHA-256-sealed witnesses.

## Quantum Bridge

The same matrix $R$ is the Gram operator of a finite-dimensional subspace of the Berry–Keating dilation generator. `quantum/berry_keating_qsvt.py` builds $R$, applies a QSVT-style polynomial projector $\Pi_+(R)$, and restricts the discrete Berry–Keating Hamiltonian onto that certified positive subspace. See `docs/quantum-bridge.md`.

## Constraints Enforced

1. Conjugate symmetry: $R = R^\dagger$
2. Unit-band support truncation on the Fourier grid
3. Directed-rounding + Gershgorin-certified positivity of eigenvalues

## License

Research code. See individual files for any additional notices.
