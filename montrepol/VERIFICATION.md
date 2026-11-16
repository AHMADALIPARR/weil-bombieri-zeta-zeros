# Verification

## What is checked

- The rank-trace inequality on random Hermitian matrices (mp-linalg tests).
- The explicit formula residual against the first Odlyzko zeros (mp-analytic tests).
- That no source file contains a hardcoded numeric constant that the gate considers a claim (mp-gate).

## What is not checked

- Full floating-point soundness of any directed-rounding bound.
- That the Montgomery form-factor control extends past |alpha| = 1.
- Any individual ordinate gamma_n.

The gate is the standing promise. If it is red, a numeric claim has been written as a string instead of computed.
