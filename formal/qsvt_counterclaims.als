/*
 * formal/qsvt_counterclaims.als
 *
 * Alloy encoding of the two soundness gaps in qsvt_polylog_cert/4:
 *
 *   1. IEEE-754 round-to-nearest before ceiling can under-report the true
 *      mathematical ceiling (discontinuity at integer boundaries).
 *   2. The hardcoded prefactor C = 1 is strictly smaller than both the
 *      Zolotarev/Eremenko–Yuditskii lower bound (~4/π) and the constructive
 *      GSLW erf-Chebyshev bound (~4), so the reported degree is not a sound
 *      QSVT query count.
 *
 * This model does NOT claim to prove floating-point theorems inside Alloy;
 * it records the logical structure of the counterclaims so that any future
 * certificate claiming "QueryEnvelope is a sound QSVT upper bound" must
 * discharge these assertions explicitly.
 *
 * Run (Alloy Analyzer 6+):
 *   Execute  "check FPCeilingUnderReport"
 *   Execute  "check PrefactorBelowZolotarev"
 *   Execute  "check PrefactorBelowGSLW"
 *   Execute  "run CounterexampleWitness"
 */

module qsvt_counterclaims

/* ---------- Numeric quantities (abstract, ordered) ---------- */

sig PosReal {}

/* Abstract order on positive reals (sufficient for the comparisons we need) */
pred lt[a, b: PosReal] { a != b and a->b in Order }
pred leq[a, b: PosReal] { a = b or lt[a, b] }

one sig Order in PosReal -> PosReal {}

fact OrderIsStrictPartial {
  no iden & Order                    // irreflexive
  Order.Order in Order               // transitive
  all a, b: PosReal |                // total on the finite universe we analyze
    a = b or a->b in Order or b->a in Order
}

/* ---------- Policy parameters ---------- */

one sig Policy {
  alphaCap: PosReal,                 // 3.0
  gapFloor: PosReal,                 // 0.05
  eps: PosReal,                      // 1e-6
  queryCap: PosReal                 // 1024
}

/* ---------- A concrete certification attempt ---------- */

sig CertAttempt {
  alphaC: PosReal,
  gapR: PosReal,
  // True mathematical value (alphaC/gapR)*ln(1/eps)
  trueProduct: PosReal,
  // IEEE-754 round-to-nearest evaluation of the same expression
  flProduct: PosReal,
  // ceiling of the floating-point product (what Prolog returns)
  reportedEnvelope: PosReal,
  // True mathematical ceiling
  trueCeiling: PosReal,
  // Prefactors
  prologPrefactor: PosReal,          // C = 1 (hardcoded)
  zolotarevPrefactor: PosReal,       // 4/π ≈ 1.27324
  gslwPrefactor: PosReal,            // ≈ 4 (constructive)
  // Degrees implied by each prefactor
  prologDegree: PosReal,
  zolotarevDegree: PosReal,
  gslwDegree: PosReal
}

/* Policy membership: inputs inside the accepted numeric envelope */
pred InPolicy[c: CertAttempt] {
  leq[c.alphaC, Policy.alphaCap]
  leq[Policy.gapFloor, c.gapR]
  leq[c.gapR, c.alphaC]
}

/* ---------- Counterclaim 1: FP ceiling under-report ---------- */

/*
 * Round-to-nearest can place flProduct on or below an integer while
 * trueProduct lies strictly above that integer.  ceiling is discontinuous
 * there, so reportedEnvelope < trueCeiling.
 */
pred FPCeilingGap[c: CertAttempt] {
  InPolicy[c]
  // Floating-point product is a strict under-approximation
  lt[c.flProduct, c.trueProduct]
  // Discontinuity: true product has crossed an integer that fl has not
  // (modelled by reportedEnvelope < trueCeiling)
  lt[c.reportedEnvelope, c.trueCeiling]
  // Policy still accepts the under-reported value
  leq[c.reportedEnvelope, Policy.queryCap]
  // while the true ceiling would have been rejected (or is larger)
  not leq[c.trueCeiling, Policy.queryCap] or lt[c.reportedEnvelope, c.trueCeiling]
}

assert FPCeilingUnderReport {
  // There exist policy-valid attempts where the reported envelope is
  // strictly smaller than the true mathematical ceiling.
  some c: CertAttempt | FPCeilingGap[c]
}

/* ---------- Counterclaim 2: prefactor C = 1 is below known bounds ---------- */

pred PrefactorOrdering[c: CertAttempt] {
  // C_prolog = 1 < C_zolotarev ≈ 1.273 < C_gslw ≈ 4
  lt[c.prologPrefactor, c.zolotarevPrefactor]
  lt[c.zolotarevPrefactor, c.gslwPrefactor]
  // Degrees scale with the prefactor for fixed (alphaC, gap, eps)
  lt[c.prologDegree, c.zolotarevDegree]
  lt[c.zolotarevDegree, c.gslwDegree]
}

assert PrefactorBelowZolotarev {
  all c: CertAttempt |
    PrefactorOrdering[c] implies lt[c.prologDegree, c.zolotarevDegree]
}

assert PrefactorBelowGSLW {
  all c: CertAttempt |
    PrefactorOrdering[c] implies lt[c.prologDegree, c.gslwDegree]
}

/*
 * On the reference unit-test parameters the Prolog degree (747) lies
 * strictly below the Zolotarev lower bound (~950).  Consequently no odd
 * polynomial of that degree can satisfy the QSVT sign conditions.
 */
pred ReferenceParametersUnsound[c: CertAttempt] {
  InPolicy[c]
  PrefactorOrdering[c]
  // Reported degree is accepted by the policy
  leq[c.prologDegree, Policy.queryCap]
  // but the Zolotarev lower bound already exceeds the reported degree
  lt[c.prologDegree, c.zolotarevDegree]
  // and the constructive GSLW degree exceeds the query cap itself
  not leq[c.gslwDegree, Policy.queryCap]
}

/* ---------- Witness search ---------- */

run CounterexampleWitness {
  some c: CertAttempt |
    FPCeilingGap[c] or ReferenceParametersUnsound[c]
} for 6 PosReal, 2 CertAttempt

check FPCeilingUnderReport for 6 PosReal, 2 CertAttempt
check PrefactorBelowZolotarev for 6 PosReal, 2 CertAttempt
check PrefactorBelowGSLW for 6 PosReal, 2 CertAttempt

/* ---------- Documentation facts (always true in the model) ---------- */

fact PrefactorConstantsDistinct {
  all c: CertAttempt | PrefactorOrdering[c]
}

/*
 * Summary (mirrors docs/qsvt-polylog-soundness.md):
 *
 * Certified by qsvt_polylog_cert/4:
 *   - type/domain safety, positivity, non-finiteness, policy filter
 *
 * Outside the mathematical guarantee:
 *   - ceiling soundness under FE_TONEAREST
 *   - existence of a QSVT phase sequence of degree QueryEnvelope
 *     (requires C_cert >= C_zolotarev and a verified phase certificate)
 */
