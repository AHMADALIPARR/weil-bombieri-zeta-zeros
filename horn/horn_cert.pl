:- use_module(library(error)).

% rank_trace_cert/7 facts are emitted by uuie/uuie_kernel and consulted at
% run time. Declaring the predicate dynamic makes the combined witness fail
% cleanly (instead of raising existence_error) when no certificate is loaded.
:- dynamic rank_trace_cert/7.

/*
 * qsvt_polylog_cert(+N, +AlphaC, +GapR, ?MaxQueries)
 *
 * Throws:
 *   - Instantiation/type errors for invalid argument modes or types.
 *   - Domain errors for invalid physical parameters.
 *   - Contextualized arithmetic errors.
 *
 * Fails:
 *   - Valid parameters exceed the configured envelope.
 *   - A valid, pre-bound MaxQueries differs from the computed value.
 *
 * Success is a conditional numerical budget check only.
 */

qsvt_polylog_cert(N, AlphaC, GapR, MaxQueries) :-
    qsvt_with_context(
        qsvt_polylog_cert/4,
        (
            qsvt_validate_query_output(MaxQueries),
            qsvt_build_report(N, AlphaC, GapR, Report),
            get_dict(query_envelope, Report, MaxQueries)
        )
    ).


qsvt_polylog_report(N, AlphaC, GapR, Report) :-
    qsvt_with_context(
        qsvt_polylog_report/4,
        qsvt_build_report(N, AlphaC, GapR, Report)
    ).


qsvt_build_report(N, AlphaC, GapR, Report) :-
    qsvt_validate_inputs(N, AlphaC, GapR),

    qsvt_envelope_policy(
        AlphaCap,
        GapFloor,
        Eps,
        QueryCap
    ),

    % Valid inputs outside policy fail, rather than throw.
    AlphaC =< AlphaCap,
    GapR >= GapFloor,

    % Calculate alpha/gap first, avoiding premature underflow
    % from calculating gap/alpha.
    InverseGap is AlphaC / GapR,
    qsvt_require_positive_finite(InverseGap),

    LogInverseError is -log(Eps),
    RawQueries is InverseGap * LogInverseError,
    qsvt_require_positive_finite(RawQueries),

    QueryEnvelope is ceiling(RawQueries),
    QueryEnvelope =< QueryCap,

    NormalizedGap is 1 / InverseGap,
    qsvt_require_positive_finite(NormalizedGap),

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


qsvt_validate_inputs(N, AlphaC, GapR) :-
    must_be(integer, N),
    (   N >= 1
    ->  true
    ;   domain_error(positive_integer, N)
    ),

    qsvt_finite_number(AlphaC),
    qsvt_finite_number(GapR),

    (   AlphaC > 0
    ->  true
    ;   domain_error(positive_normalization, AlphaC)
    ),

    (   GapR > 0
    ->  true
    ;   domain_error(positive_spectral_gap, GapR)
    ),

    (   GapR =< AlphaC
    ->  true
    ;   domain_error(
            gap_not_exceeding_normalization,
            gap_and_normalization(GapR, AlphaC)
        )
    ).


/*
 * An unbound output is allowed.
 * A pre-bound output must be a nonnegative integer.
 * A well-typed but incorrect count subsequently fails by unification.
 */

qsvt_validate_query_output(MaxQueries) :-
    (   var(MaxQueries)
    ->  true
    ;   must_be(integer, MaxQueries),
        (   MaxQueries >= 0
        ->  true
        ;   domain_error(nonnegative_integer, MaxQueries)
        )
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
 * Handles both explicit non-finite results and zero produced
 * by underflow when the runtime permits those results.
 */

qsvt_require_positive_finite(X) :-
    qsvt_finite_number(X),
    (   X > 0
    ->  true
    ;   evaluation_error(underflow)
    ).


/*
 * Add the public predicate's identity without hiding the
 * original error category, including evaluation_error/1.
 * Ordinary failure is not converted into an exception.
 */

qsvt_with_context(Predicate, Goal) :-
    catch(
        call(Goal),
        error(Formal, OriginalContext),
        throw(
            error(
                Formal,
                context(Predicate, OriginalContext)
            )
        )
    ).


qsvt_envelope_policy(
    3.0,
    0.05,
    1.0e-6,
    1024
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
