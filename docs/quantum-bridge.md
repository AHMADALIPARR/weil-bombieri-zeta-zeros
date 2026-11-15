# Quantum Bridge: Weil–Bombieri R → Berry–Keating → QSVT/QPE

This note records the exact correspondence between the finite-dimensional Hermitian matrix $R$ constructed by the Horn–Klong–UUie stack and the quantum Hamiltonian / spectral-projection framework that sits on top of arXiv:2608.13637.

## 1. What Alpöge–Furman Achieved

Unconditionally:

- $\ge 2/3$ (or $0.6725$ with the Montgomery–Taylor window) of nontrivial zeros are **simple and on the critical line**;
- $\ge 5/6$ (or $0.8362$) are **distinct**.

The argument never needs RH. It compresses Weil’s Hermitian form

$$
W(f,g)=\sum_\rho m_\rho\,\widehat f(\gamma_\rho)\overline{\widehat g(\gamma_\rho)}
$$

onto an $N\times N$ matrix $R$ built from modulated bandwidth-one windows, evaluates the unconditional Montgomery form factor (BGSTB), and applies the Bombieri rank-trace inequality

$$
n_+(R)\ge\frac{(\operatorname{tr} R)^2}{\operatorname{tr}(R^2)}.
$$

## 2. The Bandwidth-1 Ceiling

Because the form factor is known unconditionally only for $|\alpha|\le 1$, the Fourier support of the test functions is restricted to $[-1,1]$. This produces a hard Nyquist-style limit near $0.6725$. The method yields a lower bound on the *number* of positive eigenvalues, not a localisation of individual ordinates $\gamma_n$.

## 3. Mapping $R$ onto a Quantum Hamiltonian

Under the Hilbert–Pólya / Berry–Keating / Connes programme the critical-line zeros are identified with the eigenvalues of a self-adjoint dilation generator

$$
\hat H_{\mathrm{BK}}=\tfrac12(\hat x\hat p+\hat p\hat x)
$$

on a regularised phase space. Projecting $\hat H_{\mathrm{BK}}$ onto the finite-dimensional subspace spanned by the same Montgomery–Taylor basis that defines $R$ yields:

- $R$ itself is the Gram / density operator of that subspace;
- the matrix elements $\langle\psi_{\alpha_j}|\hat H_{\mathrm{BK}}|\psi_{\alpha_k}\rangle$ form a sparse Hermitian matrix whose spectrum approximates the ordinates $\gamma_k$ up to $O(1/\log T)$ boundary terms.

## 4. Polynomial-Time Spectral Projection (QSVT / QPE)

Classically, full diagonalisation of an $N\times N$ dense matrix is $O(N^3)$. On a quantum processor (or a state-vector simulator) one can:

1. **Block-encode** the structured Toeplitz–Hankel operator $R$ with $O(\mathrm{poly}\log N)$ gates (LCU + QFT);
2. Apply a low-degree polynomial approximation of the sign / Heaviside function via **Quantum Singular Value Transformation (QSVT)** to obtain the projector $\Pi_+(R)$ onto the positive eigenspace certified by $n_+(R)$;
3. Run **Quantum Phase Estimation** on the projected unitary $e^{-i\hat H_{\mathrm{BK}}t}$ to extract the eigenphases $\gamma_n$ in $\mathrm{poly}(\log N,1/\varepsilon)$ gate depth.

## 5. Concrete artefacts in this repository

| Path | Role |
|------|------|
| `uuie/uuie_kernel.c` | Directed-rounding analytic bound **and** certified Jacobi $n_+(R)$ with Gershgorin safety margin |
| `klong/weil_horn.kg` | Contains both the parametric window family **and** the exact Montgomery–Taylor extremizer `psi_mt` |
| `quantum/berry_keating_qsvt.py` | Pure PyTorch (`torch.complex128`) implementation of the QSVT projector and the discrete Berry–Keating generator; projects $H$ onto $\Pi_+(R)$ |

Together they close the loop from classical rank-trace certificates to a quantum-ready spectral projector sitting on exactly the same matrix $R$.
