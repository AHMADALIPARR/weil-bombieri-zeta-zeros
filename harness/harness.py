#!/usr/bin/env python3
"""
Hard-gated synthesis harness.

Any LLM / Muse response is accepted if and only if:

  1. it contains a well-formed <klong_kernel>...</klong_kernel> block,
  2. the extracted Klong source executes cleanly and emits matrix_R.dat,
  3. the UUie directed-rounding + Jacobi oracle returns a valid certificate
     (rho_lower > target or jacobi_frac > target, conjugate symmetry, finite).

Prose-only answers, malformed kernels, execution failures, and certificates
that miss the target are hard-rejected.  No exceptions.
"""

from __future__ import annotations

import hashlib
import re
from pathlib import Path
from typing import Any

from harness.gate import clean_and_gate_llm_output

# Optional legacy CBQN path (kept for backward compatibility)
try:
    import ctypes
    _HAS_CBQN = True
except ImportError:
    _HAS_CBQN = False


def gate_response(
    raw_llm_text: str,
    n: int = 128,
    target_rho: float = 0.6725,
) -> dict[str, Any]:
    """
    Single entry-point used by every synthesis step.

    Returns the full gate verdict, including the sealed Horn fact on success.
    """
    return clean_and_gate_llm_output(
        raw_tokens_text=raw_llm_text,
        n=n,
        target_rho=target_rho,
        kg_bin="./klong/kg",
        uuie_bin="./uuie/uuie_kernel",
        work_dir="/tmp",
    )


def step_synthesis_klong(
    llm_raw_output: str,
    n: int = 128,
    target_rho: float = 0.6725,
) -> dict[str, Any]:
    """
    Preferred synthesis step: hard-gate an LLM response that is expected to
    emit a <klong_kernel> block.
    """
    verdict = gate_response(llm_raw_output, n=n, target_rho=target_rho)

    if not verdict["accepted"]:
        return {
            "status": "REJECT",
            "reason": verdict.get("reason", "CERTIFICATE_FAIL"),
            "detail": verdict,
        }

    return {
        "status": "ACCEPTED",
        "horn_fact": verdict["horn_fact"],
        "kernel_sha256": verdict.get("kernel_sha256"),
        "detail": verdict,
    }


# ---------------------------------------------------------------------------
# Legacy CBQN path (still available but no longer the primary gate)
# ---------------------------------------------------------------------------
if _HAS_CBQN:
    def _eval_cbqn_scalar(expr: str) -> float:
        cbqn = ctypes.CDLL("./CBQN/libcbqn.so")
        cbqn.bqn_init.restype = None
        cbqn.bqn_eval.argtypes = [ctypes.c_uint64]
        cbqn.bqn_eval.restype = ctypes.c_uint64
        cbqn.bqn_makeUTF8Str.argtypes = [ctypes.c_size_t, ctypes.c_char_p]
        cbqn.bqn_makeUTF8Str.restype = ctypes.c_uint64
        cbqn.bqn_readF64.argtypes = [ctypes.c_uint64]
        cbqn.bqn_readF64.restype = ctypes.c_double
        cbqn.bqn_free.argtypes = [ctypes.c_uint64]
        cbqn.bqn_init()
        raw = expr.encode("utf-8")
        bqn_str = cbqn.bqn_makeUTF8Str(len(raw), raw)
        res_obj = cbqn.bqn_eval(bqn_str)
        val = cbqn.bqn_readF64(res_obj)
        cbqn.bqn_free(res_obj)
        return val


if __name__ == "__main__":
    # Smoke-test the hard gate with a prose-only payload (must be rejected)
    prose = "The ratio is obviously larger than 0.67 because of positivity."
    print("Prose-only test:", gate_response(prose))

    # Smoke-test with a missing matrix emission (still rejected)
    fake_kernel = """<klong_kernel>
N::16
.d("no matrix emitted")
</klong_kernel>"""
    print("Kernel-without-matrix test:", gate_response(fake_kernel))
