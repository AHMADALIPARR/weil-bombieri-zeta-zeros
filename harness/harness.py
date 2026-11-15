#!/usr/bin/env python3
"""
Zero-bloat harness: raw transformers/torch Llama-3 + direct libcbqn.so FFI.
No LangChain, no JSON wrappers. Strict XML extraction of <cbqn_kernel> blocks.
"""

import ctypes
import re
import hashlib
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM

# ---------------------------------------------------------------------------
# 1. Bind libcbqn.so directly via C FFI
# ---------------------------------------------------------------------------
cbqn = ctypes.CDLL("./CBQN/libcbqn.so")  # adjust path as needed
cbqn.bqn_init.restype = None
cbqn.bqn_eval.argtypes = [ctypes.c_uint64]
cbqn.bqn_eval.restype = ctypes.c_uint64
cbqn.bqn_makeUTF8Str.argtypes = [ctypes.c_size_t, ctypes.c_char_p]
cbqn.bqn_makeUTF8Str.restype = ctypes.c_uint64
cbqn.bqn_readF64.argtypes = [ctypes.c_uint64]
cbqn.bqn_readF64.restype = ctypes.c_double
cbqn.bqn_free.argtypes = [ctypes.c_uint64]
cbqn.bqn_init()


def eval_cbqn_scalar(expr: str) -> float:
    raw = expr.encode("utf-8")
    bqn_str = cbqn.bqn_makeUTF8Str(len(raw), raw)
    res_obj = cbqn.bqn_eval(bqn_str)
    val = cbqn.bqn_readF64(res_obj)
    cbqn.bqn_free(res_obj)
    return val


# ---------------------------------------------------------------------------
# 2. Load Llama 3 in raw PyTorch (bfloat16, deterministic)
# ---------------------------------------------------------------------------
MODEL_ID = "meta-llama/Meta-Llama-3-8B-Instruct"
tok = AutoTokenizer.from_pretrained(MODEL_ID)
model = AutoModelForCausalLM.from_pretrained(
    MODEL_ID, torch_dtype=torch.bfloat16, device_map="cuda"
)


def step_synthesis(xml_prompt: str) -> dict:
    inputs = tok(xml_prompt, return_tensors="pt").to("cuda")
    with torch.no_grad():
        out = model.generate(
            **inputs,
            max_new_tokens=768,
            do_sample=False,
            temperature=None,
            top_p=None,
            eos_token_id=tok.encode("</witness>", add_special_tokens=False)[-1],
        )
    text = tok.decode(out[0][inputs["input_ids"].shape[1] :], skip_special_tokens=True)
    kernel_match = re.search(r"<cbqn_kernel>(.*?)</cbqn_kernel>", text, re.S)
    if not kernel_match:
        return {"status": "REJECT_PARSE", "raw": text}

    code = kernel_match.group(1).strip()
    score = eval_cbqn_scalar(code)
    digest = hashlib.sha256(code.encode()).hexdigest()
    return {
        "status": "EXECUTED",
        "score": score,
        "sha256": digest,
        "kernel": code,
    }


if __name__ == "__main__":
    # Minimal smoke test — replace with full Muse system contract in production
    print("Harness loaded. Call step_synthesis(prompt) to run a synthesis step.")
