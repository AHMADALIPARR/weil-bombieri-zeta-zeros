# Measured benchmarks

All tables produced by `quantum/block_encoding_audit.py` and the same Toeplitz generator used in Klong, IEEE-754 binary64, November 2026.

Companion to the main [README](../README.md).

---

## 1. Continuous Montgomery–Taylor symbol only (no contact mass)

Cauchy–Schwarz is loose when eigenvalues decay. Analytic $\rho$ stalls near $0.29$; Jacobi still sees a large positive fraction.

| $N$ | $\rho_{\mathrm{lb}}$ | $n_+/N$ | $\delta_{\min}$ | $\alpha_C$ | $\alpha_{\mathrm{LCU}}$ | $C_U$ | $q(0.05)$ | $q(\delta_{\min})$ |
|------:|------------------------:|----------:|------------------:|-------------:|--------------------------:|-------:|-----------:|---------------------:|
| 32 | 0.2982 | 0.9375 | $5.05\times 10^{-12}$ | 2.6882 | 2.6882 | 2566 | 743 | $\sim 3.71\times 10^{10}$ |
| 64 | 0.2932 | 0.8438 | $6.91\times 10^{-12}$ | 2.6942 | 2.6942 | 2584 | 745 | $\sim 3.72\times 10^{10}$ |
| 128 | 0.2908 | 0.7969 | $1.68\times 10^{-12}$ | 2.6971 | 2.6971 | 2604 | 746 | $\sim 3.73\times 10^{10}$ |
| 256 | 0.2895 | 0.7656 | $2.54\times 10^{-12}$ | 2.6985 | 2.6985 | 2626 | 746 | $\sim 3.73\times 10^{10}$ |
| 512 | 0.2889 | 0.7520 | $1.07\times 10^{-12}$ | 2.6993 | 2.6993 | 2650 | 746 | $\sim 3.73\times 10^{10}$ |
| 1024 | 0.2887 | 0.7432 | $1.97\times 10^{-12}$ | 2.6996 | 2.6996 | 2676 | 746 | $\sim 3.73\times 10^{10}$ |

---

## 2. Same symbol + Montgomery $\delta(\alpha)$ contact $c_0 I$ ($c_0=1$)

| $N$ | $\rho_{\mathrm{lb}}$ | $n_+/N$ | $\delta_{\min}$ | $\alpha_C$ | $\alpha_{\mathrm{LCU}}$ | $C_U$ | $q(0.05)$ | $q(\delta_{\min})$ | $q_{\mathrm{Zolotarev}}$ | $q_{\mathrm{GSLW}}$ |
|------:|------------------------:|----------:|------------------:|-------------:|--------------------------:|-------:|-----------:|-------------------:|-------------------------:|--------------------:|
| 32 | 0.7788 | 1.0000 | 1.00 | 3.6882 | 3.6882 | 2566 | 1020 | 51 | 1298 | 4077 |
| 64 | 0.7746 | 1.0000 | 1.00 | 3.6942 | 3.6942 | 2584 | 1021 | 52 | 1300 | 4083 |
| 128 | 0.7726 | 1.0000 | 1.00 | 3.6971 | 3.6971 | 2604 | 1022 | 52 | 1301 | 4087 |
| 256 | 0.7715 | 1.0000 | 1.00 | 3.6985 | 3.6985 | 2626 | 1022 | 52 | 1302 | 4088 |
| 512 | 0.7710 | 1.0000 | 1.00 | 3.6993 | 3.6993 | 2650 | 1023 | 52 | 1302 | 4089 |
| 1024 | 0.7708 | 1.0000 | 1.00 | 3.6996 | 3.6996 | 2676 | 1023 | 52 | 1302 | 4089 |

$q_{\mathrm{Zolotarev}}$ uses $C=4/\pi$; $q_{\mathrm{GSLW}}$ uses $C=4$; both at fixed gap $0.05$, $\varepsilon=10^{-6}$.

---

## 3. Contact effect at $N=1024$

| Quantity | No contact | Contact $c_0=1$ | Change |
|----------|------------|-----------------|--------|
| $\rho_{\mathrm{lb}}$ | 0.2887 | 0.7708 | $\times 2.67$ |
| $n_+/N$ | 0.7432 | 1.0000 | $+0.2568$ |
| $\delta_{\min}$ | $1.97\times 10^{-12}$ | $1.00$ | $\times\sim 5\times 10^{11}$ |
| $\alpha_C$ | 2.6996 | 3.6996 | $+1$ |
| $q(\delta_{\min})$ | $\sim 3.73\times 10^{10}$ | 52 | $\times\sim 7\times 10^{-10}$ |

---

## 4. Sparse LCU truncation $\|T-T_K\|_2$ at $K=16$

| $N$ | No contact | Contact |
|------:|-----------:|--------:|
| 32 | $4.14\times 10^{-3}$ | $4.14\times 10^{-3}$ |
| 64 | $9.35\times 10^{-3}$ | $9.35\times 10^{-3}$ |
| 128 | $1.47\times 10^{-2}$ | $1.47\times 10^{-2}$ |
| 256 | $1.85\times 10^{-2}$ | $1.85\times 10^{-2}$ |
| 512 | $2.06\times 10^{-2}$ | $2.06\times 10^{-2}$ |
| 1024 | $2.18\times 10^{-2}$ | $2.18\times 10^{-2}$ |

---

## 5. Circulant-QFT gate breakdown (contact, $\varepsilon=10^{-6}$)

| $N$ | $n=\lceil\log_2(2N)\rceil$ | $b$ bits | QFT gates | Oracle gates | $C_U$ total |
|------:|---------------------------:|---------:|----------:|-------------:|------------:|
| 64 | 7 | 25 | 42 | 2542 | 2584 |
| 128 | 8 | 25 | 56 | 2548 | 2604 |
| 256 | 9 | 25 | 72 | 2554 | 2626 |
| 512 | 10 | 25 | 90 | 2560 | 2650 |
| 1024 | 11 | 25 | 110 | 2566 | 2676 |

---

## 6. $\alpha_C = \alpha_{\mathrm{LCU}}$ identity

| $N$ | No contact $\alpha_C$ | No contact $\alpha_{\mathrm{LCU}}$ | Contact $\alpha_C$ | Contact $\alpha_{\mathrm{LCU}}$ |
|------:|----------------------:|----------------------------------:|-------------------:|-------------------------------:|
| 64 | 2.6942 | 2.6942 | 3.6942 | 3.6942 |
| 128 | 2.6971 | 2.6971 | 3.6971 | 3.6971 |
| 256 | 2.6985 | 2.6985 | 3.6985 | 3.6985 |
| 512 | 2.6993 | 2.6993 | 3.6993 | 3.6993 |
| 1024 | 2.6996 | 2.6996 | 3.6996 | 3.6996 |

Non-negative Fourier coefficients $\Rightarrow$ peak circulant eigenvalue equals full $\ell_1$ LCU norm.

---

## 7. Degree landscape at gap $g=0.05$, $\varepsilon=10^{-6}$

| $\alpha_C$ | $C=1$ (policy) | $C=4/\pi$ (Zolotarev) | $C=4$ (GSLW) | Under QueryCap 1024? |
|-----------:|-----------------:|----------------------:|-------------:|----------------------|
| 1.0 | 277 | 352 | 1106 | $C=1$ only |
| 1.5 | 415 | 528 | 1658 | $C=1$ only |
| 2.0 | 553 | 704 | 2211 | $C=1$ only |
| 2.7 | 747 | 950 | 2985 | $C=1$ only |
| 3.0 | 829 | 1056 | 3316 | $C=1$ only; Zolotarev already $>1024$ |

---

## 8. Policy predicate results (SWI-Prolog 9.0.4)

| Query | Result | Reason |
|-------|--------|--------|
| `(1e6, 2.70, 0.05, Q)` | `Q = 747` | Inside envelope |
| `(1e6, 3.0, 0.05, Q)` | `Q = 829` | AlphaCap boundary |
| `(1e6, 3.01, 0.05, _)` | `false` | Above AlphaCap |
| `(1e6, 2.70, 0.049, _)` | `false` | Below GapFloor |
| `(1e6, 2.70, 0.05, 1024)` | `false` | Wrong pre-bound count |
| `(0, 2.70, 0.05, _)` | throws `domain_error(positive_integer, 0)` | Invalid domain |
| `(100, 0, 0.05, _)` | throws `domain_error(positive_normalization, 0)` | Invalid domain |
| `(100, 2.70, 0, _)` | throws `domain_error(positive_spectral_gap, 0)` | Invalid domain |

---

## 9. Degree formulae at reference $(\alpha_C,g,\varepsilon)=(2.70,0.05,10^{-6})$

| Formula | Prefactor $C$ | Degree | vs QueryCap 1024 |
|---------|----------------|--------|------------------|
| Prolog policy ($C=1$, unproved) | 1.0000 | **747** | passes |
| Zolotarev / Eremenko–Yuditskii LB | $4/\pi\approx 1.2732$ | **$\approx 950$** | exceeds 747 |
| Constructive GSLW | $\approx 4$ | **$\approx 2985$** | exceeds QueryCap |

---

## 10. IEEE-754 RNE vs RTP

```
$ z3 formal/fp_rounding_witness.smt2
sat
```

Concrete normal binary64 $\alpha,g$ with $\mathrm{RNE}(\alpha/g)<\mathrm{RTP}(\alpha/g)$.

---

## Reproduce

```bash
python3 quantum/block_encoding_audit.py
z3 formal/fp_rounding_witness.smt2
```
