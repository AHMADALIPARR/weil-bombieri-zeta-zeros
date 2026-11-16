# Weil-Bombieri Zeta Zeros

Discrete certificate tooling for the unconditional result on simple critical-line zeros of the Riemann zeta function via finite Hermitian compressions of the Weil explicit formula. The analytic theorem is from the cited paper; this code does not re-prove it.

Companion tables: [docs/BENCHMARKS.md](docs/BENCHMARKS.md).

Higher-order logic formalization of the rank-trace bound: [formal/hol/](formal/hol/).

Liquid Haskell refinement types (thousands of lines) replacing former Python: [liquid-haskell/](liquid-haskell/).

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
| `formal/hol/WeilBombieriRankTrace.thy` | Isabelle/HOL proof of the rank-trace bound | theory ready |
| `formal/hol/IsabelleAutomation.thy` | Sledgehammer / smt / simp automation examples | theory ready |
| `liquid-haskell/` | Thousands of lines of Liquid Haskell refinement types (Matrix, Certificate, DirectedRounding, QSVT) | modules present |
| `kernels/weil_probe.bqn` | CBQN trace-moment probe | not run in this pass (no CBQN installed) |
| `prompts/muse_system_contract.xml` | Output contract for a synthesis model | text |
| `.github/workflows/horn-sweep.yml` | Manual matrix job; builds the C kernel only | not run in this pass |
| `docs/qsvt-polylog-soundness.md` | What the policy does not prove | docs |
| `docs/hol.md` | HOL + LH overview | docs |

---

## 5. What is proved here vs not

**Proved / enforced**

| Claim | Where |
|-------|-------|
| Directed-rounding lower bound on rho | `uuie/uuie_kernel.c` |
| Certified n_+ count under a Gershgorin residual margin (not machine-checked; open problem 6) | `uuie/uuie_kernel.c` |
| Type/domain/finite policy guards | `horn/horn_cert.pl` |
| RNE can undercut RTP on a quotient | `formal/fp_rounding_witness.smt2` (sat) |
| Algebraic rank-trace inequality n₊ ≥ tr² / tr2 | `formal/hol/WeilBombieriRankTrace.thy` |
| Refinement-typed matrix, certificate, directed-rounding and QSVT invariants | `liquid-haskell/` |
| C=1 below Zolotarev and GSLW on reference params | docs (Alloy model not re-run 2026-11-15) |

**Not proved**

| Non-claim | Why |
|-----------|-----|
| Round-to-nearest ceiling is a sound upper bound on true Q | FE_TONEAREST does not guarantee that |
| Degree Q-hat admits a QSVT phase sequence | Prefactor C=1 is below known bounds |
| Hardware Circulant-QFT gate counts | C_U is an analytic sketch |
| Individual ordinates gamma_n from eigenmodes | Rank-trace only counts |
| Anything past bandwidth one | Form-factor control stops at `abs(alpha) = 1` |
| Full floating-point soundness of the directed-rounding bounds | open problem 6 |

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

formal/hol/WeilBombieriRankTrace.thy
  |-- machine-checked proof that the numeric ratio is a lower bound on n₊
formal/hol/IsabelleAutomation.thy
  |-- sledgehammer / smt examples

liquid-haskell/
  |-- thousands of lines of refinement types encoding the same invariants
```

---

## 9. Verification philosophy

| Layer | Content | Status |
|-------|---------|--------|
| A | Analytic theorems (Alpoge-Furman, BGSTB) | external; consumed, not re-proved |
| B | Discrete numerical certificates (directed rho, Jacobi n_+) | **operational** |
| C | Complexity envelopes and quantum sketches | instrumented; **holes named** |
| D | Higher-order logic (rank-trace bound) + automation | **Isabelle/HOL theories present** |
| E | Refinement types (Liquid Haskell) | **thousands of lines present** |

A claim of "polylog quantum projection of simple zeta zeros" needs Layer A beyond bandwidth one, a closed Layer C (sound ceiling + proved prefactor + real block-encoding), and a bridge from eigenmodes to ordinates. This repo does not make that claim.

---

## 10. Status

- Classical discrete certificates (Klong + UUie + Horn): **run end to end on 2026-11-15**
- Algebraic rank-trace inequality: **formalized in Isabelle/HOL**
- Isabelle automation layer: **present**
- Liquid Haskell refinement types: **thousands of lines added**
- Alloy models, BQN probe, GitHub workflow: **not run** in the 2026-11-15 pass
- Quantum polylog projection of simple zeros: **not claimed**; gaps named and measured

## License

Research code. No warranty. Keep directed-rounding and Jacobi margins if you reuse certificates.

Primary analytic source: Alpoge and Furman, arXiv:2608.13637 (2026).
