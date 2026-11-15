#!/usr/bin/env python3
"""
harness/gate.py

Hard verification gate for any LLM (or Muse) output.

1. Normalizes SentencePiece / Llama byte-fallback newlines (<0x0A>).
2. Extracts only executable Klong source from <klong_kernel>...</klong_kernel>.
3. Runs the kernel under kg → produces matrix_R.dat.
4. Feeds the matrix to the UUie directed-rounding + Jacobi oracle.
5. Accepts the candidate if and only if the certificate returns exit code 0
   (i.e. rho_lower > target or jacobi_frac > target, plus conjugate symmetry
   and finiteness).

No prose, no partial kernels, no floating-point claims without a sealed Horn fact.
"""

from __future__ import annotations

import re
import subprocess
from pathlib import Path
from typing import Any


def clean_and_gate_llm_output(
    raw_tokens_text: str,
    n: int = 128,
    target_rho: float = 0.6725,
    kg_bin: str = "./klong/kg",
    uuie_bin: str = "./uuie/uuie_kernel",
    work_dir: str | Path = "/tmp",
) -> dict[str, Any]:
    """
    Hard-gate an LLM response.

    Returns a dict with at least the key "accepted" (bool).
    On success also returns the sealed Horn ground fact.
    """
    work_dir = Path(work_dir)
    work_dir.mkdir(parents=True, exist_ok=True)

    # 1. Normalize raw byte-fallback newlines emitted by Llama / SentencePiece
    text = raw_tokens_text.replace("<0x0A>", "\n")

    # 2. Hard-reject prose-only responses that lack an executable Klong kernel
    match = re.search(r"<klong_kernel>(.*?)</klong_kernel>", text, re.S)
    if not match:
        return {"accepted": False, "reason": "NO_EXECUTABLE_KERNEL"}

    kernel_src = match.group(1).strip()
    candidate = work_dir / "candidate_weil.kg"
    matrix = work_dir / "matrix_R.dat"

    candidate.write_text(kernel_src + "\n", encoding="utf-8")

    # 3. Execute Klong → matrix_R.dat
    kg_run = subprocess.run(
        [kg_bin, "-l", str(candidate)],
        capture_output=True,
        text=True,
        cwd=work_dir,
    )
    if kg_run.returncode != 0:
        return {
            "accepted": False,
            "reason": "KLONG_EXEC_FAIL",
            "stderr": kg_run.stderr,
            "stdout": kg_run.stdout,
        }

    if not matrix.exists():
        return {
            "accepted": False,
            "reason": "NO_MATRIX_EMITTED",
            "stdout": kg_run.stdout,
        }

    # 4. UUie directed-rounding + Jacobi oracle
    uuie_run = subprocess.run(
        [uuie_bin, str(n), str(target_rho), str(matrix)],
        capture_output=True,
        text=True,
        cwd=work_dir,
    )

    return {
        "accepted": uuie_run.returncode == 0,
        "horn_fact": uuie_run.stdout.strip(),
        "returncode": uuie_run.returncode,
        "stderr": uuie_run.stderr.strip() if uuie_run.stderr else "",
        "kernel_sha256": __import__("hashlib").sha256(kernel_src.encode()).hexdigest(),
    }


if __name__ == "__main__":
    # Minimal self-test with a deliberately invalid (prose-only) payload
    dummy = "The ratio is obviously larger than 0.67 because of positivity."
    print(clean_and_gate_llm_output(dummy))
