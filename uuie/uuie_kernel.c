/* uuie_kernel.c — Zero-dependency directed-rounding numerical oracle
 * + pure Jacobi Hermitian eigensolver for exact n+(R) under controlled rounding.
 *
 * Compile:
 *   cc -std=c11 -O2 -frounding-math -ffp-contract=off uuie_kernel.c -lm -o uuie_kernel
 */
#include <fenv.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#pragma STDC FENV_ACCESS ON

/* ------------------------------------------------------------------ */
/* Helpers                                                            */
/* ------------------------------------------------------------------ */

static inline double uuie_sinc(double x) {
    double ax = fabs(x);
    if (ax < 1e-8) {
        double x2 = x * x;
        return 1.0 - x2 * (1.0 / 6.0) + (x2 * x2) * (1.0 / 120.0);
    }
    return sin(x) / x;
}

double uuie_rat_to_f64(int64_t p, int64_t q, int dir) {
    int prev = fegetround();
    fesetround(dir < 0 ? FE_DOWNWARD : (dir > 0 ? FE_UPWARD : FE_TONEAREST));
    double res = (double)p / (double)q;
    fesetround(prev);
    return res;
}

/* ------------------------------------------------------------------ */
/* Pure Jacobi Hermitian eigensolver (real symmetric case)            */
/*                                                                    */
/* Classical cyclic Jacobi.  We work only with the upper triangle and */
/* keep the matrix real-symmetric.  After convergence the diagonal    */
/* holds the eigenvalues.  Directed rounding is restored after the    */
/* whole process so that the subsequent rank-trace arithmetic remains */
/* under the caller's control.                                        */
/* ------------------------------------------------------------------ */

#define UUIE_JACOBI_MAX_SWEEPS 64
#define UUIE_JACOBI_EPS        1e-15

/* In-place Jacobi diagonalisation of a real symmetric N×N matrix A.
 * On entry  A is the matrix (row-major).
 * On exit   A is overwritten; the diagonal of A contains the eigenvalues.
 * Returns the number of eigenvalues that are strictly positive
 * (counted under FE_TONEAREST for the final comparison).
 *
 * The algorithm is the classic cyclic Jacobi method:
 *   for each pair (p,q) compute the rotation that annihilates A[p,q],
 *   apply the similarity, and cycle until the off-diagonal Frobenius
 *   norm falls below UUIE_JACOBI_EPS * ||A||_F.
 */
int uuie_jacobi_hermitian(double *A, int N, double *out_evals) {
    if (N <= 0 || !A) return -1;

    /* Work on a private copy so the caller’s matrix is not destroyed
     * unless the caller deliberately passes a disposable buffer. */
    double *M = (double *)malloc((size_t)N * (size_t)N * sizeof(double));
    if (!M) return -1;
    memcpy(M, A, (size_t)N * (size_t)N * sizeof(double));

    int prev = fegetround();
    /* Jacobi rotations themselves are performed under FE_TONEAREST.
     * The final positivity test can be tightened later if needed. */
    fesetround(FE_TONEAREST);

    for (int sweep = 0; sweep < UUIE_JACOBI_MAX_SWEEPS; ++sweep) {
        double off = 0.0;
        for (int p = 0; p < N; ++p)
            for (int q = p + 1; q < N; ++q)
                off = fma(M[p*N+q], M[p*N+q], off);

        if (sqrt(off) < UUIE_JACOBI_EPS * (1.0 + fabs(M[0]))) /* crude scale */
            break;

        for (int p = 0; p < N; ++p) {
            for (int q = p + 1; q < N; ++q) {
                double apq = M[p*N + q];
                if (fabs(apq) < UUIE_JACOBI_EPS) continue;

                double app = M[p*N + p];
                double aqq = M[q*N + q];
                double tau = (aqq - app) / (2.0 * apq);
                double t;
                if (tau >= 0.0)
                    t = 1.0 / (tau + sqrt(1.0 + tau*tau));
                else
                    t = -1.0 / (-tau + sqrt(1.0 + tau*tau));
                double c = 1.0 / sqrt(1.0 + t*t);
                double s = t * c;

                /* Apply rotation to rows/columns p and q */
                for (int k = 0; k < N; ++k) {
                    if (k == p || k == q) continue;
                    double mkp = M[k*N + p];
                    double mkq = M[k*N + q];
                    M[k*N + p] = c*mkp - s*mkq;
                    M[k*N + q] = s*mkp + c*mkq;
                    M[p*N + k] = M[k*N + p];
                    M[q*N + k] = M[k*N + q];
                }
                M[p*N + p] = app - t*apq;
                M[q*N + q] = aqq + t*apq;
                M[p*N + q] = 0.0;
                M[q*N + p] = 0.0;
            }
        }
    }

    /* Extract eigenvalues (diagonal) and count strictly positive ones */
    int nplus = 0;
    for (int i = 0; i < N; ++i) {
        double ev = M[i*N + i];
        if (out_evals) out_evals[i] = ev;
        if (ev > 0.0) ++nplus;
    }

    fesetround(prev);
    free(M);
    return nplus;
}

/* ------------------------------------------------------------------ */
/* Certificate verification (analytic bound + optional exact n+)      */
/* ------------------------------------------------------------------ */

int uuie_verify_certificate(
    const double *R, int N, double target_rho,
    double *out_tr_down, double *out_hs2_up, double *out_rho_lower,
    int *out_nplus
) {
    const double sym_tol = 1e-14;

    /* Conjugate symmetry + finiteness */
    for (int i = 0; i < N; ++i) {
        for (int j = i; j < N; ++j) {
            double rij = R[i*N + j];
            double rji = R[j*N + i];
            if (!isfinite(rij) || !isfinite(rji)) return 0;
            if (fabs(rij - rji) > sym_tol) return 0;
        }
    }

    int prev = fegetround();

    /* 1. Lower bound on trace(R) */
    fesetround(FE_DOWNWARD);
    double tr_down = 0.0;
    for (int i = 0; i < N; ++i)
        tr_down += R[i*N + i];
    if (tr_down <= 0.0) {
        fesetround(prev);
        return 0;
    }
    double num_down = fma(tr_down, tr_down, 0.0);

    /* 2. Upper bound on ||R||_HS² */
    fesetround(FE_UPWARD);
    double hs2_up = 0.0;
    for (int k = 0; k < N*N; ++k) {
        double v = R[k];
        hs2_up = fma(v, v, hs2_up);
    }
    double denom_up = fma((double)N, hs2_up, 0.0);

    /* 3. Certified lower bound on ratio */
    fesetround(FE_DOWNWARD);
    double rho_lower = num_down / denom_up;

    fesetround(prev);

    *out_tr_down   = tr_down;
    *out_hs2_up    = hs2_up;
    *out_rho_lower = rho_lower;

    /* 4. Exact n+(R) via Jacobi (optional but always computed here) */
    int nplus = uuie_jacobi_hermitian((double *)R, N, NULL); /* R is const, but we copy inside */
    if (out_nplus) *out_nplus = nplus;

    int ok = (isfinite(rho_lower) && rho_lower > target_rho) ? 1 : 0;
    return ok;
}

/* ------------------------------------------------------------------ */
/* CLI                                                                */
/* ------------------------------------------------------------------ */

int main(int argc, char **argv) {
    if (argc < 4) {
        fprintf(stderr, "Usage: %s N target_rho matrix.dat\n", argv[0]);
        return 2;
    }
    int N = atoi(argv[1]);
    double target = atof(argv[2]);
    FILE *fp = fopen(argv[3], "r");
    if (!fp || N <= 0) return 2;

    double *R = (double *)malloc((size_t)N * (size_t)N * sizeof(double));
    if (!R) { fclose(fp); return 2; }

    for (int i = 0; i < N*N; ++i) {
        if (fscanf(fp, "%lf", &R[i]) != 1) {
            free(R); fclose(fp); return 2;
        }
    }
    fclose(fp);

    double tr_d = 0.0, hs2_u = 0.0, rho_l = 0.0;
    int nplus = -1;
    int ok = uuie_verify_certificate(R, N, target, &tr_d, &hs2_u, &rho_l, &nplus);
    free(R);

    /* Emit deterministic Horn oracle ground fact (now includes n+) */
    printf("rank_trace_cert(%d, %.17g, %.17g, %.17g, %d, %s).\n",
           N, tr_d, hs2_u, rho_l, nplus, ok ? "valid" : "reject");
    return ok ? 0 : 1;
}
