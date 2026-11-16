theory IsabelleAutomation
  imports WeilBombieriRankTrace
begin

(*
  Isabelle/HOL Proof Automation Layer
  ===================================

  This theory demonstrates and documents the use of Isabelle's automation
  (sledgehammer, auto, simp, blast, metis, smt, etc.) for discharging
  the linear-algebra goals arising from the Weil-Bombieri certificates.

  The core rank-trace bound is already proved in WeilBombieriRankTrace.
  Here we show how automation can be applied to related lemmas and to
  future extensions (Jacobi residual bounds, directed-rounding sketches,
  QSVT degree envelopes).

  Typical workflow:
  - State a goal.
  - Run `sledgehammer` (or the panel) to find a proof.
  - Reconstruct with `by (metis ...)` or `by auto` etc.
  - Prefer structured Isar for readability when the proof is non-trivial.
*)

lemma example_automation_cauchy:
  fixes a b :: real
  assumes "a > 0" "b > 0"
  shows "a^2 / b + b^2 / a >= 2 * a * b / sqrt (a * b)"
  by (smt (verit) assms power2_eq_square real_sqrt_mult_self)

lemma positive_part_automation:
  fixes xs :: "real list"
  shows "sum_list (map (\x. if x > 0 then x else 0) xs) >= sum_list xs"
  by (simp add: sum_list_mono)

text \<open>
  Automation status
  -----------------
  - Sledgehammer + metis reconstruction works well for first-order fragments
    of the rank-trace argument.
  - Higher-order or arithmetic goals often benefit from `smt` or `auto`.
  - The directed-rounding floating-point inequalities remain outside the
    scope of pure HOL automation and are tracked as open problem 6.
\<close>

end
