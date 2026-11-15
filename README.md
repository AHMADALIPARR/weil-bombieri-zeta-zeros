# Weil–Bombieri Zeta Zeros

**Unconditional simple critical-line zeros of the Riemann zeta function via finite Hermitian compressions of the Weil explicit formula.**

This repository implements the discrete side of the Alpöge–Furman argument (arXiv:2608.13637), gates every candidate matrix through directed-rounding and exact Jacobi certification, and documents — with Alloy and SMT — what still fails when the same matrices are promoted to polylogarithmic QSVT query bounds.

It is a certificate engine and a complexity truth-serum. It is not a zero factory and it does not claim a quantum algorithm that extracts individual ordinates in polylog time.

**Full measured tables:** [`docs/BENCHMARKS.md`](docs/BENCHMARKS.md) (truncation error, gate breakdown, extended $N$ grid, degree landscape $C=1$ vs $4/\pi$ vs $4$, $\alpha_C=\alpha_{\mathrm{LCU}}$ identity, policy results, sparse LCU $K$-sweep).

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

### 1.3 Mechanism

Weil’s explicit formula $\to$ Hermitian form $W(f,g)$ $\to$ finite grid $\to$ $N\times N$ matrix $R$ $\to$ Bombieri rank-trace

$$
n_+(R)\;\ge\;\frac{(\operatorname{tr} R)^2}{\operatorname{tr}(R^2)},\qquad
\rho(R)\;=\;\frac{(\operatorname{tr} R)^2}{N\,\|R\|_{\mathrm{HS}}^2}.
$$

Unconditional form-factor control for $|\alpha|\le 1$ (BGSTB / Goldston–Suriajaya). Hard constraints: conjugate symmetry, unit band, stability, directed-rounding $\rho$ or Jacobi $n_+/N$ above target.

---

## 2. Repository map

| Path | Role | Status |
|------|------|--------|
| `klong/weil_horn.kg` | MT window, Toeplitz Gram, $\delta(\alpha)$ contact | operational |
| `uuie/uuie_kernel.c` | Directed-rounding $\rho$ + Jacobi $n_+$ | operational |
| `horn/horn_cert.pl` | Hardened policy + Horn rules | operational |
| `harness/gate.py` | LLM → kernel → kg → UUie; prose rejected | operational |
| `quantum/block_encoding_audit.py` | Circulant-QFT / LCU / QSVT degrees | operational |
| `quantum/sparse_lcu.py` | **Bandwidth + threshold LCU truncation** | operational |
| `formal/fp_rounding_witness.smt2` | QF_FP RNE $<$ RTP | **sat** |
| `formal/recursive_manifold_prune.py` | QF_NRA manifold pruner | operational |
| `docs/BENCHMARKS.md` | **Complete measured tables** | docs |
| `docs/qsvt-polylog-soundness.md` | What policy does not prove | docs |

---

## 3. Benchmarks (summary)

See **[`docs/BENCHMARKS.md`](docs/BENCHMARKS.md)** for full tables. Headline numbers:

| Regime | $\rho$ | $n_+/N$ | $\delta_{\min}$ | $q(\delta_{\min})$ |
|--------|--------|---------|-----------------|-------------------|
| No contact, $N=1024$ | 0.2887 | 0.7432 | $\sim 10^{-12}$ | $\sim 10^{10}$ |
| Contact $c_0=1$, $N=1024$ | 0.7708 | 1.0000 | $1.00$ | 52 |

| Prefactor | Degree at $(2.70,0.05,10^{-6})$ | vs QueryCap 1024 |
|-----------|----------------------------------|------------------|
| $C=1$ (policy, unproved) | 747 | passes |
| $C=4/\pi$ (Zolotarev LB) | $\approx 950$ | exceeds 747 |
| $C=4$ (GSLW) | $\approx 2985$ | exceeds QueryCap |

$\alpha_C=\alpha_{\mathrm{LCU}}$ at every measured $N$. Gate sketch $C_U\sim 2600$ at $N=128$, $O(\log^2 N)$.

---

## 4. Sparse LCU truncation

Module: [`quantum/sparse_lcu.py`](quantum/sparse_lcu.py).

The Montgomery–Taylor Toeplitz coefficients decay empirically as $|t_d|\sim d^{-2.16}$. Two truncation methods:

| Method | API | Keeps |
|--------|-----|-------|
| **Bandwidth** | `truncate_bandwidth(T, t_col, K)` | lags $\|d\|\le K$ |
| **Threshold** | `truncate_threshold(T, t_col, tau)` | $\|t_d\|\ge\tau$ (always $d=0$) |

Each returns spectral error $\|T-T_{\mathrm{sparse}}\|_2$, Frobenius error, nnz fraction, and truncated $\alpha_{\mathrm{LCU},K}$.

**$K$-sweep at $N=256$ (no contact):**

| $K$ | $\|T-T_K\|_2$ | nnz | $\alpha_K$ | terms |
|------:|----------------:|----:|-----------:|------:|
| 8 | $4.43\times 10^{-2}$ | 0.065 | 2.651 | 9 |
| **16** | **$1.85\times 10^{-2}$** | **0.125** | **2.677** | **17** |
| 32 | $7.30\times 10^{-3}$ | 0.238 | 2.689 | 33 |
| 64 | $2.33\times 10^{-3}$ | 0.440 | 2.694 | 65 |

Threshold $\tau=10^{-3}$: $\mathrm{err}_2=2.18\times 10^{-2}$, 15 terms, $\alpha_K=2.673$.

**Recommendation:** Circulant-QFT stays the zero-truncation block-encoding ($\alpha_C=\alpha_{\mathrm{LCU}}$, $O(\log^2 N)$). Sparse LCU is the baseline when you want fewer explicit diagonals (classical sparsifier for UUie, or shallow SELECT).

```bash
python quantum/sparse_lcu.py --N 256 --sweep
python quantum/sparse_lcu.py --N 256 --K 16
python quantum/sparse_lcu.py --N 256 --tau 1e-3
```

---

## 5. Proved vs not

**Proved/enforced:** directed-rounding $\rho$; Jacobi $n_+$ with Gershgorin margin; hard reject of non-executable LLM output; policy type/domain/finite guards; RNE can undercut RTP (Z3 sat); $C=1$ below Zolotarev/GSLW on reference parameters.

**Not proved:** soundness of round-to-nearest ceiling as upper bound; existence of QSVT phases at degree $\widehat Q$; hardware gate counts; individual $\gamma_n$; bandwidth $>1$.

---

## 6. Architecture

```
LLM → <klong_kernel> → gate → kg → matrix_R.dat → uuie
  → rank_trace_cert → Horn classical / qsvt_polylog_cert / smt_manifold_cert

Parallel cost models:
  block_encoding_audit.py   Circulant-QFT / full LCU
  sparse_lcu.py             bandwidth / threshold truncation
```

---

## 7. Open problems

| # | Problem |
|---|--------|
| 1 | Form factor $|\alpha|>1$ (analytic, external) |
| 2 | Sound ceiling under FP (directed-up / rationals) |
| 3 | Proved prefactor $C\ge 4/\pi$ (ideally GSLW) |
| 4 | Eigenmodes $\mapsto\gamma_n$ |
| 5 | Calibrate $c_0(T)$ |
| 6 | Machine-checked UUie |

---

## 8. Run

```bash
# Classical certificate
cc -std=c11 -O2 -frounding-math -ffp-contract=off uuie/uuie_kernel.c -lm -o uuie/uuie_kernel
kg -l klong/weil_horn.kg
./uuie/uuie_kernel 128 0.6725 matrix_R.dat

# Cost models
python3 quantum/block_encoding_audit.py
python3 quantum/sparse_lcu.py --N 256 --sweep

# Formal
z3 formal/fp_rounding_witness.smt2
```

---

## 9. Status

**Classical discrete certificates: operational.**  
**Hard gate: operational.**  
**Sparse LCU truncation: operational.**  
**Quantum polylog projection of simple zeros: not claimed; gaps named and measured.**

## License

Research code. No warranty. Keep directed-rounding and Jacobi margins.
