# What `qsvt_polylog_cert/4` Actually Proves

## Scope of the predicate

`qsvt_polylog_cert/4` enforces **runtime type/domain discipline** and a **deterministic arithmetic policy filter**. It is **not** a formal mathematical proof of a valid QSVT query upper bound.

Two unverified gaps sit inside `qsvt_build_report/4`:

1. **IEEE-754 round-to-nearest arithmetic before `ceiling/1`**
2. **Unproved prefactor $C = 1$** in the query formula

---

## 1. Floating-point rounding breaks upper-bound soundness

### Exact semantics computed by the code

Given valid inputs $(\alpha_C, g, \varepsilon)$, the predicate evaluates

$$
\widehat{Q} = \bigl\lceil \operatorname{fl}\bigl(\operatorname{fl}(\alpha_C / g) \cdot \operatorname{fl}(-\ln\varepsilon)\bigr) \bigr\rceil
$$

where $\operatorname{fl}(\cdot)$ denotes IEEE-754 binary64 round-to-nearest-even (`FE_TONEAREST`), **not** directed upward rounding or exact rational interval arithmetic.

For $\widehat{Q}$ to be a sound upper bound on

$$
Q^* = \Bigl\lceil \frac{\alpha_C}{g}\ln\bigl(\tfrac1\varepsilon\bigr) \Bigr\rceil,
$$

the implementation would have to guarantee $\widehat{x} \ge x$ prior to `ceiling/1`. Round-to-nearest only guarantees $|\widehat{x}-x| \le c\cdot u\cdot|x|$ with $u=2^{-53}$.

### Constructive binary64 counterexample

Choose exact binary64 values inside the policy domain:

- $\alpha_C = 0.5$, $g = 0.25$ (both bit-for-bit exact)
- Exact real quotient $\alpha_C/g = 2 + \frac{2^{-52}}{1+2^{-52}} > 2$
- On $[2,4)$, $\operatorname{ulp}(2)=2^{-51}$. The midpoint is $2+2^{-52}$. Round-to-nearest therefore rounds **downward** to $2.0$, discarding $\approx 2.22\times 10^{-16}$.

Because $\lceil x\rceil$ is discontinuous at every integer, any product whose exact value lies in $(M, M+O(u\cdot M))$ while the rounded product satisfies $\widehat{x}\le M$ yields

$$
\texttt{QueryEnvelope} = M < \lceil x\rceil = Q^*.
$$

When $M = \texttt{QueryCap}$ (e.g. 1024), the policy check `QueryEnvelope =< QueryCap` **succeeds on an instance whose true ceiling exceeds the cap**.

### What would close the gap

- Exact rational enclosure (`clp(q)` / `rdiv` with a certified rational lower bound on $-\ln\varepsilon$), **or**
- Explicit directed upward rounding (`FE_UPWARD` / `set_prolog_flag(float_rounding, toward_positive)`) on every intermediate before `ceiling/1`.

---

## 2. The unproved polynomial-degree constant $C=1$ is false for QSVT

### Hidden assumption

```prolog
RawQueries is InverseGap * LogInverseError   % C = 1 hardcoded
```

assumes that for every $\delta\in(0,1]$ and $\varepsilon\in(0,1)$ there exists an **odd** real polynomial $P$ of degree

$$
d \le d_{\text{Prolog}} = \frac{\alpha_C}{g}\ln\frac1\varepsilon
$$

satisfying the mandatory QSVT conditions (Gilyén et al., STOC 2019, Thm 17 & Lem 25):

1. $|P(x)|\le 1$ for all $x\in[-1,1]$
2. $|P(x)-\operatorname{sgn}(x)|\le\varepsilon$ for all $|x|\in[\delta,1]$

### Why $d_{\text{Prolog}}$ violates existence bounds

- **No witness in the Horn theory.** Nothing constructs $P$, verifies the unit-bound, checks spectral accuracy, or proves a degree theorem in $(\delta,\varepsilon)$.
- **Chebyshev / Zolotarev lower bound.** Any odd $P$ of degree $d$ obeying the two conditions yields an even residual $Q(y)=1-P(\sqrt y)^2$ to which Chebyshev’s extremal inequality applies on $[\delta^2,1]$. The sharp asymptotic constant is the Eremenko–Yuditskii / Zolotarev value

  $$
  C_{\mathrm{opt}} = \frac4\pi \approx 1.27324.
  $$

- **Constructive GSLW bound.** The explicit erf-Chebyshev truncation used in practice requires a still larger prefactor $\approx 4$.

### Numbers on the reference unit-test inputs

$\alpha_C=2.70$, $g=0.05$ $\Rightarrow$ $\delta=1/54$, $\varepsilon=10^{-6}$:

| Bound | Prefactor $C$ | Degree / queries | vs QueryCap = 1024 |
|-------|---------------|------------------|--------------------|
| `qsvt_build_report/4` ($C=1$, unproved) | 1.0000 | **747** | Passes |
| Sharp Zolotarev / Eremenko–Yuditskii lower bound | $4/\pi\approx 1.2732$ | **950** | Exceeds 747 by +203 |
| Constructive GSLW erf-Chebyshev | $\approx 4$ | **2985** | Exceeds both 747 and 1024 |

Because $d_{\min}(1/54,10^{-6})\approx 950 > 747$, **no odd polynomial of degree 747 exists** that meets the QSVT conditions for these parameters.

---

## Summary — certified vs. outside the guarantee

| Status | Property |
|--------|----------|
| **Certified by the code** | Input instantiation/type safety; domain positivity ($0 < g \le \alpha_C$); non-finiteness / underflow detection; deterministic policy filtering ($\alpha_C\le 3.0$, $g\ge 0.05$, $\widehat Q\le 1024$); exception-context propagation |
| **Outside the mathematical guarantee** | Exact ceiling soundness under `FE_TONEAREST`; existence of an actual QSVT phase-angle sequence of degree `QueryEnvelope` (requires a proved constructive prefactor $C_{\mathrm{cert}}$ plus a verified QSP/QSVT phase certificate) |

---

## Counterclaims (Alloy model)

See `formal/qsvt_counterclaims.als` for a machine-checkable encoding of the two gaps:

1. Round-to-nearest can produce a reported envelope strictly below the true mathematical ceiling.
2. The hardcoded prefactor $C=1$ lies strictly below both the Zolotarev lower bound and the constructive GSLW upper bound, so the reported degree is not a sound QSVT query count.
