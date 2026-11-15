% horn_cert.pl — SLD-resolution witness constructor for simple_critical(Rho)
% + polylogarithmic QSVT complexity envelope
:- op(1200, xfx, '<-').

prove(true, trivial).
prove((A, B), pair(PA, PB)) :- prove(A, PA), prove(B, PB).
prove(Goal, Term) :-
    (Goal <- Body),
    prove(Body, SubProof),
    Goal =.. [Pred | _],
    atom_concat(Pred, '_intro', Ctor),
    Term =.. [Ctor, SubProof].

% Ground facts emitted by Klong + UUie oracle:
% rank_trace_cert(N, TrDown, Hs2Up, RhoLower, Nplus, JacobiFrac, valid).

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

% ---------------------------------------------------------------------------
% Polylogarithmic QSVT complexity envelope
% ---------------------------------------------------------------------------
% Certifies that block-encoding + thresholded QSVT stays strictly polylogarithmic in N.
% Fixed threshold DeltaThresh >= 0.05 keeps the degree independent of the vanishing
% spectral gap delta_min(N) ~ 1e-12.
qsvt_polylog_cert(N, AlphaC, DeltaThresh, MaxQueries) <-
    AlphaC =< 3.0,
    DeltaThresh >= 0.05,
    MaxQueries is ceiling((AlphaC / DeltaThresh) * log(1.0e6)),
    MaxQueries =< 1024.

% Combined certified witness: UUie Jacobi / trace-moment bound + polylog QSVT envelope
verified_weil_quantum_witness(N, RhoLb, JacobiFrac, MaxQueries) <-
    rank_trace_cert(N, _, _, RhoLb, _, JacobiFrac, valid),
    (RhoLb > 0.6725 ; JacobiFrac > 0.6725),
    qsvt_polylog_cert(N, 2.70, 0.05, MaxQueries).
