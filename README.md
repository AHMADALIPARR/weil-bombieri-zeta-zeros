# Weil–Bombieri Zeta Zeros

**Unconditional simple critical-line zeros of the Riemann zeta function via finite Hermitian compressions of the Weil explicit formula.**

This repository implements the discrete side of the Alpöge–Furman argument (arXiv:2608.13637), gates every candidate matrix through directed-rounding and exact Jacobi certification, and documents — with Alloy and SMT — what still fails when the same matrices are promoted to polylogarithmic QSVT query bounds.

It is a certificate engine and a complexity truth-serum. It is not a zero factory and it does not claim a quantum algorithm that extracts individual ordinates in polylog time.

---

## 1. Research goal

### 1.1 The quantity

Let $N(T)$ count non-trivial zeros of $\zeta(s)$ with $0 < \operatorname{Im}(s) \le T$. Write $N_s(T)$ for those that are **simple and lie on the critical line** $\operatorname{Re}(s)=1/2$. The object is a lower bound

$$
\liminf_{T\to\infty}\frac{N_s(T)}{N(T)}\;\ge\;\rho_0
$$

that holds **unconditionally** (no RH, no pair-correlation hypotheses beyond what has been proved).

### 1.2 The classical record this work sits under

| Result | Bound | Method | Year |
|--------|-------|--------|------|
| Levinson | $1/3$ on the line | mollifiers | 1974 |
| Conrey | $2/5 = 0.4000$ on the line | mollifiers | 1989 |
| Bui–Conrey–Young / related | $\approx 0.414$ on the line | refined mollifiers | 2010s |
| **Alpöge–Furman** | **$2/3$ simple + critical** | Weil form + rank-trace | 2026 |
| **Alpöge–Furman (MT window)** | **$0.6725$ simple + critical** | Montgomery–Taylor test function | 2026 |
| Alpöge–Furman | $5/6$ distinct zeros | same lane | 2026 |
| Alpöge–Furman (MT) | $\approx 0.8362$ distinct | same lane | 2026 |

The mollifier lane and the Weil–Bombieri lane are not interchangeable. Mollifiers attack the proportion **on the line**; the rank-trace argument attacks the joint condition **simple and on the line**, and as a byproduct yields a strong distinct-zeros bound.

### 1.3 Mechanism

Weil’s explicit formula associates to suitable test functions a Hermitian quadratic form $W(f,g)$. Restricting to a finite-dimensional family of modulated, compactly supported windows produces an $N\times N$ Hermitian matrix $R$.

Unconditional control of Montgomery’s form factor $F(\alpha)$ for $|\alpha|\le 1$ (Baluyot–Goldston–Suriajaya–Turnage-Butterbaugh; Goldston–Suriajaya) supplies the asymptotic shape of the entries. Bombieri’s finite-dimensional rank-trace inequality then gives

$$
n_+(R)\;\ge\;\frac{(\operatorname{tr} R)^2}{\operatorname{tr}(R^2)},
$$

where $n_+(R)$ is the number of strictly positive eigenvalues. Each positive eigenvalue accounts for a zero that must be simple and critical-line inside the spectral window. The normalized ratio

$$
\rho(R)\;=\;\frac{(\operatorname{tr} R)^2}{N\,\|R\|_{\mathrm{HS}}^2}
$$

is what numerical search maximizes. The analytic theorem uses continuous test functions; this repository discretizes, certifies, and refuses to accept prose in place of a matrix.

**Hard constraints on every candidate $R$:**

1. Conjugate symmetry $R=R^\dagger$.
2. Unit-band Fourier support (bandwidth one).
3. Numerical stability (no NaN/Inf).
4. Directed-rounding lower bound on $\rho$, or exact Jacobi $n_+/N$, above the target (default $0.6725$).

---

## 2. Repository map

### 2.1 Classical certificate stack

| Path | Role | Status |
|------|------|--------|
| `klong/weil_horn.kg` | Montgomery–Taylor window, sinc-Toeplitz Gram, $\delta(\alpha)$ contact mass, matrix dump | operational |
| `uuie/uuie_kernel.c` | C11 directed-rounding $\rho$ + cyclic Jacobi $n_+$ + Gershgorin margin | operational |
| `horn/horn_cert.pl` | Hardened SWI-Prolog policy + classical Horn rules | operational |
| `horn/test_qsvt_polylog.pl` | plunit edge-case suite | operational |
| `horn/smt_manifold_cert.pl` | Membership in SMT-certified $(\alpha_C,g)$ cells | operational |
| `harness/gate.py` | LLM output → extract kernel → kg → UUie; prose rejected | operational |
| `harness/harness.py` | Synthesis loop around the gate | operational |
| `prompts/muse_system_contract.xml` | Forces executable Klong, not English | operational |
| `.github/workflows/horn-sweep.yml` | Stateless parameter matrix CI | operational |

### 2.2 Quantum bridge and cost models

| Path | Role | Status |
|------|------|--------|
| `quantum/block_encoding_audit.py` | Circulant-QFT vs LCU, $\delta_{\min}$, QSVT degrees | operational |
| `quantum/berry_keating_qsvt.py` | Classical Chebyshev projector + discrete Berry–Keating | simulation only |
| `docs/block-encoding-audit.md` | Written cost analysis | docs |
| `docs/quantum-bridge.md` | $R\mapsto\hat H_{\mathrm{BK}}\mapsto$ QSVT/QPE | docs |
| `docs/qsvt-polylog-soundness.md` | What the policy predicate does **not** prove | docs |

### 2.3 Formal layer (Alloy + SMT)

| Path | Role | Status |
|------|------|--------|
| `formal/qsvt_counterclaims.als` | FP ceiling under-report; $C=1$ below Zolotarev/GSLW | model |
| `formal/qsvt_manifold.als` | SAT rounding slip, SAT unsound prefactor, UNSAT hardened invariant | model |
| `formal/fp_rounding_witness.smt2` | QF_FP: RNE can undercut RTP | **sat** under Z3 4.8.12 |
| `formal/recursive_manifold_prune.py` | QF_NRA recursive $(\alpha_C,g)$ pruner | operational |
| `docs/alloy-smt-manifold.md` | Two-layer verification index | docs |

### 2.4 Seed / legacy

| Path | Role |
|------|------|
| `kernels/weil_probe.bqn` | Original CBQN probe |
| `docs/constraints.md` | Symmetry, band, stability |
| `docs/hard-gate.md` | Gate acceptance criteria |
| `docs/jacobi-eigensolver.md` | Jacobi API and rounding discipline |
| `docs/horn-klong-uuie.md` | Classical stack overview |

---

## 3. Benchmarks (measured on this codebase)

All tables below were produced by `quantum/block_encoding_audit.py` and the same Toeplitz generator used in Klong, on IEEE-754 binary64, November 2026.

### 3.1 Continuous Montgomery–Taylor symbol only (no contact mass)

Cauchy–Schwarz on the positive spectrum is loose when eigenvalues decay. Analytic $\rho$ stalls near $0.29$ while Jacobi still sees a large positive fraction.

| $N$ | $\rho_{\mathrm{lb}}$ | $n_+/N$ | $\delta_{\min}$ | $\alpha_C$ | $\alpha_{\mathrm{LCU}}$ | $C_U$ | $q(0.05)$ | $q(\delta_{\min})$ |
|------:|------------------------:|----------:|------------------:|-------------:|--------------------------:|-------:|-----------:|---------------------:|
| 64 | 0.2932 | 0.8438 | $6.91\times 10^{-12}$ | 2.6942 | 2.6942 | 2584 | 745 | $\sim 3.72\times 10^{10}$ |
| 128 | 0.2908 | 0.7969 | $1.68\times 10^{-12}$ | 2.6971 | 2.6971 | 2604 | 746 | $\sim 3.73\times 10^{10}$ |
| 256 | 0.2895 | 0.7656 | $2.54\times 10^{-12}$ | 2.6985 | 2.6985 | 2626 | 746 | $\sim 3.73\times 10^{10}$ |
| 512 | 0.2889 | 0.7520 | $1.07\times 10^{-12}$ | 2.6993 | 2.6993 | 2650 | 746 | $\sim 3.73\times 10^{10}$ |
| 1024 | 0.2887 | 0.7432 | $1.97\times 10^{-12}$ | 2.6996 | 2.6996 | 2676 | 746 | $\sim 3.73\times 10^{10}$ |

Interpretation:

- $\rho < 0.30$ never clears the analytic target $0.6725$.
- Jacobi $n_+/N$ is still well above $2/3$ at moderate $N$, which is why the eigensolver is mandatory.
- $\delta_{\min}\sim 10^{-12}$ makes a full positive-subspace QSVT projector leave the polylog regime by many orders of magnitude.

### 3.2 Same symbol plus Montgomery $\delta(\alpha)$ contact mass $c_0 I$ with $c_0=1$

The diagonal contact is the discrete model of the $\delta(\alpha)$ term in Montgomery’s form factor (the $T\log T$ main term of the explicit formula). With $c_0=1$:

| $N$ | $\rho_{\mathrm{lb}}$ | $n_+/N$ | $\delta_{\min}$ | $\alpha_C$ | $\alpha_{\mathrm{LCU}}$ | $C_U$ | $q(0.05)$ | $q(\delta_{\min})$ |
|------:|------------------------:|----------:|------------------:|-------------:|--------------------------:|-------:|-----------:|---------------------:|
| 64 | 0.7746 | 1.0000 | $1.00$ | 3.6942 | 3.6942 | 2584 | 1021 | 52 |
| 128 | 0.7726 | 1.0000 | $1.00$ | 3.6971 | 3.6971 | 2604 | 1022 | 52 |
| 256 | 0.7715 | 1.0000 | $1.00$ | 3.6985 | 3.6985 | 2626 | 1022 | 52 |
| 512 | 0.7710 | 1.0000 | $1.00$ | 3.6993 | 3.6993 | 2650 | 1023 | 52 |
| 1024 | 0.7708 | 1.0000 | $1.00$ | 3.6996 | 3.6996 | 2676 | 1023 | 52 |

Interpretation:

- Both $\rho$ and $n_+/N$ clear $0.6725$ at every listed $N$.
- $\delta_{\min}=\Theta(1)$ collapses exact-gap QSVT degree from $\sim 10^{10}$ to $52$.
- $\alpha_C=\alpha_{\mathrm{LCU}}$ still holds (non-negative Fourier coefficients).
- $C_U$ remains $O(\log^2 N)$ for the Circulant-QFT sketch.
- $c_0=1$ is a working normalisation in the discrete model; matching the precise height-dependent coefficient of the explicit formula is Open Problem 5.

### 3.3 Side-by-side: what contact changes at $N=1024$

| Quantity | No contact | Contact $c_0=1$ | Ratio / delta |
|----------|------------|-------------------|---------------|
| $\rho_{\mathrm{lb}}$ | 0.2887 | 0.7708 | $\times 2.67$ |
| $n_+/N$ | 0.7432 | 1.0000 | $+0.2568$ |
| $\delta_{\min}$ | $1.97\times 10^{-12}$ | $1.00$ | $\times\sim 5\times 10^{11}$ |
| $\alpha_C$ | 2.6996 | 3.6996 | $+1$ (the contact) |
| $q(\delta_{\min})$ | $\sim 3.73\times 10^{10}$ | 52 | $\times\sim 7\times 10^{-10}$ |

### 3.4 Policy predicate `qsvt_polylog_cert/4` (SWI-Prolog 9.0.4)

| Query | Result | Reason |
|-------|--------|--------|
| `(1e6, 2.70, 0.05, Q)` | `Q = 747` | Inside envelope; unifies with computed ceiling |
| `(1e6, 3.0, 0.05, Q)` | `Q = 829` | At AlphaCap boundary |
| `(1e6, 3.01, 0.05, _)` | `false` | Above AlphaCap $3.0$ |
| `(1e6, 2.70, 0.049, _)` | `false` | Below GapFloor $0.05$ |
| `(1e6, 2.70, 0.05, 1024)` | `false` | Pre-bound count must match envelope, not the hard cap |
| `(0, 2.70, 0.05, _)` | **throws** `domain_error(positive_integer, 0)` | Invalid domain |
| `(100, 0, 0.05, _)` | **throws** `domain_error(positive_normalization, 0)` | Invalid domain |
| `(100, 2.70, 0, _)` | **throws** `domain_error(positive_spectral_gap, 0)` | Invalid domain |

Invalid domains **throw**. Valid parameters outside the policy **fail**. That distinction is intentional.

### 3.5 Degree formulae on the reference point $(\alpha_C,g,\varepsilon)=(2.70, 0.05, 10^{-6})$

| Formula | Prefactor $C$ | Degree | vs QueryCap $1024$ |
|---------|-----------------|--------|----------------------|
| Prolog policy ($C=1$, unproved) | 1.0000 | **747** | passes |
| Zolotarev / Eremenko–Yuditskii lower bound | $4/\pi\approx 1.2732$ | **$\approx 950$** | exceeds 747 |
| Constructive GSLW erf-Chebyshev | $\approx 4$ | **$\approx 2985$** | exceeds QueryCap |

No odd polynomial of degree 747 satisfies the QSVT unit-bound and spectral-accuracy conditions at this gap. The policy predicate is a **budget filter**, not a QSVT existence proof. See `docs/qsvt-polylog-soundness.md`.

### 3.6 IEEE-754 RNE vs RTP (Z3 4.8.12)

```
$ z3 formal/fp_rounding_witness.smt2
sat
```

Concrete normal binary64 $\alpha,g$ exist with $\operatorname{RNE}(\alpha/g) < \operatorname{RTP}(\alpha/g)$. Round-to-nearest can sit on the wrong side of an integer discontinuity relative to the exact real product; that is the structural fact behind the ceiling-soundness gap in `qsvt_build_report/4`.

---

## 4. What is proved in this codebase

### 4.1 Proved or enforced

| Claim | Where | Mechanism |
|-------|-------|-----------|
| Directed-rounding lower bound on $\rho$ | `uuie/uuie_kernel.c` | Trace `FE_DOWNWARD`, HS-norm `FE_UPWARD`, ratio downward |
| Exact $n_+$ under residual margin | `uuie/uuie_kernel.c` | Cyclic Jacobi + Gershgorin safety |
| Non-executable LLM output rejected | `harness/gate.py` | No `<klong_kernel>` / kg fail / UUie nonzero → reject |
| Type/domain/finite discipline on policy inputs | `horn/horn_cert.pl` | `must_be`, `domain_error`, `float_class` |
| RNE can undercut RTP on a quotient | `formal/fp_rounding_witness.smt2` | QF_FP **sat** |
| $C=1$ lies below Zolotarev and GSLW on reference parameters | docs + Alloy models | Analytic comparison + manifold SAT |

### 4.2 Not proved

| Non-claim | Why |
|-----------|-----|
| $\widehat Q = \lceil\mathrm{fl}((\alpha_C/g)\ln(1/\varepsilon))\rceil$ is a sound upper bound on the true ceiling | Round-to-nearest does not guarantee $\widehat x\ge x$ before `ceiling` |
| Degree $\widehat Q$ admits a QSVT phase sequence | Prefactor $C=1$ is below known lower and constructive upper bounds |
| Circulant-QFT gate counts on hardware | $C_U$ is an analytic sketch, not a compiled circuit |
| Individual ordinates $\gamma_n$ from positive eigenmodes | Rank-trace is a counting argument |
| Anything past bandwidth one | Unconditional form-factor control stops at $|\alpha|=1$ |

---

## 5. Architecture

```
LLM / Muse
    │  must emit <klong_kernel>...</klong_kernel>
    ▼
harness/gate.py
    │  kg → matrix_R.dat
    │  uuie_kernel N target matrix_R.dat
    ▼
rank_trace_cert(N, TrDown, Hs2Up, RhoLower, Nplus, JacobiFrac, valid)
    │
    ├─► Horn classical: simple_critical / simple_critical_exact
    │
    └─► qsvt_polylog_cert          (policy budget only)
             │
             └─► qsvt_smt_manifold_cert   (optional; QF_NRA-certified cells)
```

Parallel track (does not feed the hard gate):

- `block_encoding_audit.py` — cost tables for Circulant-QFT / LCU / QSVT degrees.
- `berry_keating_qsvt.py` — classical projector simulation on a discrete Berry–Keating generator.

---

## 6. Method notes

### 6.1 Window and Gram matrix

Montgomery–Taylor window on $[-1,1]$:

$$
\psi_{\mathrm{MT}}(u)=(1-|u|)\cos(\pi u)+\frac{\sin(\pi|u|)}{\pi}.
$$

Continuous symbol used in the Toeplitz generator:

$$
g(u)=\psi_{\mathrm{MT}}(u)^2\bigl(1-\tfrac12|u|\bigr).
$$

On an equispaced grid the continuous part of $R$ is the weighted Fourier–Toeplitz matrix of $g$, optionally plus contact $c_0 I$.

### 6.2 Directed rounding

For a **lower** bound on $\rho=(\operatorname{tr} R)^2/(N\|R\|_{\mathrm{HS}}^2)$:

| Quantity | Rounding mode | Reason |
|----------|---------------|--------|
| $\operatorname{tr} R$ | `FE_DOWNWARD` | must not overestimate numerator |
| $\|R\|_{\mathrm{HS}}^2$ | `FE_UPWARD` | must not underestimate denominator |
| final ratio | `FE_DOWNWARD` | preserve lower-bound direction |

Jacobi runs on a private copy; positivity is tested after subtracting a residual computed under upward rounding.

### 6.3 Why Jacobi is mandatory

Cauchy–Schwarz on the positive spectrum yields $\rho\le n_+/N$, with equality only for flat positive eigenvalues. A decaying spectrum drives $\rho$ down while $n_+$ stays large. Section 3.1 is the empirical proof that $\rho$ alone would reject matrices whose exact positive fraction already exceeds $2/3$.

### 6.4 Quantum cost model (limits)

Circulant-QFT block-encoding of a non-negative Toeplitz symbol keeps $\alpha_C=O(1)$ (Szegő). Gate cost of one call is $O(\log^2 N)$ in the sketch. Two independent obstructions remain:

1. **Vanishing gap without contact** — $\delta_{\min}\sim 10^{-12}$ forces enormous QSVT degree for a full positive-subspace projector.
2. **Degree prefactor** — even with a healthy gap, $C=1$ is not a sound QSVT degree formula. Policy uses it as a filter; SMT pruning with $C=4$ is the path that excludes cells where constructive QSVT cannot meet QueryCap.

---

## 7. Open problems

| # | Problem | Type | Blocks |
|---|---------|------|--------|
| 1 | Unconditional form factor for $|\alpha|>1$ | Analytic (external) | Classical ceiling above bandwidth one |
| 2 | Sound ceiling under floating point | Numerical / formal | Trust in $\widehat Q$ as upper bound |
| 3 | Proved constructive prefactor $C_{\mathrm{cert}}\ge 4/\pi$ | Analytic + verified phases | Polylog QSVT claims |
| 4 | Map positive eigenmodes of $R$ to ordinates $\gamma_n$ | Analytic / spectral | Individual zero extraction |
| 5 | Calibrate $c_0(T)$ to explicit-formula diagonal | Analytic + numerical | Height-correct contact mass |
| 6 | Machine-checked proof of UUie directed-rounding inequalities | Formal verification | Trust without reading C |

---

## 8. How to run

```bash
# Oracle
cc -std=c11 -O2 -frounding-math -ffp-contract=off \
   uuie/uuie_kernel.c -lm -o uuie/uuie_kernel

# Matrix (requires Nils Holm kg + math.kg)
kg -l klong/weil_horn.kg

# Certificate
./uuie/uuie_kernel 128 0.6725 matrix_R.dat

# Policy
swipl -q -s horn/horn_cert.pl \
  -g 'qsvt_polylog_cert(1000000,2.70,0.05,Q), writeln(Q), halt'

# FP witness
z3 formal/fp_rounding_witness.smt2

# SMT manifold cells
python3 formal/recursive_manifold_prune.py > horn/certified_manifold_cells.pl

# Cost tables
python3 quantum/block_encoding_audit.py
```

Hard gate from Python:

```python
from harness.gate import clean_and_gate_llm_output
verdict = clean_and_gate_llm_output(raw_llm_text, n=128, target_rho=0.6725)
assert verdict["accepted"], verdict["reason"]
```

---

## 9. Reproduce the contact-mass table

```python
import math, torch
torch.set_default_dtype(torch.float64)

def psi_mt(u):
    au = u.abs()
    return (1-au)*torch.cos(math.pi*u)+torch.sin(math.pi*au)/math.pi

def build(N, c0=1.0, c=1.35, q=4096):
    u = torch.linspace(-1+1/q, 1-1/q, q)
    g = psi_mt(u)**2 * (1-0.5*u.abs())
    d = torch.arange(N, dtype=torch.float64)[:,None]
    t = (g*torch.cos((math.pi/c)*d*u[None,:])).sum(1)*(2/q)
    idx = torch.arange(N)
    return t[(idx[:,None]-idx[None,:]).abs()] + c0*torch.eye(N)

for N in [64, 128, 256, 512, 1024]:
    T = build(N)
    tr, hs2 = torch.trace(T).item(), torch.sum(T*T).item()
    rho = (tr*tr)/(N*hs2)
    nplus = (torch.linalg.eigvalsh(T) > 1e-12).sum().item()/N
    print(f"{N:5d}  rho={rho:.4f}  n+/N={nplus:.4f}")
```

Expected: `rho` in $[0.77, 0.78]$, `n+/N = 1.0` at every listed $N$.

---

## 10. Verification philosophy

Three layers of claim appear in this project. Mixing them is how complexity hand-waving happens.

| Layer | Content | Status in this repo |
|-------|---------|---------------------|
| **A** | Analytic theorems (Alpöge–Furman, BGSTB, form factor) | External; consumed, not re-proved |
| **B** | Discrete numerical certificates (directed $\rho$, Jacobi $n_+$, sealed Horn facts) | **Operational** |
| **C** | Complexity envelopes and quantum sketches | Instrumented; **holes named and modelled** |

A claim that “the stack gives polylog quantum projection of simple zeta zeros” would require Layer A beyond bandwidth one, a closed Layer C (sound ceiling + proved prefactor + real block-encoding), and a bridge from eigenmodes to ordinates that Layer B does not provide. **We do not make that claim.**

What we claim: Layer B works; Layer C is instrumented so the next person cannot silently assume $C=1$ or round-to-nearest ceilings.

---

## 11. Design principles that held

1. **Executable or reject.** Natural-language claims never enter the certificate path.
2. **Directed rounding for inequalities that must not flip.** Down on numerators that should be large, up on denominators that should be small.
3. **Jacobi as the equalizer.** When the spectrum is uneven, $\rho$ underestimates $n_+/N$.
4. **Name what is not proved.** The QSVT policy predicate carries a known false prefactor and a known FP gap. Alloy and SMT exist to make those holes checkable.
5. **Zero dependency on the critical path.** UUie is C11 + libm. Klong is public-domain. Horn is SWI-Prolog. Quantum scripts use PyTorch only for classical linear algebra.

---

## 12. Lineage

| Work | Contribution |
|------|----------------|
| Weil (1952) | Explicit formula as Hermitian form; positivity $\Leftrightarrow$ RH in the appropriate sense |
| Montgomery (1973) | Pair correlation; form factor $F(\alpha)$; GUE connection (Dyson) |
| Bombieri | Finite-dimensional rank-trace viewpoint |
| BGSTB; Goldston–Suriajaya | Unconditional form-factor control in the complex-zero setting |
| Alpöge–Furman (arXiv:2608.13637, 2026) | $2/3$ and $0.6725$ unconditional simple critical-line proportions |

This repository does not improve those analytic constants. It ships a gated discrete implementation and a documented account of what still fails on the way to polylog quantum spectral projection.

---

## 13. Roadmap (only items that close stated gaps)

| Priority | Item | Closes |
|----------|------|--------|
| P0 | Directed-upward or rational arithmetic in `qsvt_build_report` | FP ceiling gap |
| P0 | Replace $C=1$ by $C\ge 4/\pi$ (ideally constructive GSLW $\approx 4$) in policy + SMT | Prefactor gap |
| P1 | CI fails outside SMT-safe $(\alpha,g)$ cells | Regression to unsound cells |
| P1 | Machine-checked proof of UUie directed-rounding inequalities | Trust in Layer B without reading C |
| P2 | Calibrate $c_0(T)$ against explicit-formula diagonal | Contact-mass asymptotics |
| P3 | Analytic progress on $|\alpha|>1$ form factor | Bandwidth wall (external) |

No roadmap item claims “find a closed form for the zeros.”

---

## 14. Failure modes the gate exists to catch

| Failure | Detection | Exit path |
|---------|-----------|-----------|
| LLM returns English only | No `<klong_kernel>` tag | reject |
| Klong fails to write matrix | missing `matrix_R.dat` | reject |
| Matrix contains NaN/Inf | UUie pre-check | reject |
| $\rho$ and Jacobi fraction both below target | UUie comparison | reject |
| Policy inputs outside domain | Prolog `domain_error` | throw |
| Policy inputs valid but outside envelope | Prolog fail | `false` |
| SMT cell missing for claimed $(\alpha_C,g)$ | `qsvt_smt_manifold_cert` fail | no combined witness |

Silent acceptance of a prose “proof” is the original failure mode this stack was built to eliminate.

---

## 15. Bandwidth wall

Everything in Sections 3–6 that concerns the continuous symbol $g$ and the matrix $R$ lives inside bandwidth one: Fourier support restricted to $|\alpha|\le 1$, where unconditional form-factor asymptotics are known. Crossing $|\alpha|=1$ is not a software problem. It requires new analytic input on $F(\alpha)$ for $|\alpha|>1$. Until that exists, certificates emitted by this repository are only meaningful inside the regime the theorems cover.

---

## 16. Status line

**Classical discrete certificates for the Alpöge–Furman ratio: operational.**  
**Hard gate against non-executable synthesis: operational.**  
**Quantum polylog projection of simple zeta zeros: not claimed; gaps named, modelled, and partially SMT-pruned.**

---

## License

Research code. Individual files may carry additional notices. No warranty. If you reuse the certificates, keep the directed-rounding and Jacobi margins; stripping them reintroduces the failure modes the gate was built to catch.

## Citation

Primary analytic source: Alpöge & Furman, arXiv:2608.13637 (2026).  
Toolkit: https://github.com/AHMADALIPARR/weil-bombieri-zeta-zeros
