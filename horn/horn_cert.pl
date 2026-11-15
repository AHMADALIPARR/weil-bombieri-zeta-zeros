% horn_cert.pl — SLD-resolution witness constructor for simple_critical(Rho)
:- op(1200, xfx, '<-').

prove(true, trivial).
prove((A, B), pair(PA, PB)) :- prove(A, PA), prove(B, PB).
prove(Goal, Term) :-
    (Goal <- Body),
    prove(Body, SubProof),
    Goal =.. [Pred | _],
    atom_concat(Pred, '_intro', Ctor),
    Term =.. [Ctor, SubProof].

% Ground facts emitted by Klong + UUie oracle (now includes n+):
% window(psi_0). unit_band(psi_0). grid_equispaced(grid_0, 128).
% compression(psi_0, grid_0, r_0). conjugate_sym(r_0). stable(r_0).
% rank_trace_cert(N, TrDown, Hs2Up, RhoLower, Nplus, valid).

simple_critical(RhoLower) <-
    compression(Psi, Grid, R),
    unit_band(Psi),
    conjugate_sym(R),
    stable(R),
    rank_trace_cert(_, _, _, RhoLower, _, valid),
    RhoLower > 0.6725.

% Stronger certificate that also demands a sufficient exact positive-eigenvalue count
simple_critical_exact(RhoLower, Nplus, N) <-
    compression(Psi, Grid, R),
    unit_band(Psi),
    conjugate_sym(R),
    stable(R),
    rank_trace_cert(N, _, _, RhoLower, Nplus, valid),
    RhoLower > 0.6725,
    Nplus > 0.6725 * N.

distinct(RhoD) <-
    simple_critical(RhoS),
    RhoD is (3.0 - (1.0 / RhoS)) / 2.0,
    RhoD > 0.8333333333333334.
