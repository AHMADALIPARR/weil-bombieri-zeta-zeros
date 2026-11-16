# Higher-Order Logic Layer

The repository now contains an Isabelle/HOL formalization of the
elementary rank-trace inequality that turns a positive trace-moment
ratio into a lower bound on the number of positive eigenvalues.

See `formal/hol/WeilBombieriRankTrace.thy` and `formal/hol/README.md`.

This addresses part of open problem 6 (machine-checked proof of the
UUie inequalities) by securing the pure mathematical step. The
floating-point directed-rounding argument that produces the concrete
numbers `tr_down` and `hs2_up` is still outside the logic.

The Horn certificates continue to consume the numeric witnesses emitted
by the C kernel; the HOL theory supplies an independent proof that those
witnesses are meaningful.
