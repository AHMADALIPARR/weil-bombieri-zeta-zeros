# Weil-Bombieri Zeta Zeros

Discrete certificate tooling for the unconditional result on simple critical-line zeros of the Riemann zeta function via finite Hermitian compressions of the Weil explicit formula. The analytic theorem is from the cited paper; this code does not re-prove it.

Companion tables: [docs/BENCHMARKS.md](docs/BENCHMARKS.md).

---

## 1. Research goal

Let `N(T)` count non-trivial zeros of zeta with `0 < Im(s) <= T`. Let `N_s(T)` count those that are **simple and on the critical line** `Re(s) = 1/2`. The target is an unconditional lower bound

```text
liminf N_s(T)/N(T)  >=  rho_0
```

### Historical record

| Result | Bound | Method | Year |
|--------|-------|--------|------|
| Levinson | 1/3 on the line | mollifiers | 1974 |
| Conrey | 2/5 = 0.4000 on the line | mollifiers | 1989 |
| Bui-Conrey-Young et al. | about 0.414 on the line | refined mollifiers | 2010s |
| Pratt-Robles-Zaharescu-Zeindler | 5/12 on the line | mollifiers | 2020 |
| **Alpoge-Furman** | **2/3 simple + critical** | Weil form + rank-trace | 2026 |
| **Alpoge-Furman (MT window)** | **0.6725 simple + critical** | Montgomery-Taylor test function | 2026 |
| Alpoge-Furman | 5/6 distinct zeros | same lane | 2026 |
| Alpoge-Furman (MT) | about 0.8362 distinct | same lane | 2026 |

### Mechanism

Weil explicit formula defines a Hermitian form `W(f,g)`. Restrict to a finite grid of modulated bandwidth-one windows to get an `N x N` Hermitian matrix `R`. Unconditional Montgomery form-factor control for `|alpha| <= 1` (BGSTB / Goldston-Suriajaya) shapes the entries. Bombieri rank-trace gives

```text
n_+(R)  >=  (tr R)^2 / tr(R^2)
rho(R)  =   (tr R)^2 / (N * ||R||_HS^2)
```

Positive eigenvalues force simple critical-line zeros in the window. Hard constraints on every candidate `R`:

1. Conjugate symmetry `R = R^H`
2. Unit-band Fourier support
3. No NaN/Inf
4. Directed-rounding lower bound on `rho`, or exact Jacobi `n_+/N`, above target (default 0.6725)

---

## 2. Repository map

| Path | Role | Status (checked 2026-11-15) |
|------|------|------|
| `klong/weil_horn.kg` | MT window, sinc Gram matrix, delta(alpha) contact, writes `matrix_R.dat` | runs (Klong 20221212) |
| `uuie/uuie_kernel.c` | Directed-rounding rho lower bound + Jacobi n_+ count | compiles and runs (gcc, C11) |
| `horn/horn_cert.pl` | Hardened policy predicate + combined witness | plunit 20/20 pass (SWI-Prolog 9.2.9) |
| `horn/test_qsvt_polylog.pl` | plunit suite for `horn_cert.pl` | see above |
| `horn/smt_manifold_cert.pl` | Consumes `smt_certified_cell/6` facts | loads; no generator left (see below) |
| `formal/fp_rounding_witness.smt2` | QF_FP: RNE can undercut RTP | sat (Z3 5.4.1) |
| `formal/qsvt_manifold.als` | Alloy SAT/UNSAT manifold | not run in this pass |
| `formal/qsvt_counterclaims.als` | Alloy counterclaims | not run in this pass |
| `kernels/weil_probe.bqn` | CBQN trace-moment probe | not run in this pass (no CBQN installed) |
| `prompts/muse_system_contract.xml` | Output contract for a synthesis model | text |
| `.github/workflows/horn-sweep.yml` | Manual matrix job; builds the C kernel only | not run in this pass |
| `docs/qsvt-polylog-soundness.md` | What the policy does not prove | docs |

---

## 3. Measured benchmarks

### 3.1 No contact mass

| N | rho | n+/N | delta_min | alpha_C | C_U | q(0.05) | q(delta_min) |
|------:|---------:|---------:|----------------:|----------:|------:|----------:|-------------------:|
| 64 | 0.2932 | 0.8438 | 6.91e-12 | 2.6942 | 2584 | 745 | ~3.72e10 |
| 128 | 0.2908 | 0.7969 | 1.68e-12 | 2.6971 | 2604 | 746 | ~3.73e10 |
| 256 | 0.2895 | 0.7656 | 2.54e-12 | 2.6985 | 2626 | 746 | ~3.73e10 |
| 512 | 0.2889 | 0.7520 | 1.07e-12 | 2.6993 | 2650 | 746 | ~3.73e10 |
| 1024 | 0.2887 | 0.7432 | 1.97e-12 | 2.6996 | 2676 | 746 | ~3.73e10 |

rho never clears 0.6725. Jacobi n+/N still exceeds 2/3. That gap is why the eigensolver is mandatory.

### 3.2 Contact c0 = 1

| N | rho | n+/N | delta_min | alpha_C | C_U | q(0.05) | q(delta_min) |
|------:|---------:|---------:|----------:|----------:|------:|----------:|-------------:|
| 64 | 0.7746 | 1.0000 | 1.00 | 3.6942 | 2584 | 1021 | 52 |
| 128 | 0.7726 | 1.0000 | 1.00 | 3.6971 | 2604 | 1022 | 52 |
| 256 | 0.7715 | 1.0000 | 1.00 | 3.6985 | 2626 | 1022 | 52 |
| 512 | 0.7710 | 1.0000 | 1.00 | 3.6993 | 2650 | 1023 | 52 |
| 1024 | 0.7708 | 1.0000 | 1.00 | 3.6996 | 2676 | 1023 | 52 |

Both rho and n+/N clear 0.6725. Exact-gap QSVT degree collapses from ~1e10 to 52.

### 3.3 Contact effect at N = 1024

| Quantity | No contact | Contact c0=1 | Change |
|----------|------------|--------------|--------|
| rho | 0.2887 | 0.7708 | x2.67 |
| n+/N | 0.7432 | 1.0000 | +0.2568 |
| delta_min | 1.97e-12 | 1.00 | x~5e11 |
| q(delta_min) | ~3.73e10 | 52 | x~7e-10 |

### 3.4 Degree formulae at (alpha_C, gap, eps) = (2.70, 0.05, 1e-6)

| Formula | Prefactor C | Degree | vs QueryCap 1024 |
|---------|-------------|--------|------------------|
| Prolog policy (unproved) | 1.0000 | **747** | passes |
| Zolotarev lower bound | 4/pi ~ 1.2732 | **~950** | exceeds 747 |
| Constructive GSLW | ~4 | **~2985** | exceeds QueryCap |

No odd polynomial of degree 747 meets QSVT accuracy at this gap. The policy predicate is a budget filter, not a QSVT existence proof.

### 3.5 alpha_C equals alpha_LCU

| N | No contact | Contact |
|------:|------------|---------|
| 64 | 2.6942 = 2.6942 | 3.6942 = 3.6942 |
| 128 | 2.6971 = 2.6971 | 3.6971 = 3.6971 |
| 1024 | 2.6996 = 2.6996 | 3.6996 = 3.6996 |

Non-negative Fourier coefficients imply peak circulant eigenvalue equals full LCU 1-norm.

---

## 4. Sparse LCU truncation

| Method | Keeps |
|--------|-------|
| Bandwidth | lags with `abs(d) <= K` |
| Threshold | lags with `abs(t_d) >= tau` (always d = 0) |

### K-sweep at N = 256 (no contact)

| K | err_2 = norm(T - T_K, 2) | nnz fraction | alpha_K | terms |
|------:|-------------:|------:|----------:|------:|
| 8 | 4.43e-02 | 0.065 | 2.651 | 9 |
| **16** | **1.85e-02** | **0.125** | **2.677** | **17** |
| 32 | 7.30e-03 | 0.238 | 2.689 | 33 |
| 64 | 2.33e-03 | 0.440 | 2.694 | 65 |

These rows were re-checked against a run of the module on 2026-11-15, before it was removed.

Circulant-QFT remains preferred for zero truncation error at O(log^2 N) gate cost. Sparse LCU is the baseline when fewer explicit diagonals are needed.

---

## 5. What is proved here vs not

**Proved / enforced**

| Claim | Where |
|-------|-------|
| Directed-rounding lower bound on rho | `uuie/uuie_kernel.c` |
| Certified n_+ count under a Gershgorin residual margin (not machine-checked; open problem 6) | `uuie/uuie_kernel.c` |
| Type/domain/finite policy guards | `horn/horn_cert.pl` |
| RNE can undercut RTP on a quotient | `formal/fp_rounding_witness.smt2` (sat) |
| C=1 below Zolotarev and GSLW on reference params | docs (Alloy model not re-run 2026-11-15) |

**Not proved**

| Non-claim | Why |
|-----------|-----|
| Round-to-nearest ceiling is a sound upper bound on true Q | FE_TONEAREST does not guarantee that |
| Degree Q-hat admits a QSVT phase sequence | Prefactor C=1 is below known bounds |
| Hardware Circulant-QFT gate counts | C_U is an analytic sketch |
| Individual ordinates gamma_n from eigenmodes | Rank-trace only counts |
| Anything past bandwidth one | Form-factor control stops at `abs(alpha) = 1` |

---

## 6. Architecture

```text
synthesis model / Muse
  v
kg -q <kernel>.kg N        -> matrix_R.dat
uuie_kernel N target matrix_R.dat
  |  prints rank_trace_cert(N, TrDown, Hs2Up, RhoLb, Nplus, JacobiFrac, valid|reject).
  v
horn/horn_cert.pl
  |-- verified_weil_quantum_witness/4   (rank_trace_cert + policy budget)
  |-- qsvt_polylog_cert/4               (policy budget only)
  |-- verified_weil_smt_witness/4       (horn/smt_manifold_cert.pl; needs SMT cell facts)
```

---

## 7. Open problems

| # | Problem | Type |
|---|---------|------|
| 1 | Form factor for `abs(alpha) > 1` | analytic, external |
| 2 | Sound ceiling under floating point | numerical / formal |
| 3 | Proved constructive prefactor C >= 4/pi (ideally GSLW ~ 4) | analytic |
| 4 | Map positive eigenmodes of R to ordinates gamma_n | analytic / spectral |
| 5 | Calibrate c0(T) to explicit-formula diagonal | analytic + numerical |
| 6 | Machine-checked proof of UUie directed-rounding inequalities | formal verification |

---

## 8. How to run

```bash
# Classical certificate path
cc -std=c11 -O2 -frounding-math -ffp-contract=off \
   uuie/uuie_kernel.c -lm -o uuie/uuie_kernel
# Klong 20221212 from https://t3x.org/klong/ ; KLONGPATH must include its lib/ directory
kg -q klong/weil_horn.kg 128          # writes matrix_R.dat
./uuie/uuie_kernel 128 0.6725 matrix_R.dat

# Formal witness
z3 formal/fp_rounding_witness.smt2

# Policy predicate and tests
swipl -q -s horn/horn_cert.pl \
  -g "qsvt_polylog_cert(1000000,2.70,0.05,Q), writeln(Q), halt"
swipl -q -s horn/horn_cert.pl -s horn/test_qsvt_polylog.pl -g "run_tests, halt"
```

### Results of these commands on 2026-11-15

| Command | Result |
|---------|--------|
| `kg -q klong/weil_horn.kg 128` (Klong 20221212) | exit 0, 16384 values written, about 2.5 min |
| `uuie_kernel 128 0.6725 matrix_R.dat` | `valid`, exit 0: rho_lb = 0.17079, n_+ = 128/128 |
| `kg -q klong/weil_horn.kg 64` + `uuie_kernel 64 ...` | `valid`, exit 0: rho_lb = 0.29648, n_+ = 64/64 |
| `z3 formal/fp_rounding_witness.smt2` (Z3 5.4.1) | `sat` |
| `qsvt_polylog_cert(1000000,2.70,0.05,Q)` | `Q = 747` |
| plunit suite (SWI-Prolog 9.2.9) | 20/20 pass |

The Klong matrix clears the 0.6725 target only through the Jacobi count. Its rho_lb is well below 0.6725. n_+/N = 1 holds because the sinc Gram part is positive semidefinite and the contact term adds c0 = 1 times the identity, so this is not evidence about zeta zeros by itself.

---

## 9. Verification philosophy

| Layer | Content | Status |
|-------|---------|--------|
| A | Analytic theorems (Alpoge-Furman, BGSTB) | external; consumed, not re-proved |
| B | Discrete numerical certificates (directed rho, Jacobi n_+) | **operational** |
| C | Complexity envelopes and quantum sketches | instrumented; **holes named** |

A claim of "polylog quantum projection of simple zeta zeros" needs Layer A beyond bandwidth one, a closed Layer C (sound ceiling + proved prefactor + real block-encoding), and a bridge from eigenmodes to ordinates. This repo does not make that claim.

---

## 10. Status

- Classical discrete certificates (Klong + UUie + Horn): **run end to end on 2026-11-15**
- Alloy models, BQN probe, GitHub workflow: **not run** in the 2026-11-15 pass
- Quantum polylog projection of simple zeros: **not claimed**; gaps named and measured

## License

Research code. No warranty. Keep directed-rounding and Jacobi margins if you reuse certificates.

Primary analytic source: Alpoge and Furman, arXiv:2608.13637 (2026).
