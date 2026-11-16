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
kg -q candidate_weil.kg N   →  matrix_R.dat
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

## Status on this branch

The Python implementation of this gate (`harness/gate.py`, `harness/harness.py`) was removed at the owner's request. The pipeline above is still the contract, and its two executable stages can be run by hand:

```bash
kg -q candidate_weil.kg 128          # must exit 0 and write matrix_R.dat
./uuie/uuie_kernel 128 0.6725 matrix_R.dat   # exit 0 = accepted, 1 = rejected, 2 = bad input
```

The extraction of the `<klong_kernel>` block from raw model output and the automatic reject on missing kernels are not implemented in any remaining file.

## Design Rationale

- **Executable only.** The gate never evaluates a natural-language claim; it only evaluates a runnable Klong program.
- **Directed rounding.** Floating-point drift cannot manufacture a false positive.
- **Jacobi + Gershgorin.** A certified $n_+$ count under a Gershgorin safety margin complements the analytic trace-moment bound.
- **Zero trust in the generator.** The LLM may be stochastic, fine-tuned, or adversarial; the gate is deterministic and side-effect-free.
