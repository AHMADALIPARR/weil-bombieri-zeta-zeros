# Conformance

This file records what the repository claims to conform to, and how that claim
is discharged.

## Analytic side

The explicit formula implementation in `packages/mp-analytic` is checked against
the Odlyzko zero tables in `oracles/zeta-zeros-odlyzko.txt`. The check is a
finite residual; it is not a proof that the formula holds for all zeros.

## Linear algebra side

`packages/mp-linalg` implements the rank-trace lower bound and the participation
ratio. Both are checked by random Hermitian matrices of modest size in the test
suite. The bound itself is classical (Bombieri).

## Gate

`mp-gate` is the standing promise that no numeric claim is hardcoded. It scans
source for string literals that look like computed constants and fails if it
finds one outside the allow-list in `model/ids.toml`.

## What is not claimed

- That the Riemann hypothesis is proved here.
- That any particular zero is certified simple by a machine-checked proof.
- That the directed-rounding bounds in the companion C kernel are fully sound.
