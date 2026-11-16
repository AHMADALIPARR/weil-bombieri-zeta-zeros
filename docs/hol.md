# Higher-Order Logic and Refinement Types

## Isabelle/HOL

- `formal/hol/WeilBombieriRankTrace.thy` — algebraic rank-trace bound
- `formal/hol/IsabelleAutomation.thy` — demonstration of sledgehammer, smt, simp, etc. for related goals

## Liquid Haskell

- `liquid-haskell/` — thousands of lines of refinement types covering Matrix, Certificate, DirectedRounding, and QSVT policy

These replace the former Python modules (harness.py, quantum/*.py, etc.) with machine-checked specifications.

Open problem 6 (full floating-point directed-rounding soundness) remains; the LH layer provides abstract models and the Isabelle layer provides the pure math.
