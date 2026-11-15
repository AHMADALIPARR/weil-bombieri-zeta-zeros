:- use_module(library(error)).

/*
 * qsvt_polylog_cert(+N, +AlphaC, +GapR, ?MaxQueries)
 *
 * Checks the proposed numerical query envelope:
 *
 *   ceil((AlphaC / GapR) * ln(1 / Eps)) =< QueryCap
 *
 * GapR is a gap of the ORIGINAL matrix R.
 * If the gap is already normalized by AlphaC, do not divide by
 * AlphaC again.
 *
 * MaxQueries is unified with the computed envelope, not with
 * the fixed cap of 1024.
 *
 * This is a conditional budget check, not an independent
 * mathematical certificate of an actual QSVT implementation.
 */

qsvt_polylog_cert(N, AlphaC, GapR, MaxQueries) :-
    qsvt_polylog_report(N, AlphaC, GapR, Report),
    MaxQueries = Report.query_envelope.


/*
 * qsvt_polylog_report(+N, +AlphaC, +GapR, -Report)
 *
 * Throws for uninstantiated, incorrectly typed, or non-finite
 * input arguments.
 *
 * Fails for well-typed inputs outside the accepted envelope.
 */

qsvt_polylog_report(N, AlphaC, GapR, Report) :-
    must_be(positive_integer, N),
    qsvt_finite_number(AlphaC),
    qsvt_finite_number(GapR),

    qsvt_envelope_policy(
        AlphaCap,
        GapFloor,
        Eps,
        QueryCap
    ),

    AlphaC > 0,
    AlphaC =< AlphaCap,
    GapR >= GapFloor,
    GapR =< AlphaC,

    NormalizedGap is GapR / AlphaC,
    QueryEnvelope is ceiling(
        (AlphaC / GapR) * log(1 / Eps)
    ),
    QueryEnvelope =< QueryCap,

    Report = qsvt_envelope{
        n: N,
        normalization: AlphaC,
        physical_gap_lower_bound: GapR,
        normalized_gap_lower_bound: NormalizedGap,
        target_polynomial_error: Eps,
        query_envelope: QueryEnvelope,
        query_cap: QueryCap,
        status: conditional_budget_pass
    }.


qsvt_envelope_policy(
    3.0,       % Maximum supplied normalization
    0.05,      % Minimum supplied physical gap
    1.0e-6,    % Target polynomial approximation error
    1024       % Query-envelope cap
).


qsvt_finite_number(X) :-
    must_be(number, X),
    (   float(X)
    ->  float_class(X, Class),
        (   memberchk(Class, [zero, subnormal, normal])
        ->  true
        ;   domain_error(finite_number, X)
        )
    ;   true
    ).


/*
 * Combined witness.
 *
 * once/1 avoids a duplicate success when BOTH inequalities hold
 * for the same rank_trace_cert/7 result.
 *
 * The normalization and gap remain supplied assumptions here;
 * rank_trace_cert/7 does not establish them merely by succeeding.
 */

verified_weil_quantum_witness(
    N,
    RhoLb,
    JacobiFrac,
    MaxQueries
) :-
    rank_trace_cert(
        N, _, _, RhoLb, _, JacobiFrac, valid
    ),
    qsvt_finite_number(RhoLb),
    qsvt_finite_number(JacobiFrac),
    once((
        RhoLb > 0.6725
    ;
        JacobiFrac > 0.6725
    )),
    qsvt_polylog_cert(
        N, 2.70, 0.05, MaxQueries
    ).


/* ---------- legacy classical certificates (kept for compatibility) ---------- */

:- op(1200, xfx, '<-').

prove(true, trivial).
prove((A, B), pair(PA, PB)) :- prove(A, PA), prove(B, PB).
prove(Goal, Term) :-
    (Goal <- Body),
    prove(Body, SubProof),
    Goal =.. [Pred | _],
    atom_concat(Pred, '_intro', Ctor),
    Term =.. [Ctor, SubProof].

simple_critical(RhoLower) <-
    compression(Psi, Grid, R),
    unit_band(Psi),
    conjugate_sym(R),
    stable(R),
    rank_trace_cert(_, _, _, RhoLower, _, _, valid),
    RhoLower > 0.6725.

simple_critical_exact(RhoLower, Nplus, N) <-
    compression(Psi, Grid, R),
    unit_band(Psi),
    conjugate_sym(R),
    stable(R),
    rank_trace_cert(N, _, _, RhoLower, Nplus, _, valid),
    RhoLower > 0.6725,
    Nplus > 0.6725 * N.

distinct(RhoD) <-
    simple_critical(RhoS),
    RhoD is (3.0 - (1.0 / RhoS)) / 2.0,
    RhoD > 0.8333333333333334.
