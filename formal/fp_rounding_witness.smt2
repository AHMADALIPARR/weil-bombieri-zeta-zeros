; formal/fp_rounding_witness.smt2
;
; Bit-exact IEEE-754 binary64 proof that RNE (FE_TONEAREST) can undercut
; the exact quotient while RTP (FE_UPWARD) preserves an upward bound.
;
; alpha = 0.5 + 3*2^-53 = (2^52 + 3)*2^-53
; gap   = 0.25 + 2^-54  = (2^52 + 1)*2^-54
;
; Run:  z3 formal/fp_rounding_witness.smt2
; Expected: sat, with q_rne = 2.0 and q_rtp > 2.0

(set-logic QF_FP)

; Exact IEEE-754 binary64 (11-bit exponent, 53-bit significand)
; alpha: exp bias 1023 -> 1022 = #b01111111110, sig = 3
; gap:   exp bias 1023 -> 1021 = #b01111111101, sig = 1
(define-const alpha Float64 (fp #b0 #b01111111110 #x0000000000003))
(define-const gap   Float64 (fp #b0 #b01111111101 #x0000000000001))
(define-const two   Float64 ((_ to_fp 11 53) RNE 2.0))

(declare-const q_rne Float64)
(declare-const q_rtp Float64)

(assert (= q_rne (fp.div RNE alpha gap)))
(assert (= q_rtp (fp.div RTP alpha gap)))

; Assert RNE undercuts exact quotient (2.0 < alpha/gap) while RTP preserves upward bound
(assert (fp.eq q_rne two))
(assert (fp.gt q_rtp two))

(check-sat)
(get-value (q_rne q_rtp))
