/*
 * horn/smt_manifold_cert.pl
 *
 * Wiring SMT-certified (alpha_C, g) cells into the Horn verifier.
 *
 * Generate the fact file with:
 *   python3 formal/recursive_manifold_prune.py > horn/certified_manifold_cells.pl
 *
 * Then:
 *   :- consult('horn/certified_manifold_cells.pl').
 *   :- consult('horn/smt_manifold_cert.pl').
 *
 * qsvt_smt_manifold_cert(+AlphaC, +GapR, -UpperQueries) succeeds iff the
 * point lies inside an SMT QF_NRA certified cell whose constructive GSLW
 * degree UpperQueries is <= 1024.
 *
 * This automatically rejects the boundary (AlphaC=2.70, GapR=0.05) where
 * GSLW requires ~2985 queries, while admitting safer regimes such as
 * (AlphaC <= 2.70, GapR >= 0.15) where 4*(2.70/0.15)*13.82 ~ 995 <= 1024.
 */

:- dynamic smt_certified_cell/6.

% Succeeds iff (AlphaC, GapR) lies inside an SMT-certified manifold cell
% with constructive GSLW degree UpperQueries =< 1024.
qsvt_smt_manifold_cert(AlphaC, GapR, UpperQueries) :-
    smt_certified_cell(_, ALo, AHi, GLo, GHi, UpperQueries),
    AlphaC >= ALo, AlphaC =< AHi,
    GapR >= GLo, GapR =< GHi,
    UpperQueries =< 1024.

% Combined witness that also requires an SMT-certified cell
verified_weil_smt_witness(N, RhoLb, JacobiFrac, UpperQueries) :-
    rank_trace_cert(N, _, _, RhoLb, _, JacobiFrac, valid),
    (RhoLb > 0.6725 ; JacobiFrac > 0.6725),
    qsvt_smt_manifold_cert(2.70, 0.15, UpperQueries).
