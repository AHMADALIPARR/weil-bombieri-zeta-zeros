# Weil–Bombieri Zeta Zeros

**Unconditional simple critical-line zeros of $\zeta(s)$ via finite Hermitian compressions of the Weil form — classical certificates, hard numerical gates, and an honest quantum complexity audit.**

Repository: classical rank-trace machinery for the Alpöge–Furman bound (arXiv:2608.13637), a zero-dependency directed-rounding / Jacobi oracle, a hard LLM synthesis gate, and a layered Alloy + SMT analysis of what *does not* yet follow for QSVT query bounds.

---

## 1. Research goal

The target is the proportion of non-trivial zeros of the Riemann zeta function that are **both simple and on the critical line** $\mathrm{Re}(s)=1/2$, obtained **without assuming RH**.

Alpöge–Furman (2026) proved unconditionally that this proportion is at least $2/3$, and at least $0.6725$ under the Montgomery–Taylor window. Distinct zeros reach at least $5/6$ (about $0.8362$ with the same window). The classical Levinson–Conrey mollifier record was $5/12\approx 0.4167$ for zeros on the line; the new argument works in a different lane.

**Mechanism.** Weil’s explicit formula defines a Hermitian quadratic form $W(f,g)$ on bandwidth-one test functions. Evaluating $W$ on a finite grid of modulated windows yields an $N\times N$ Hermitian matrix $R$. Unconditional Montgomery-type form-factor asymptotics (BGSTB / Goldston–Suriajaya) control the entries. Bombieri’s rank-trace inequality then lower-bounds the number of strictly positive eigenvalues:

$$
n_+(R)\;\ge\;\frac{(\mathrm{tr}\,R)^2}{\mathrm{tr}(R^2)}\,.
$$

Positivity of those eigenvalues forces a matching proportion of zeros in the window to be simple and critical-line. The analytic quantity we maximize is

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
| `uuie/uuie_kernel.c` | C11, zero deps (`-lm` only): directed-rounding $\rho$ + cyclic Jacobi $n_+$ with Gershgorin safety margin |
| `horn/horn_cert.pl` | Hardened SWI-Prolog: type/domain errors, finite guards, underflow protection, `qsvt_polylog_cert/4` |
| `horn/test_qsvt_polylog.pl` | plunit suite |
| `harness/gate.py` | Hard gate: extract `<klong_kernel>` → kg → UUie; **prose rejected** |
| `harness/harness.py` | Synthesis entry points |
| `prompts/muse_system_contract.xml` | Muse must emit executable Klong |
| `.github/workflows/horn-sweep.yml` | Stateless parameter matrix |

### Quantum bridge and complexity audit

| Path | Role |
|------|------|
| `quantum/block_encoding_audit.py` | Circulant-QFT vs LCU, $\delta_{\min}$, QSVT degree budgets |
| `quantum/berry_keating_qsvt.py` | Classical Chebyshev projector + discrete Berry–Keating (simulation) |
| `docs/block-encoding-audit.md` | Where polylog dies |
| `docs/quantum-bridge.md` | $R\mapsto\hat H_{\mathrm{BK}}\mapsto$ QSVT/QPE |
| `docs/qsvt-polylog-soundness.md` | **What `qsvt_polylog_cert` does *not* prove** |

### Formal layer (Alloy + SMT)

| Path | Role |
|------|------|
| `formal/qsvt_counterclaims.als` | FP ceiling under-report; $C=1$ below Zolotarev/GSLW |
| `formal/qsvt_manifold.als` | SAT rounding slip, SAT unsound prefactor, UNSAT hardened invariant |
| `formal/fp_rounding_witness.smt2` | QF_FP **sat**: RNE can undercut RTP (Z3 4.8) |
| `formal/recursive_manifold_prune.py` | QF_NRA $(\alpha_C,g)$ pruner → Horn facts |
| `horn/smt_manifold_cert.pl` | Membership in SMT-certified cells |
| `docs/alloy-smt-manifold.md` | Two-layer index |

---

## 3. Benchmarks (measured)

### 3.1 $\rho$ and $n_+$ with $\delta(\alpha)$ contact ($c_0=1$)

```
   N |   rho_lb |  n+/N |   emin |   emax
  32 |   0.7788 | 1.000 | 1.0000 | 3.6207
  64 |   0.7746 | 1.000 | 1.0000 | 3.6684
 128 |   0.7726 | 1.000 | 1.0000 | 3.6866
 256 |   0.7715 | 1.000 | 1.0000 | 3.6940
 512 |   0.7710 | 1.000 | 1.0000 | 3.6972
1024 |   0.7708 | 1.000 | 1.0000 | 3.6986
```

Without contact: $\rho\approx 0.29$, Jacobi $n_+/N\approx 0.74$–$0.84$. Cauchy–Schwarz slack — Jacobi was built for that.

### 3.2 Block-encoding (with contact)

```
   N | alpha_C | alpha_LCU |  C_U | q(0.05) | q(min)
  64 |  3.6942 |    3.6942 | 2584 |    1021 |     52
 128 |  3.6971 |    3.6971 | 2604 |    1022 |     52
1024 |  3.6996 |    3.6996 | 2676 |    1023 |     52
```

$\alpha_C=\alpha_{\mathrm{LCU}}$; $C_U=O(\log^2 N)$; contact lifts $\delta_{\min}$ so exact-gap degree falls from $\sim 10^{10}$ to $\sim 52$.

### 3.3 Policy (SWI-Prolog 9.0.4)

```
?- qsvt_polylog_cert(1000000, 2.70, 0.05, Q).  % Q = 747
?- qsvt_polylog_cert(1000000, 3.01, 0.05, _).  % false (AlphaCap)
?- qsvt_polylog_cert(0, 2.70, 0.05, _).        % domain_error positive_integer
```

### 3.4 IEEE-754 (Z3 4.8.12)

```
$ z3 formal/fp_rounding_witness.smt2
sat   # RNE(alpha/gap) < RTP(alpha/gap) for concrete normal binary64 values
```

---

## 4. What is proved here vs not

**Proved / enforced:** directed-rounding lower bound on $\rho$; exact $n_+$ with Gershgorin margin; hard reject of non-executable LLM output; policy type/domain/finite guards; Alloy/SMT encoding of the FP-ceiling gap and the $C=1$ prefactor gap.

**Not proved:** soundness of $\lceil\mathrm{fl}((\alpha_C/g)\ln(1/\varepsilon))\rceil$ as an upper bound on the true ceiling; existence of a QSVT phase sequence of that degree ($C=1$ is below Zolotarev $\approx 4/\pi$ and GSLW $\approx 4$; reference point gives 747 vs 950 vs 2985); hardware gate counts for a real Circulant-QFT circuit; localisation of individual $\gamma_n$; anything past bandwidth one.

---

## 5. Architecture

```
LLM/Muse → <klong_kernel> → gate.py → kg → matrix_R.dat → uuie_kernel
    → rank_trace_cert → Horn simple_critical / qsvt_polylog_cert
                       → optional qsvt_smt_manifold_cert (QF_NRA cells)
```

Parallel: block-encoding audit and Berry–Keating simulation on the same $R$ — cost models, not the hard gate.

---

## 6. Open problems

1. Bandwidth $|\alpha|>1$ (analytic, external).  
2. Sound ceiling under FP (directed-up / rationals in the policy predicate).  
3. Proved constructive prefactor $C_{\mathrm{cert}}\ge 4/\pi$ (ideally GSLW) before polylog QSVT claims.  
4. Individual zero locations from positive eigenmodes.  
5. Calibrate $c_0(T)$ to the explicit-formula diagonal.  
6. Machine-checked proof of UUie directed-rounding inequalities.

---

## 7. Run

```bash
cc -std=c11 -O2 -frounding-math -ffp-contract=off uuie/uuie_kernel.c -lm -o uuie/uuie_kernel
kg -l klong/weil_horn.kg
./uuie/uuie_kernel 128 0.6725 matrix_R.dat
swipl -q -s horn/horn_cert.pl -g 'qsvt_polylog_cert(1000000,2.70,0.05,Q),writeln(Q),halt'
z3 formal/fp_rounding_witness.smt2
python3 formal/recursive_manifold_prune.py > horn/certified_manifold_cells.pl
```

---

## 8. Design principles that held

Executable or reject. Directed rounding on inequalities that must not flip. Jacobi when the spectrum is uneven. Name what is not proved. Zero dependency on the critical path (C11, Klong, SWI-Prolog).

---

## 9. Lineage

Weil (1952) → Montgomery (1973) → Bombieri rank-trace → BGSTB / Goldston–Suriajaya unconditional form factor → Alpöge–Furman (2026) $2/3$ and $0.6725$.

This toolkit does not improve those constants. It ships a gated discrete implementation and a documented account of what still fails on the way to polylog quantum spectral projection.

---

## 10. Method notes (discrete)

Montgomery–Taylor window on $[-1,1]$; weighted sinc Gram; $\delta(\alpha)$ realised as $c_0 I$ with $c_0=1$ so discrete $\rho$ clears $0.6725$. Trace under `FE_DOWNWARD`, HS-norm under `FE_UPWARD`. Jacobi on a private copy; positivity after Gershgorin residual. Before contact, $\rho\approx 0.29$ vs $n_+\approx 0.74$–$0.84$ — Cauchy–Schwarz slack; Jacobi recovers the count.

---

## 11. Method notes (quantum limits)

Circulant-QFT keeps $\alpha_C=O(1)$ for non-negative symbols; $C_U=O(\log^2 N)$ in the sketch. Obstructions: vanishing gap without contact; degree formula with $C=1$ below Zolotarev and GSLW. Policy uses $C=1$ as a *budget filter*; SMT prune with $C=4$ excludes cells where constructive QSVT cannot meet QueryCap. Berry–Keating script is classical linear algebra, not a runtime claim.

---

## 12. Verification philosophy

**Layer A** — external analytic theorems (Alpöge–Furman, BGSTB).  
**Layer B** — discrete numerical certificates (this repo; exit codes, not prose).  
**Layer C** — complexity envelopes with *named holes* (FP ceiling, $C=1$), encoded in Alloy/SMT.

We claim Layer B works and Layer C is instrumented. We do **not** claim end-to-end polylog quantum projection of simple zeta zeros.

---

## 13. Reproduce contact-mass table

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
for N in [64,128,256,512,1024]:
    T = build(N)
    tr, hs2 = torch.trace(T).item(), torch.sum(T*T).item()
    print(N, round((tr*tr)/(N*hs2),4), round((torch.linalg.eigvalsh(T)>1e-12).sum().item()/N,4))
```

Expect $\rho\in[0.77,0.78]$, $n_+/N=1$.

---

## 14. Roadmap (closes stated gaps only)

| Priority | Item |
|----------|------|
| P0 | Directed-up or rational arithmetic in policy ceiling |
| P0 | $C\ge 4/\pi$ (ideally GSLW $\approx 4$) in policy + SMT |
| P1 | CI fails outside SMT-safe $(\alpha,g)$ cells |
| P1 | Machine-checked UUie directed-rounding proof |
| P2 | Calibrate $c_0(T)$ to explicit-formula diagonal |
| P3 | Analytic $|\alpha|>1$ (external) |

---

## 15. Status line

**Classical discrete certificates: operational.**  
**Hard gate against non-executable synthesis: operational.**  
**Quantum polylog projection of simple zeta zeros: not claimed; gaps named, modelled, partially SMT-pruned.**

## License

Research code. No warranty. Keep directed-rounding and Jacobi margins if you reuse certificates.
