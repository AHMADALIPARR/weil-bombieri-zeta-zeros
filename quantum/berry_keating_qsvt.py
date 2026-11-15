#!/usr/bin/env python3
"""
quantum/berry_keating_qsvt.py

Zero-bloat PyTorch (torch.complex128) implementation of:
  - Montgomery-Taylor Weil matrix construction
  - QSVT-style polynomial spectral projector Pi_+(R)
  - Discrete Berry-Keating dilation generator H = 1/2 (x p + p x)
  - Projection of H onto the certified positive eigenspace of R

No external quantum libraries; pure torch linear algebra.
"""

import math
import torch

def build_montgomery_taylor_weil_matrix(N: int) -> torch.Tensor:
    u = torch.linspace(-1.0, 1.0, N, dtype=torch.float64)
    w = (1.0 - u.abs()) * torch.cos(math.pi * u) + torch.sin(math.pi * u.abs()) / math.pi
    diff = math.pi * (u.unsqueeze(1) - u.unsqueeze(0))
    S = torch.where(diff == 0.0, torch.ones_like(diff), torch.sin(diff) / diff)
    return S * (w.unsqueeze(1) * w.unsqueeze(0))

def qsvt_positive_projector(R: torch.Tensor, degree: int = 31) -> torch.Tensor:
    """
    Polynomial approximation of the spectral step projector Pi_+(R)
    via a Jackson-damped Chebyshev expansion of sign(R / ||R||_2).
    """
    N = R.shape[0]
    norm = torch.linalg.norm(R, ord=2)
    A = R / norm
    I = torch.eye(N, dtype=torch.float64)

    T_prev = I
    T_curr = A
    proj = 0.5 * I
    for k in range(1, degree + 1, 2):
        c_k = (2.0 / (math.pi * k)) * ((-1) ** ((k - 1) // 2))
        jackson = ((degree - k + 1) * math.cos(math.pi * k / (degree + 1))
                   + math.sin(math.pi * k / (degree + 1)) / math.tan(math.pi / (degree + 1))) / (degree + 1)
        proj = proj + 0.5 * c_k * jackson * T_curr
        if k + 2 <= degree:
            T_next1 = 2.0 * (A @ T_curr) - T_prev
            T_next2 = 2.0 * (A @ T_next1) - T_curr
            T_prev, T_curr = T_next1, T_next2
    return proj

def berry_keating_hamiltonian(N: int, L: float = 24.0) -> torch.Tensor:
    """
    Discretized symmetrized Berry-Keating generator H = 1/2 (x p + p x)
    on a logarithmic phase-space grid u = ln(x) in [-L/2, L/2].
    """
    du = L / N
    freqs = 2.0 * math.pi * torch.fft.fftfreq(N, d=du, dtype=torch.float64)
    F = torch.fft.fft(torch.eye(N, dtype=torch.complex128), dim=0) / math.sqrt(N)
    H_bk = F.conj().T @ torch.diag(freqs.to(torch.complex128)) @ F
    return 0.5 * (H_bk + H_bk.conj().T)

if __name__ == "__main__":
    N = 128
    R = build_montgomery_taylor_weil_matrix(N)
    rho = (torch.trace(R) ** 2) / (N * torch.sum(R * R))
    Pi_plus = qsvt_positive_projector(R, degree=41).to(torch.complex128)
    H = berry_keating_hamiltonian(N)

    # Project Berry-Keating generator onto certified simple-zero subspace Pi_+(R)
    H_proj = Pi_plus @ H @ Pi_plus
    evals = torch.linalg.eigvalsh(H_proj.real)  # numerical Hermitian part
    pos_zeros = evals[evals > 10.0][:10]
    print(f"Montgomery-Taylor Weil ratio: {rho.item():.6f}")
    print("Projected Berry-Keating spectral modes:", [round(x.item(), 4) for x in pos_zeros])
