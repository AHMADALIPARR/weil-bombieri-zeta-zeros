; formal/fp_rounding_witness.smt2
;
; Bit-exact IEEE-754 binary64 witness that round-to-nearest (RNE) and
; round-toward-positive (RTP) can disagree on the same exact quotient:
;
;   RNE(alpha / gap)  <  RTP(alpha / gap)
;
; This is the structural prerequisite for the ceiling-soundness gap:
; if the true real quotient lies just above an integer M while RNE lands
; at or below M, ceiling(RNE) under-reports the mathematical ceiling.
;
; Run:  z3 formal/fp_rounding_witness.smt2
; Expected: sat  (with concrete alpha, gap, q_rne, q_rtp)
;
; Verified sat under Z3 4.8.12. Re-run 2026-11-15 under Z3 5.4.1: sat.

(set-logic QF_FP)

(declare-const alpha Float64)
(declare-const gap   Float64)

(assert (fp.isNormal alpha))
(assert (fp.isNormal gap))
(assert (fp.gt alpha (_ +zero 11 53)))
(assert (fp.gt gap   (_ +zero 11 53)))
; Stay inside a scale comparable to the policy domain
(assert (fp.leq alpha ((_ to_fp 11 53) RNE 3.0)))
(assert (fp.leq gap   ((_ to_fp 11 53) RNE 3.0)))
(assert (fp.geq gap   ((_ to_fp 11 53) RNE 0.05)))
(assert (fp.leq gap alpha))

(define-const q_rne Float64 (fp.div RNE alpha gap))
(define-const q_rtp Float64 (fp.div RTP alpha gap))

; RNE strictly undercuts RTP on the same exact real quotient
(assert (fp.lt q_rne q_rtp))

(check-sat)
(get-value (alpha gap q_rne q_rtp))
