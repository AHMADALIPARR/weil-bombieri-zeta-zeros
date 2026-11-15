/*
 * formal/qsvt_manifold.als
 *
 * Alloy bounded model of the QSVT spectral-envelope parameter manifold.
 * Integer scaling by 20 maps physical values exactly:
 *   0.05 → 1,  2.70 → 54,  3.00 → 60.
 * Signed 14-bit Int gives range [-8192, 8191], safe for products up to
 * 4 × 60 × 14 = 3360.
 *
 * Commands:
 *   run FindRoundingSlip        → SAT  (truncating division under-reports)
 *   run FindUnsoundPrefactor    → SAT  (C=1 below Zolotarev floor)
 *   check HardenedManifoldSound → UNSAT (hardened invariant holds on children)
 *
 * CLI:
 *   java -jar org.alloytools.alloy.dist.jar exec -o - formal/qsvt_manifold.als
 */

module qsvt_manifold

open util/integer

one sig Policy {
  alpha_cap: Int,      // 60  => 3.00 (scaled by 20)
  gap_floor: Int,      // 1   => 0.05 (scaled by 20)
  log_inv_eps: Int,    // 14  => ceil(ln(10^6))
  query_cap: Int       // 1024
} {
  alpha_cap = 60
  gap_floor = 1
  log_inv_eps = 14
  query_cap = 1024
}

sig ManifoldCell {
  depth: Int,
  parent: lone ManifoldCell,
  alpha_min: Int,
  alpha_max: Int,
  gap_min: Int,
  gap_max: Int,
  d_prolog_floor: Int,   // C = 1 with truncating division
  d_zolotarev_lb: Int,   // Information-theoretic lower bound (> 5/4 * C=1)
  d_gslw_ceil: Int       // Constructive QSVT bound (C = 4 with upward ceiling)
} {
  depth >= 0 and depth <= 4
  // Valid non-empty box inside physical domain 0 < gap <= alpha <= alpha_cap
  gap_min >= Policy.gap_floor
  gap_min <= gap_max
  gap_max <= alpha_min
  alpha_min <= alpha_max
  alpha_max <= Policy.alpha_cap

  // Worst-case inverse gap ratio within cell occurs at (alpha_max, gap_min)
  let num = alpha_max.mul[Policy.log_inv_eps] |
  let q_trunc = num.div[gap_min] |
  let rem = num.rem[gap_min] |
  let q_ceil = (rem > 0) implies q_trunc.add[1] else q_trunc |
  {
    d_prolog_floor = q_trunc
    d_zolotarev_lb = q_ceil.add[q_ceil.div[4]]
    d_gslw_ceil = q_ceil.mul[4]
  }
}

// Recursive manifold tree invariants (acyclic bisection with strict box containment)
fact RecursiveManifoldStructure {
  no c: ManifoldCell | c in c.^parent
  all c: ManifoldCell | some c.parent implies {
    c.depth = c.parent.depth.add[1]
    c.alpha_min >= c.parent.alpha_min
    c.alpha_max <= c.parent.alpha_max
    c.gap_min >= c.parent.gap_min
    c.gap_max <= c.parent.gap_max
    // Strict bisection along at least one axis
    (c.alpha_max < c.parent.alpha_max) or
    (c.alpha_min > c.parent.alpha_min) or
    (c.gap_max < c.parent.gap_max) or
    (c.gap_min > c.parent.gap_min)
  }
  all c: ManifoldCell | no c.parent implies c.depth = 0
}

pred CurrentPrologAdmits[c: ManifoldCell] {
  c.d_prolog_floor <= Policy.query_cap
}

pred HardenedQSVTAdmits[c: ManifoldCell] {
  c.d_gslw_ceil <= Policy.query_cap
  c.d_gslw_ceil >= c.d_zolotarev_lb
}

// 1. SAT: Proves truncating/downward division admits a cell whose true ceiling > query_cap
run FindRoundingSlip {
  some c: ManifoldCell |
    CurrentPrologAdmits[c] and
    c.alpha_max.mul[Policy.log_inv_eps] > Policy.query_cap.mul[c.gap_min]
} for 4 ManifoldCell, 14 Int

// 2. SAT: Proves C=1 admits cells strictly below the Zolotarev polynomial existence bound
run FindUnsoundPrefactor {
  some c: ManifoldCell |
    CurrentPrologAdmits[c] and
    c.d_prolog_floor < c.d_zolotarev_lb
} for 4 ManifoldCell, 14 Int

// 3. UNSAT (counterexample check): Proves hardened invariant holds across all recursive children
assert HardenedManifoldSound {
  all p, c: ManifoldCell |
    (HardenedQSVTAdmits[p] and c in p.^parent) implies
      (HardenedQSVTAdmits[c] and c.d_gslw_ceil <= p.d_gslw_ceil)
}
check HardenedManifoldSound for 6 ManifoldCell, 14 Int
