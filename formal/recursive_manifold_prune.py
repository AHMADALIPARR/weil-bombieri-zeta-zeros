#!/usr/bin/env python3
"""
Zero-dependency SMT (QF_NRA) recursive manifold pruner for QSVT spectral envelopes.

Bisects the continuous (alpha_C, g) parameter manifold:
  - Prune  (unsat on feasibility): discard regions where even the best-case
            corner exceeds QueryCap = 1024.
  - Certify (unsat on negated invariant): entire cell satisfies the hardened
            constructive GSLW bound; emit a Horn ground fact.
  - Subdivide (sat on boundary): split widest axis and recurse.

Requires only the system `z3` binary on PATH.
Redirect stdout to horn/certified_manifold_cells.pl for Horn consumption.
"""
from __future__ import annotations

import subprocess
from dataclasses import dataclass

# Certified rational upper bound on ln(10^6) = 13.815510557964274...
LN_INV_EPS_NUM = 13815511
LN_INV_EPS_DEN = 1000000
PREFACTOR_GSLW = 4          # Constructive GSLW erf-Chebyshev constant
QUERY_CAP = 1024
ALPHA_CAP = 3.0
GAP_FLOOR = 0.05


@dataclass(frozen=True)
class Cell:
    depth: int
    a_lo: float
    a_hi: float
    g_lo: float
    g_hi: float


class Z3Pipe:
    def __init__(self) -> None:
        self.proc = subprocess.Popen(
            ["z3", "-in", "-smt2"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            text=True,
            bufsize=1,
        )
        self._send("(set-logic QF_NRA)")
        self._send("(declare-const a Real)")
        self._send("(declare-const g Real)")
        # Hardened QSVT constructive query bound:
        #   4 * (a / g) * ln(1/eps) <= 1024
        # Rearranged (g > 0): 4 * a * LN_NUM <= 1024 * g * LN_DEN
        self._send(
            f"(define-fun valid_qsvt ((a Real) (g Real)) Bool "
            f"(and (> g 0.0) (>= g {GAP_FLOOR}) (<= a {ALPHA_CAP}) (<= g a) "
            f"(<= (* {PREFACTOR_GSLW * LN_INV_EPS_NUM}.0 a) "
            f"(* {QUERY_CAP * LN_INV_EPS_DEN}.0 g))))"
        )

    def _send(self, cmd: str) -> None:
        assert self.proc.stdin is not None
        self.proc.stdin.write(cmd + "\n")
        self.proc.stdin.flush()

    def check_box(self, c: Cell, negated: bool) -> str:
        assert self.proc.stdout is not None
        self._send("(push 1)")
        self._send(
            f"(assert (and (>= a {c.a_lo:.12f}) (<= a {c.a_hi:.12f}) "
            f"(>= g {c.g_lo:.12f}) (<= g {c.g_hi:.12f})))"
        )
        if negated:
            self._send("(assert (not (valid_qsvt a g)))")
        else:
            self._send("(assert (valid_qsvt a g))")
        self._send("(check-sat)")
        res = self.proc.stdout.readline().strip()
        self._send("(pop 1)")
        return res

    def close(self) -> None:
        self._send("(exit)")
        self.proc.wait()


def prune_manifold(root: Cell, max_depth: int = 6) -> tuple[list[Cell], int]:
    z3 = Z3Pipe()
    certified: list[Cell] = []
    pruned_count = 0

    def recurse(c: Cell) -> None:
        nonlocal pruned_count
        # 1. If NO point in cell satisfies valid_qsvt -> UNSAT -> prune
        if z3.check_box(c, negated=False) == "unsat":
            pruned_count += 1
            return

        # 2. If NO point in cell violates valid_qsvt -> UNSAT -> certify
        if z3.check_box(c, negated=True) == "unsat":
            certified.append(c)
            return

        # 3. Boundary cell: bisect along widest relative span
        if c.depth >= max_depth:
            return

        if (c.a_hi - c.a_lo) >= (c.g_hi - c.g_lo):
            mid = 0.5 * (c.a_lo + c.a_hi)
            recurse(Cell(c.depth + 1, c.a_lo, mid, c.g_lo, c.g_hi))
            recurse(Cell(c.depth + 1, mid, c.a_hi, c.g_lo, c.g_hi))
        else:
            mid = 0.5 * (c.g_lo + c.g_hi)
            recurse(Cell(c.depth + 1, c.a_lo, c.a_hi, c.g_lo, mid))
            recurse(Cell(c.depth + 1, c.a_lo, c.a_hi, mid, c.g_hi))

    recurse(root)
    z3.close()
    return certified, pruned_count


if __name__ == "__main__":
    root = Cell(depth=0, a_lo=0.05, a_hi=3.00, g_lo=0.05, g_hi=3.00)
    certified, pruned = prune_manifold(root, max_depth=7)
    print(
        f"% SMT QF_NRA Manifold Pruning: "
        f"{len(certified)} certified cells, {pruned} unsat branches pruned"
    )
    for c in certified:
        # Conservative integer upper bound on constructive GSLW degree
        worst_q = (
            int((PREFACTOR_GSLW * LN_INV_EPS_NUM * c.a_hi) // (LN_INV_EPS_DEN * c.g_lo))
            + 1
        )
        print(
            f"smt_certified_cell({c.depth}, {c.a_lo:.6f}, {c.a_hi:.6f}, "
            f"{c.g_lo:.6f}, {c.g_hi:.6f}, {worst_q})."
        )
