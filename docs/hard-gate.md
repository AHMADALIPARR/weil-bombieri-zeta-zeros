# Hard Verification Gate

Every candidate produced by an LLM / Muse agent is subjected to a non-negotiable verification gate before it can become a certificate.

## Pipeline

```
raw LLM tokens
    ↓  normalize <0x0A> → \n
extract <klong_kernel> … </klong_kernel>
    ↓  (hard reject if missing)

write /tmp/candidate_weil.kg
    ↓
./klong/kg -l candidate_weil.kg   →  matrix_R.dat
    ↓  (hard reject on non-zero exit or missing matrix)

./uuie/uuie_kernel N target matrix_R.dat
    ↓  directed-rounding ρ + Jacobi n₊ + Gershgorin margin

exit 0  ⇒  accepted  +  sealed Horn fact
exit 1  ⇒  rejected
```

## Acceptance Criteria (all must hold)

1. A well-formed `<klong_kernel>` block is present.
2. The Klong source executes without error and emits `matrix_R.dat`.
3. The matrix is finite and conjugate-symmetric to machine precision.
4. Either the directed-rounding lower bound $\rho_{\mathrm{lower}} >$ target **or** the certified Jacobi fraction $n_+(R)/N >$ target.

Any prose-only answer, any kernel that fails to emit a matrix, any numerical instability, or any certificate that misses the target is **hard-rejected**. There is no soft threshold, no “almost”, and no override.

## API

```python
from harness.gate import clean_and_gate_llm_output
from harness.harness import step_synthesis_klong, gate_response

verdict = gate_response(raw_llm_text, n=128, target_rho=0.6725)
if verdict["accepted"]:
    print(verdict["horn_fact"])   # sealed ground fact for the Horn engine
```

## Design Rationale

- **Executable only.** The gate never evaluates a natural-language claim; it only evaluates a runnable Klong program.
- **Directed rounding.** Floating-point drift cannot manufacture a false positive.
- **Jacobi + Gershgorin.** Exact $n_+$ under a rigorous safety margin complements the analytic trace-moment bound.
- **Zero trust in the generator.** The LLM may be stochastic, fine-tuned, or adversarial; the gate is deterministic and side-effect-free.
