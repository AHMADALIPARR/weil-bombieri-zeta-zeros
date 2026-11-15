#!/usr/bin/env python3
"""
quantum/sparse_lcu.py

Sparse LCU truncation for the Weil–Bombieri Toeplitz operator.

Methods
-------
1. Bandwidth truncation  — keep lags |d| <= K
2. Coefficient threshold — keep lags with |t_d| >= tau

Reports
-------
- spectral error ||T - T_sparse||_2 and Frobenius error
- truncated LCU 1-norm alpha_LCU_K
- nnz fraction
- empirical coefficient decay

Circulant-QFT remains the preferred full-accuracy block-encoding;
this module is the sparse baseline and a classical sparsifier for
UUie / Jacobi when memory is tight.

Usage
-----
  python quantum/sparse_lcu.py
  python quantum/sparse_lcu.py --N 256 --K 16
  python quantum/sparse_lcu.py --N 256 --tau 1e-3
"""

from __future__ import annotations

import argparse
import math
from dataclasses import dataclass

import torch

torch.set_default_dtype(torch.float64)


def montgomery_taylor_symbol(u: torch.Tensor) -> torch.Tensor:
    au = u.abs()
    psi = (1.0 - au) * torch.cos(math.pi * u) + torch.sin(math.pi * au) / math.pi
    return (psi ** 2) * (1.0 - 0.5 * au)


def toeplitz_first_column(
    N: int,
    oversample_c: float = 1.35,
    quad_pts: int = 8192,
    c0: float = 0.0,
) -> torch.Tensor:
    """Fourier coefficients t_0..t_{N-1} of the continuous symbol (+ optional contact)."""
    u = torch.linspace(-1.0 + 1.0 / quad_pts, 1.0 - 1.0 / quad_pts, quad_pts)
    du = 2.0 / quad_pts
    g_u = montgomery_taylor_symbol(u)
    d = torch.arange(N, dtype=torch.float64).unsqueeze(1)
    phase = (math.pi / oversample_c) * d * u.unsqueeze(0)
    t = torch.sum(g_u.unsqueeze(0) * torch.cos(phase), dim=1) * du
    if c0 != 0.0:
        t = t.clone()
        t[0] = t[0] + c0
    return t


def build_toeplitz(t_col: torch.Tensor) -> torch.Tensor:
    N = t_col.numel()
    idx = torch.arange(N)
    dist = (idx.unsqueeze(1) - idx.unsqueeze(0)).abs()
    return t_col[dist]


@dataclass(frozen=True)
class TruncationReport:
    method: str
    N: int
    param: float  # K or tau
    err_2: float
    err_F: float
    nnz_frac: float
    alpha_full: float
    alpha_sparse: float
    n_terms: int  # number of kept diagonals (one-sided, including 0)


def alpha_lcu(t_col: torch.Tensor) -> float:
    return float(t_col[0].abs() + 2.0 * t_col[1:].abs().sum())


def truncate_bandwidth(T: torch.Tensor, t_col: torch.Tensor, K: int) -> tuple[torch.Tensor, TruncationReport]:
    """Keep lags |d| <= K."""
    N = T.shape[0]
    K = max(0, min(K, N - 1))
    idx = torch.arange(N)
    dist = (idx.unsqueeze(1) - idx.unsqueeze(0)).abs()
    mask = (dist <= K).to(torch.float64)
    Tk = T * mask
    err_2 = float(torch.linalg.norm(T - Tk, ord=2))
    err_F = float(torch.linalg.norm(T - Tk, ord="fro"))
    nnz = float(mask.sum().item()) / (N * N)
    a_full = alpha_lcu(t_col)
    a_sparse = float(t_col[0].abs() + 2.0 * t_col[1 : K + 1].abs().sum()) if K >= 1 else float(t_col[0].abs())
    return Tk, TruncationReport(
        method="bandwidth",
        N=N,
        param=float(K),
        err_2=err_2,
        err_F=err_F,
        nnz_frac=nnz,
        alpha_full=a_full,
        alpha_sparse=a_sparse,
        n_terms=K + 1,
    )


def truncate_threshold(
    T: torch.Tensor, t_col: torch.Tensor, tau: float
) -> tuple[torch.Tensor, TruncationReport]:
    """Keep lags with |t_d| >= tau (and always keep d=0)."""
    N = T.shape[0]
    keep = t_col.abs() >= tau
    keep[0] = True
    idx = torch.arange(N)
    dist = (idx.unsqueeze(1) - idx.unsqueeze(0)).abs()
    # mask[i,j] = 1 iff |i-j| is a kept lag
    mask = keep[dist].to(torch.float64)
    Tk = T * mask
    err_2 = float(torch.linalg.norm(T - Tk, ord=2))
    err_F = float(torch.linalg.norm(T - Tk, ord="fro"))
    nnz = float(mask.sum().item()) / (N * N)
    a_full = alpha_lcu(t_col)
    # one-sided kept lags
    kept_lags = torch.where(keep)[0]
    a_sparse = float(t_col[0].abs() + 2.0 * t_col[kept_lags[kept_lags > 0]].abs().sum())
    return Tk, TruncationReport(
        method="threshold",
        N=N,
        param=float(tau),
        err_2=err_2,
        err_F=err_F,
        nnz_frac=nnz,
        alpha_full=a_full,
        alpha_sparse=a_sparse,
        n_terms=int(keep.sum().item()),
    )


def coefficient_decay(t_col: torch.Tensor, d_min: int = 2) -> float:
    """Empirical power b in |t_d| ~ d^{-b} for d >= d_min."""
    N = t_col.numel()
    if N <= d_min + 1:
        return float("nan")
    ds = torch.arange(d_min, N, dtype=torch.float64)
    logt = torch.log(t_col[d_min:].abs().clamp_min(1e-30))
    logd = torch.log(ds)
    var = ((logd - logd.mean()) ** 2).sum()
    if var == 0:
        return float("nan")
    b = -((logd - logd.mean()) * (logt - logt.mean())).sum() / var
    return float(b)


def sweep_bandwidth(N: int, Ks: list[int], c0: float = 0.0) -> list[TruncationReport]:
    t = toeplitz_first_column(N, c0=c0)
    T = build_toeplitz(t)
    out = []
    for K in Ks:
        _, rep = truncate_bandwidth(T, t, K)
        out.append(rep)
    return out


def main() -> None:
    p = argparse.ArgumentParser(description="Sparse LCU truncation for Weil–Bombieri T")
    p.add_argument("--N", type=int, default=256)
    p.add_argument("--K", type=int, default=None, help="bandwidth truncation")
    p.add_argument("--tau", type=float, default=None, help="coefficient threshold")
    p.add_argument("--c0", type=float, default=0.0, help="diagonal contact mass")
    p.add_argument("--sweep", action="store_true", help="print K-sweep table")
    args = p.parse_args()

    t = toeplitz_first_column(args.N, c0=args.c0)
    T = build_toeplitz(t)
    b = coefficient_decay(t)
    print(f"N={args.N}  c0={args.c0}  alpha_LCU={alpha_lcu(t):.6f}  decay_b≈{b:.3f}")

    if args.sweep or (args.K is None and args.tau is None):
        Ks = [1, 2, 4, 8, 12, 16, 24, 32, 48, 64, 96, 128]
        Ks = [K for K in Ks if K < args.N]
        print(f"{'K':>4} {'err_2':>12} {'err_F':>12} {'nnz':>8} {'alpha_K':>10} {'terms':>6}")
        for rep in sweep_bandwidth(args.N, Ks, c0=args.c0):
            print(
                f"{int(rep.param):4d} {rep.err_2:12.4e} {rep.err_F:12.4e} "
                f"{rep.nnz_frac:8.4f} {rep.alpha_sparse:10.6f} {rep.n_terms:6d}"
            )

    if args.K is not None:
        Tk, rep = truncate_bandwidth(T, t, args.K)
        print(
            f"bandwidth K={args.K}: err_2={rep.err_2:.4e} err_F={rep.err_F:.4e} "
            f"nnz={rep.nnz_frac:.4f} alpha_K={rep.alpha_sparse:.6f}"
        )

    if args.tau is not None:
        Tk, rep = truncate_threshold(T, t, args.tau)
        print(
            f"threshold tau={args.tau}: err_2={rep.err_2:.4e} err_F={rep.err_F:.4e} "
            f"nnz={rep.nnz_frac:.4f} alpha_K={rep.alpha_sparse:.6f} terms={rep.n_terms}"
        )


if __name__ == "__main__":
    main()
