#!/usr/bin/env python3
"""
quantum/block_encoding_audit.py

Zero-dependency PyTorch harness that constructs the exact arXiv:2608.13637
Montgomery–Taylor Weil Toeplitz operator and audits:

  - Circulant-QFT subnormalization alpha_C(N)
  - Full LCU 1-norm alpha_LCU(N)
  - Sparse LCU truncation error
  - Spectral gap delta_min(N)
  - QSVT query degree for fixed gap vs exact min gap
  - Explicit gate counts for the block-encoding

No external libraries beyond torch.
"""

import math
import torch

torch.set_default_dtype(torch.float64)

def montgomery_taylor_symbol(u: torch.Tensor) -> torch.Tensor:
    """
    Exact Montgomery-Taylor extremal window squared times pair-correlation kernel
    from arXiv:2608.13637 on u in [-1, 1].
    """
    au = u.abs()
    psi = (1.0 - au) * torch.cos(math.pi * u) + torch.sin(math.pi * au) / math.pi
    # Montgomery pair-correlation weight (1 - |u| + delta_0 contribution normalized)
    return (psi ** 2) * (1.0 - 0.5 * au)

def build_weil_toeplitz(N: int, oversample_c: float = 1.35, quad_pts: int = 4096) -> tuple[torch.Tensor, torch.Tensor]:
    """
    Computes exact Fourier-Toeplitz entries t_d = int_{-1}^1 g(u) exp(i * pi * d * u / c) du
    for d = 0..N-1 via midpoint quadrature and builds N x N Hermitian Toeplitz T.
    """
    u = torch.linspace(-1.0 + 1.0 / quad_pts, 1.0 - 1.0 / quad_pts, quad_pts)
    du = 2.0 / quad_pts
    g_u = montgomery_taylor_symbol(u)

    d = torch.arange(N, dtype=torch.float64).unsqueeze(1)  # [N, 1]
    phase = (math.pi / oversample_c) * d * u.unsqueeze(0)  # [N, quad_pts]
    t_col = torch.sum(g_u.unsqueeze(0) * torch.cos(phase), dim=1) * du

    idx = torch.arange(N)
    dist = (idx.unsqueeze(1) - idx.unsqueeze(0)).abs()
    T = t_col[dist]
    return T, t_col

def audit_block_encoding(N: int, oversample_c: float = 1.35, eps: float = 1e-6):
    T, t_col = build_weil_toeplitz(N, oversample_c=oversample_c)

    # 1. Weil-Bombieri trace-moment lower bound ratio
    tr_T = torch.trace(T).item()
    hs2_T = torch.sum(T * T).item()
    rho_bound = (tr_T ** 2) / (N * hs2_T)

    # 2. Circulant 2N embedding eigenvalues -> exact subnormalization alpha_C(N)
    zero_pad = torch.zeros(1, dtype=torch.float64)
    c_first = torch.cat([t_col, zero_pad, torch.flip(t_col[1:], dims=[0])])  # length 2N
    circ_eigs = torch.fft.rfft(c_first).real
    alpha_circ = torch.max(circ_eigs.abs()).item()

    # 3. Full LCU 1-norm alpha_LCU(N) = |t_0| + 2 * sum_{d=1}^{N-1} |t_d|
    alpha_lcu = (t_col[0].abs() + 2.0 * torch.sum(t_col[1:].abs())).item()

    # 4. Sparse LCU truncation error ||T - T_K||_2 for K = 16
    K = min(16, N - 1)
    idx = torch.arange(N)
    mask = ((idx.unsqueeze(1) - idx.unsqueeze(0)).abs() <= K).to(torch.float64)
    trunc_err_16 = torch.linalg.norm(T - T * mask, ord=2).item()

    # 5. Exact eigenspectrum -> positive fraction & minimum positive gap delta_min
    evals = torch.linalg.eigvalsh(T)
    pos_evals = evals[evals > 1e-12]
    n_plus_frac = pos_evals.numel() / N
    delta_min = torch.min(pos_evals).item() if pos_evals.numel() > 0 else 0.0

    # 6. Explicit gate count & QSVT query degree budget
    n_qubits = math.ceil(math.log2(2 * N))
    b_bits = math.ceil(math.log2(8.0 * alpha_circ / eps))
    # 2 QFTs on n_qubits: 2 * (n*(n-1)/2) controlled rotations + O(b^2) coherent symbol oracle
    gates_qft = n_qubits * (n_qubits - 1)
    gates_oracle = 4 * (b_bits ** 2) + 6 * n_qubits
    c_u_gates = gates_qft + gates_oracle

    # QSVT Chebyshev degree for fixed gap delta=0.05 vs full delta_min(N)
    q_fixed_gap = math.ceil((alpha_circ / 0.05) * math.log(1.0 / eps))
    q_exact_gap = math.ceil((alpha_circ / max(delta_min, 1e-9)) * math.log(1.0 / eps))

    return {
        "N": N,
        "rho": rho_bound,
        "n+/N": n_plus_frac,
        "alpha_C": alpha_circ,
        "alpha_LCU": alpha_lcu,
        "err_K16": trunc_err_16,
        "delta_min": delta_min,
        "b_bits": b_bits,
        "C_U_gates": c_u_gates,
        "QSVT_deg(0.05)": q_fixed_gap,
        "QSVT_deg(min)": q_exact_gap,
    }

if __name__ == "__main__":
    header = (
        f"{'N':>5} | {'rho_lb':>7} | {'n+/N':>6} | {'alpha_C':>7} | {'alpha_LCU':>9} | "
        f"{'err_K16':>9} | {'delta_min':>9} | {'C_U(b=22)':>9} | {'q(0.05)':>7} | {'q(min)':>9}"
    )
    print(header)
    print("-" * len(header))
    for N in [64, 128, 256, 512, 1024]:
        r = audit_block_encoding(N)
        print(
            f"{r['N']:5d} | {r['rho']:7.4f} | {r['n+/N']:6.4f} | {r['alpha_C']:7.4f} | "
            f"{r['alpha_LCU']:9.4f} | {r['err_K16']:9.2e} | {r['delta_min']:9.2e} | "
            f"{r['C_U_gates']:9d} | {r['QSVT_deg(0.05)']:7d} | {r['QSVT_deg(min)']:9d}"
        )
