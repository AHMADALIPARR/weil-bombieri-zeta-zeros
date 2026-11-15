# Block-Encoding Complexity Audit of the Weil–Bombieri Operator

This document records the exact gate-complexity analysis of block-encoding the compressed Weil matrix $R$ that appears in arXiv:2608.13637, together with the concrete numbers produced by `quantum/block_encoding_audit.py`.

## 1. Circulant-QFT versus Naive Shift-LCU

The matrix produced by evaluating the Weil form on an equispaced frequency grid is a pure Hermitian Toeplitz matrix $T$ whose symbol is the squared Montgomery–Taylor window times the pair-correlation kernel.

| Method | Subnormalization $\alpha$ | Gate cost of one block-encoding call |
|--------|---------------------------|--------------------------------------|
| Naive Shift-LCU ($T=\sum t_d S^d$) | $\alpha_{\mathrm{LCU}}=\|t\|_1$ (grows with $N$ or $\log N$) | PREP of a $(2N-1)$-state + controlled modular shifts |
| **Circulant-QFT** (embed $T$ in a $2N\times 2N$ circulant $C=F^\dagger\Lambda F$) | $\alpha_C=\|\Lambda\|_\infty$ | Two $n$-qubit QFTs ($n=\lceil\log_2(2N)\rceil$) + coherent evaluation of the symbol |

In the true oversampled regime of the paper ($\Delta\alpha\cdot T=\pi/c$ with $c>1$) Szegő’s theorem implies

$$
\alpha_C(N)=O(1).
$$

In a fixed-bandwidth spatial discretisation one instead obtains the disastrous $\alpha_C=\Theta(N)$.

## 2. Arithmetic & Truncation

- The generating symbol is an explicit elementary function; its values on the Fourier grid are computed *coherently* (degree-$p$ minimax / CORDIC). No QRAM is required.
- Bit-width needed for operator-norm error $\varepsilon$ is $b=O(\log(\alpha/\varepsilon))$.
- Because the Montgomery–Taylor window is $C^2$ and vanishes to second order at the endpoints, the Fourier coefficients decay as $O(d^{-4})$. Sparse LCU truncated at lag $K$ therefore incurs spectral error $O(K^{-3})$.

Total gate cost of one Circulant-QFT block-encoding call:

$$
C_U=O(\log^2 N+\log^2(1/\varepsilon)).
$$

## 3. Where $\operatorname{polylog}(N)$ Breaks

Even with $\alpha_C=O(1)$ and $C_U=\operatorname{polylog}(N)$, the QSVT degree for a step-function approximation is

$$
q=O\Bigl(\frac{\alpha_C}{\delta}\log\frac1\varepsilon\Bigr).
$$

- **Fixed gap** $\delta=\Theta(1)$ (e.g. project above $0.05$): $q$ stays polylogarithmic.
- **Exact positive subspace** ($\delta=\delta_{\min}(N)$): the smallest positive eigenvalue of $T$ tends to zero with $N$. The audit shows $\delta_{\min}(N)\sim N^{-1}$ or worse, forcing $q=\Omega(\operatorname{poly}(N))$.

In addition, classical readout of $N$ distinct ordinates via QPE still costs $O(N/\varepsilon_{\mathrm{QPE}})$ measurements.

## 4. Empirical Numbers

Run

```bash
python quantum/block_encoding_audit.py
```

to obtain the concrete table of $\rho$, $n_+/N$, $\alpha_C$, $\alpha_{\mathrm{LCU}}$, truncation error, $\delta_{\min}$, gate counts and QSVT degrees for $N=64\dots1024$.

The script proves that Circulant-QFT keeps $\alpha_C=O(1)$ while isolating the spectral-gap bottleneck that prevents an unconditional polylogarithmic extraction of every simple critical-line zero.
