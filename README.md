# Weil–Bombieri Zeta Zeros

**Unconditional simple critical-line zeros of $\zeta(s)$ via finite Hermitian compressions of the Weil form — classical certificates, hard numerical gates, and an honest quantum complexity audit.**

Repository: classical rank-trace machinery for the Alpöge–Furman bound (arXiv:2608.13637), a zero-dependency directed-rounding / Jacobi oracle, a hard LLM synthesis gate, and a layered Alloy + SMT analysis of what *does not* yet follow for QSVT query bounds.

---

## 1. Research goal

The target is the proportion of non-trivial zeros of the Riemann zeta function that are **both simple and on the critical line** $\mathrm{Re}(s)=1/2$, obtained **without assuming RH**.

Alpöge–Furman (2026) proved unconditionally that this proportion is at least $2/3$, and at least $0.6725$ under the Montgomery–Taylor window. Distinct zeros reach at least $5/6$ (about $0.8362$ with the same window). The classical Levinson–Conrey mollifier record was $5/12\approx 0.4167$ for zeros on the line; the new argument works in a different lane.

**Mechanism (one paragraph).**  
Weil’s explicit formula defines a Hermitian quadratic form $W(f,g)$ on bandwidth-one test functions. Evaluating $W$ on a finite grid of modulated windows yields an $N\times N$ Hermitian matrix $R$. Unconditional Montgomery-type form-factor asymptotics (BGSTB / Goldston–Suriajaya) control the entries. Bombieri’s rank-trace inequality then lower-bounds the number of strictly positive eigenvalues:

$$
n_+(R)\;\ge\;\frac{(\mathrm{tr}\,R)^2}{\mathrm{tr}(R^2)}\,.
$$

Positivity of those eigenvalues forces a matching proportion of zeros in the window to be simple and critical-line. The analytic quantity we maximize is the normalized ratio

$$
\rho(R)\;=\;\frac{(\mathrm{tr}\,R)^2}{N\,\|R\|_{\mathrm{HS}}^2}\,.
$$

**Hard constraints on every candidate $R$:** conjugate symmetry, unit-band Fourier support, numerical stability (no NaN/Inf), and — in this repo — a directed-rounding lower bound on $\rho$ together with an exact Jacobi count of $n_+$.

---

## 2. What this repository contains

### Classical certificate stack (Horn–Klong–UUie)

| Path | Role |
|------|------|
| `klong/weil_horn.kg` | Pure Klong: Montgomery–Taylor window, sinc-Toeplitz Gram, **$\delta(\alpha)$ diagonal contact mass**, matrix dump |
| `uuie/uuie_kernel.c` | C11, zero deps (`-lm` only): directed-rounding $\rho$ (trace `FE_DOWNWARD`, HS-norm `FE_UPWARD`) + cyclic Jacobi $n_+$ with Gershgorin safety margin |
| `horn/horn_cert.pl` | Hardened SWI-Prolog: type/domain errors, finite-number guards, underflow protection, `qsvt_polylog_cert/4` policy envelope |
| `horn/test_qsvt_polylog.pl` | plunit suite for the policy predicate |
| `harness/gate.py` | Hard gate: LLM output → extract `<klong_kernel>` → run kg → UUie; **prose-only answers are rejected** |
| `harness/harness.py` | Synthesis loop entry points around the gate |
| `prompts/muse_system_contract.xml` | Muse contract forced to emit executable Klong, not prose |
| `.github/workflows/horn-sweep.yml` | Stateless parameter matrix runner |

### Quantum bridge and complexity audit

| Path | Role |
|------|------|
| `quantum/block_encoding_audit.py` | Circulant-QFT vs LCU subnormalization, truncation error, $\delta_{\min}$, QSVT degree budgets |
| `quantum/berry_keating_qsvt.py` | Classical Chebyshev/Jackson projector + discrete Berry–Keating generator (simulation only) |
| `docs/block-encoding-audit.md` | Why Circulant-QFT keeps $\alpha_C=O(1)$ and where polylog dies |
| `docs/quantum-bridge.md` | Map $R\mapsto \hat H_{\mathrm{BK}}\mapsto$ QSVT/QPE |
| `docs/qsvt-polylog-soundness.md` | **What `qsvt_polylog_cert` does *not* prove** |

### Formal layer (Alloy + SMT)

| Path | Role |
|------|------|
| `formal/qsvt_counterclaims.als` | Counterclaims: FP ceiling under-report; $C=1$ below Zolotarev / GSLW |
| `formal/qsvt_manifold.als` | Bounded manifold: SAT rounding slip, SAT unsound prefactor, UNSAT hardened invariant |
| `formal/fp_rounding_witness.smt2` | QF_FP: **sat** witness that RNE can undercut RTP on the same quotient (Z3 4.8) |
| `formal/recursive_manifold_prune.py` | QF_NRA recursive $(\alpha_C,g)$ pruner → Horn facts |
| `horn/smt_manifold_cert.pl` | `qsvt_smt_manifold_cert/3` membership in SMT-certified cells |
| `docs/alloy-smt-manifold.md` | Two-layer verification index |

### Legacy / seed

| Path | Role |
|------|------|
| `kernels/weil_probe.bqn` | Original CBQN probe |
| `docs/constraints.md` | Conjugate symmetry, unit band, stability |
| `docs/hard-gate.md` | Gate acceptance criteria |
| `docs/jacobi-eigensolver.md` | Jacobi API and rounding discipline |
| `docs/horn-klong-uuie.md` | Classical stack overview |

---

## 3. Benchmarks (measured, not aspirational)

### 3.1 Trace-moment ratio and exact $n_+$ with $\delta(\alpha)$ contact

Montgomery–Taylor continuous symbol **plus** diagonal contact $c_0 I$ with $c_0=1$. All eigenvalues lift above zero; Jacobi reports $n_+/N=1$; analytic $\rho$ clears $0.6725$.

```
   N |   rho_lb |  n+/N |   emin |   emax
  32 |   0.7788 | 1.000 | 1.0000 | 3.6207
  64 |   0.7746 | 1.000 | 1.0000 | 3.6684
 128 |   0.7726 | 1.000 | 1.0000 | 3.6866
 256 |   0.7715 | 1.000 | 1.0000 | 3.6940
 512 |   0.7710 | 1.000 | 1.0000 | 3.6972
1024 |   0.7708 | 1.000 | 1.0000 | 3.6986
```

Without the contact mass, the same continuous symbol alone gave $\rho\approx 0.29$ while Jacobi still saw $n_+/N\approx 0.74$–$0.84$. That gap is exactly the Cauchy–Schwarz slack: equal positive eigenvalues would make $\rho=n_+/N$; a decaying spectrum inflates $\|R\|_{\mathrm{HS}}^2$ relative to $(\mathrm{tr}\,R)^2$. The Jacobi oracle was built to see past that slack.

### 3.2 Block-encoding audit (with contact)

```
   N | alpha_C | alpha_LCU |  C_U gates | q(0.05) | q(min)
  64 |  3.6942 |    3.6942 |       2584 |    1021 |     52
 128 |  3.6971 |    3.6971 |       2604 |    1022 |     52
 256 |  3.6985 |    3.6985 |       2626 |    1022 |     52
 512 |  3.6993 |    3.6993 |       2650 |    1023 |     52
1024 |  3.6996 |    3.6996 |       2676 |    1023 |     52
```

- $\alpha_C=\alpha_{\mathrm{LCU}}$ (non-negative Fourier coefficients → Circulant-QFT matches full LCU 1-norm).
- $C_U=O(\log^2 N)$ for the Circulant-QFT block-encoding sketch.
- Contact lifts $\delta_{\min}$ to $\Theta(1)$, so exact-gap QSVT degree collapses from $\sim 10^{10}$ (no contact) to $\sim 52$.

### 3.3 Policy predicate under SWI-Prolog 9.0.4

```
?- qsvt_polylog_cert(1000000, 2.70, 0.05, Q).
Q = 747.

?- qsvt_polylog_cert(1000000, 3.0, 0.05, Q).
Q = 829.

?- qsvt_polylog_cert(1000000, 3.01, 0.05, _).
false.                          % above AlphaCap

?- qsvt_polylog_cert(1000000, 2.70, 0.049, _).
false.                          % below GapFloor

?- qsvt_polylog_cert(0, 2.70, 0.05, _).
ERROR: domain_error(positive_integer, 0)  [context qsvt_polylog_cert/4]
```

### 3.4 IEEE-754 disagreement (Z3 4.8.12)

```
$ z3 formal/fp_rounding_witness.smt2
sat
```

Concrete normal binary64 $\alpha,g$ with $\mathrm{RNE}(\alpha/g)<\mathrm{RTP}(\alpha/g)$. That is the structural fact behind the ceiling-soundness gap: round-to-nearest can sit on the wrong side of an integer discontinuity relative to the exact real product.

---

## 4. What is proved (in this codebase)

**Proved / enforced here**

1. **Directed-rounding lower bound on $\rho$.** Trace under `FE_DOWNWARD`, Hilbert–Schmidt under `FE_UPWARD`; ratio formed under downward rounding. A passing certificate is a machine-checkable inequality $\rho_{\mathrm{lower}}>\mathrm{target}$ (or Jacobi fraction $>\mathrm{target}$).
2. **Exact $n_+$ under a Gershgorin residual margin.** Jacobi diagonalisation on a private copy; positivity tested after subtracting a directed-rounding row-sum safety term.
3. **Hard rejection of non-executable LLM output.** No `<klong_kernel>` → reject. Klong non-zero exit or missing matrix → reject. UUie exit $\neq 0$ → reject.
4. **Policy envelope discipline.** Instantiation/type/domain errors for invalid $(N,\alpha_C,g)$; finite-number and underflow guards; fail (not throw) when valid parameters sit outside $(\alpha_C\le 3,\, g\ge 0.05,\, \widehat Q\le 1024)$.
5. **Structural counterclaims.** Alloy + SMT encode: (i) RNE can undercut RTP; (ii) $C=1$ lies below Zolotarev ($4/\pi$) and constructive GSLW ($\approx 4$) degree formulae on the reference parameters.

**Not proved by this codebase**

1. **That $\widehat Q=\lceil\mathrm{fl}((\alpha_C/g)\ln(1/\varepsilon))\rceil$ is a sound upper bound on the true mathematical ceiling.** Round-to-nearest does not guarantee $\widehat x\ge x$ before `ceiling`.
2. **That degree $\widehat Q$ admits a QSVT phase sequence implementing a $\varepsilon$-accurate sign polynomial on the gap.** The hardcoded prefactor $C=1$ is strictly below known lower and constructive upper bounds. On $(\alpha_C,g,\varepsilon)=(2.70,0.05,10^{-6})$ the Prolog degree is $747$; Zolotarev already requires $\approx 950$; constructive GSLW $\approx 2985$.
3. **A full Circulant-QFT block-encoding circuit with proved gate counts on hardware.** $C_U$ numbers are analytic sketches from QFT + symbol-oracle accounting, not compiled circuits.
4. **End-to-end extraction of individual ordinates $\gamma_n$.** Rank-trace counts positive eigenvalues; it does not localise zeros. QPE readout still scales with the number of sampled eigenphases.
5. **Anything beyond bandwidth one without new analytic input.** Unconditional form-factor control is only for $|\alpha|\le 1$. Crossing that wall is an open analytic problem, not a software one.

---

## 5. Architecture (how the pieces fit)

```
LLM / Muse
   │  must emit <klong_kernel>…</klong_kernel>
   ▼
harness/gate.py
   │  kg → matrix_R.dat
   │  uuie_kernel N target matrix_R.dat
   ▼
rank_trace_cert(...)          ← directed ρ + Jacobi n+
   │
   ├─► horn classical: simple_critical / simple_critical_exact
   │
   └─► qsvt_polylog_cert      ← policy only (not a QSVT existence proof)
            │
            └─► optional: qsvt_smt_manifold_cert  ← membership in QF_NRA-certified (α,g) cell
```

Parallel track: `block_encoding_audit.py` and `berry_keating_qsvt.py` study the *same* matrix $R$ under Circulant-QFT cost models and classical polynomial projectors. They do not feed the hard gate; they bound expectations for any future quantum implementation.

---

## 6. Open problems (honest list)

1. **Bandwidth $>1$.** Unconditional pair correlation past $|\alpha|=1$ would raise the classical ceiling. No code change substitutes for that theorem.
2. **Sound ceiling under floating point.** Replace `FE_TONEAREST` arithmetic in the policy predicate by directed upward rounding or `clp(q)` rationals so that reported envelopes cannot under-shoot $Q^*$.
3. **Proved constructive prefactor.** Swap $C=1$ for a theorem-backed $C_{\mathrm{cert}}\ge C_{\mathrm{Zolotarev}}$ (ideally matching a verified QSP phase table) before claiming polylog QSVT query bounds.
4. **Individual zero locations.** Rank-trace is a counting argument. Connecting positive eigenmodes of $R$ to explicit $\gamma_n$ remains open even under RH-style spectral interpretations.
5. **Scaling the contact mass.** $c_0=1$ is a working normalisation that clears $0.6725$ in the discrete model; matching the precise $T\log T$ coefficient of the explicit formula across heights $T$ needs a more careful asymptotic calibration.
6. **Formal verification of UUie.** The C kernel is small and auditable; a machine-checked proof of the directed-rounding inequalities (e.g. in Coq/Isabelle with a floating-point library) is still future work.

---

## 7. How to run the classical certificate path

```bash
# Build the oracle
cc -std=c11 -O2 -frounding-math -ffp-contract=off \
   uuie/uuie_kernel.c -lm -o uuie/uuie_kernel

# Klong (requires Nils Holm kg + math.kg on the load path)
kg -l klong/weil_horn.kg          # writes matrix_R.dat, prints residual

# Certificate
./uuie/uuie_kernel 128 0.6725 matrix_R.dat
# → rank_trace_cert(128, TrDown, Hs2Up, RhoLower, Nplus, JacobiFrac, valid).
```

Hard gate from Python:

```python
from harness.gate import clean_and_gate_llm_output
verdict = clean_and_gate_llm_output(raw_llm_text, n=128, target_rho=0.6725)
assert verdict["accepted"]  # else reason in verdict["reason"]
```

Policy predicate:

```bash
swipl -q -s horn/horn_cert.pl -g "qsvt_polylog_cert(1000000,2.70,0.05,Q), writeln(Q), halt"
```

FP witness:

```bash
z3 formal/fp_rounding_witness.smt2
```

Manifold prune (requires `z3` on `PATH`):

```bash
python3 formal/recursive_manifold_prune.py > horn/certified_manifold_cells.pl
```

---

## 8. Design principles that actually held

- **Executable or reject.** Natural-language claims never enter the certificate path.
- **Directed rounding for inequalities that must not flip.** Down on numerators that should be large, up on denominators that should be small.
- **Jacobi as the equalizer.** When the spectrum is uneven, $\rho$ underestimates $n_+/N$; the eigensolver reports the count the analytic bound only lower-bounds.
- **Say what is not proved.** The QSVT policy predicate is a budget check with a known false prefactor and a known FP gap. Encoding that in Alloy/SMT is part of the deliverable, not an embarrassment to hide.
- **Zero dependency on the critical path.** UUie is C11 + libm. Klong is a public-domain array language. Horn is SWI-Prolog. The quantum scripts use only PyTorch for classical linear algebra simulations.

---

## 9. Lineage

- Weil (1952): explicit formula as Hermitian form; positivity $\Leftrightarrow$ RH in the appropriate sense.
- Montgomery (1973): pair correlation; form factor $F(\alpha)$; GUE connection (Dyson).
- Bombieri: finite-dimensional rank-trace viewpoint used in the modern argument.
- Baluyot–Goldston–Suriajaya–Turnage-Butterbaugh; Goldston–Suriajaya: unconditional form-factor control in the complex-zero setting.
- Alpöge–Furman (arXiv:2608.13637, 2026): $2/3$ and $0.6725$ unconditional simple critical-line proportions via the compression + rank-trace route.

This repository does not claim to improve those analytic constants. It claims a **reproducible, gated, floating-point-aware implementation** of the discrete side, plus a **documented account of what still fails** when one tries to promote the same matrix $R$ to a polylogarithmic quantum spectral projector.

---

## 10. License

Research code. Individual files may carry additional notices. No warranty. If you use the certificates, keep the directed-rounding and Jacobi margins; stripping them reintroduces the exact failure modes the gate was built to catch.
