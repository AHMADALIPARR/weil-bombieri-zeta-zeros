/*
 * Run with:
 *   swipl -q -s horn/horn_cert.pl -s horn/test_qsvt_polylog.pl -g "run_tests, halt"
 *
 * Or consult both into the same module and call run_tests/0.
 */

:- begin_tests(qsvt_polylog_cert).

test(reference_parameters) :-
    qsvt_polylog_cert(1000000, 2.70, 0.05, 747).

test(policy_boundary) :-
    qsvt_polylog_cert(100, 3.0, 0.05, 829).

test(report) :-
    qsvt_polylog_report(100, 2.70, 0.05, Report),
    get_dict(query_envelope, Report, Env),
    assertion(Env =:= 747),
    get_dict(status, Report, Status),
    assertion(Status == conditional_budget_pass).

test(unbound_n,
     [throws(error(instantiation_error, _))]) :-
    qsvt_polylog_cert(_, 2.70, 0.05, _).

test(noninteger_n,
     [throws(error(type_error(integer, 1.5), _))]) :-
    qsvt_polylog_cert(1.5, 2.70, 0.05, _).

test(zero_n,
     [throws(error(domain_error(positive_integer, 0), _))]) :-
    qsvt_polylog_cert(0, 2.70, 0.05, _).

test(non_numeric_alpha,
     [throws(error(type_error(number, bad), _))]) :-
    qsvt_polylog_cert(100, bad, 0.05, _).

test(zero_alpha,
     [throws(error(domain_error(positive_normalization, 0), _))]) :-
    qsvt_polylog_cert(100, 0, 0.05, _).

test(zero_gap,
     [throws(error(domain_error(positive_spectral_gap, 0), _))]) :-
    qsvt_polylog_cert(100, 2.70, 0, _).

test(negative_gap,
     [throws(error(domain_error(positive_spectral_gap, -1), _))]) :-
    qsvt_polylog_cert(100, 2.70, -1, _).

test(gap_above_normalization,
     [throws(error(
         domain_error(
             gap_not_exceeding_normalization,
             gap_and_normalization(0.2, 0.1)
         ),
         _
     ))]) :-
    qsvt_polylog_cert(100, 0.1, 0.2, _).

test(alpha_outside_policy, [fail]) :-
    qsvt_polylog_cert(100, 3.01, 0.05, _).

test(gap_outside_policy, [fail]) :-
    qsvt_polylog_cert(100, 2.70, 0.049, _).

test(negative_output,
     [throws(error(domain_error(nonnegative_integer, -1), _))]) :-
    qsvt_polylog_cert(100, 2.70, 0.05, -1).

test(float_output,
     [throws(error(type_error(integer, 747.0), _))]) :-
    qsvt_polylog_cert(100, 2.70, 0.05, 747.0).

test(incorrect_output, [fail]) :-
    qsvt_polylog_cert(100, 2.70, 0.05, 1024).

test(exception_identifies_public_predicate,
     [throws(error(
         domain_error(positive_integer, 0),
         context(qsvt_polylog_cert/4, _)
     ))]) :-
    qsvt_polylog_cert(0, 2.70, 0.05, _).

test(witness_without_certificate, [fail]) :-
    retractall(user:rank_trace_cert(_, _, _, _, _, _, _)),
    verified_weil_quantum_witness(128, _, _, _).

test(witness_with_certificate,
     [ setup(assertz(user:rank_trace_cert(128, 1.0, 1.0, 0.7, 128, 1.0, valid))),
       cleanup(retractall(user:rank_trace_cert(_, _, _, _, _, _, _))),
       true(Q == 747) ]) :-
    verified_weil_quantum_witness(128, _, _, Q).

test(witness_rejected_certificate, [fail]) :-
    setup_call_cleanup(
        assertz(user:rank_trace_cert(128, 1.0, 1.0, 0.7, 128, 1.0, reject)),
        verified_weil_quantum_witness(128, _, _, _),
        retractall(user:rank_trace_cert(_, _, _, _, _, _, _))).

:- end_tests(qsvt_polylog_cert).
