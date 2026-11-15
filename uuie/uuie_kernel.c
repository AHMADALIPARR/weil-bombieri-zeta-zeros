/* uuie_kernel.c — Directed-rounding trace-moment & Jacobi Hermitian eigensolver
 *
 * Zero-dependency C11. Compile:
 *   cc -std=c11 -O2 -frounding-math -ffp-contract=off uuie_kernel.c -lm -o uuie_kernel
 */
#include <fenv.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#pragma STDC FENV_ACCESS ON

static inline double uuie_sinc(double x) {
    double ax = fabs(x);
    if (ax < 1e-8) {
        double x2 = x * x;
        return 1.0 - x2 * (1.0 / 6.0) + (x2 * x2) * (1.0 / 120.0);
    }
    return sin(x) / x;
}

/*
 * Classic cyclic Jacobi Hermitian (real-symmetric) eigensolver.
 * Computes eigenvalues of A (N x N) and returns a certified count n+(R)
 * of eigenvalues strictly exceeding a Gershgorin/roundoff safety margin.
 */
int uuie_jacobi_nplus(const double *R, int N, double *out_min_pos_eig) {
    double *A = (double *)malloc((size_t)N * (size_t)N * sizeof(double));
    if (!A) return -1;
    memcpy(A, R, (size_t)N * (size_t)N * sizeof(double));

    const int max_sweeps = 100;
    const double eps = 1e-14;

    for (int sweep = 0; sweep < max_sweeps; ++sweep) {
        double off_norm = 0.0;
        for (int p = 0; p < N - 1; ++p) {
            for (int q = p + 1; q < N; ++q) {
                double apq = A[p * N + q];
                off_norm += apq * apq;
            }
        }
        if (sqrt(2.0 * off_norm) < eps) break;

        for (int p = 0; p < N - 1; ++p) {
            for (int q = p + 1; q < N; ++q) {
                double apq = A[p * N + q];
                if (fabs(apq) <= eps * 1e-2) continue;

                double app = A[p * N + p];
                double aqq = A[q * N + q];
                double tau = (aqq - app) / (2.0 * apq);
                double t = (tau >= 0.0)
                    ? (1.0 / (tau + sqrt(1.0 + tau * tau)))
                    : (-1.0 / (-tau + sqrt(1.0 + tau * tau)));
                double c = 1.0 / sqrt(1.0 + t * t);
                double s = t * c;

                A[p * N + p] = app - t * apq;
                A[q * N + q] = aqq + t * apq;
                A[p * N + q] = 0.0;
                A[q * N + p] = 0.0;

                for (int r = 0; r < N; ++r) {
                    if (r == p || r == q) continue;
                    double arp = A[r * N + p];
                    double arq = A[r * N + q];
                    A[r * N + p] = c * arp - s * arq;
                    A[p * N + r] = A[r * N + p];
                    A[r * N + q] = s * arp + c * arq;
                    A[q * N + r] = A[r * N + q];
                }
            }
        }
    }

    /* Directed-rounding residual Gershgorin certification margin */
    int prev = fegetround();
    fesetround(FE_UPWARD);
    double max_off_row = 0.0;
    for (int i = 0; i < N; ++i) {
        double row_sum = 0.0;
        for (int j = 0; j < N; ++j) {
            if (i != j) row_sum += fabs(A[i * N + j]);
        }
        /* Include IEEE-754 backward Jacobi perturbation bound */
        double safety = fma((double)N * 2.220446049250313e-16,
                            fabs(A[i * N + i]) + row_sum, row_sum);
        if (safety > max_off_row) max_off_row = safety;
    }

    fesetround(FE_DOWNWARD);
    int nplus = 0;
    double min_pos = INFINITY;
    for (int i = 0; i < N; ++i) {
        double cert_eig = A[i * N + i] - max_off_row;
        if (cert_eig > 0.0) {
            nplus++;
            if (cert_eig < min_pos) min_pos = cert_eig;
        }
    }
    fesetround(prev);

    free(A);
    *out_min_pos_eig = (nplus > 0) ? min_pos : 0.0;
    return nplus;
}

int uuie_verify_certificate(
    const double *R, int N, double target_rho,
    double *out_tr_down, double *out_hs2_up, double *out_rho_lower,
    int *out_nplus, double *out_jacobi_frac
) {
    const double sym_tol = 1e-14;
    for (int i = 0; i < N; ++i) {
        for (int j = i; j < N; ++j) {
            double rij = R[i * N + j];
            double rji = R[j * N + i];
            if (!isfinite(rij) || !isfinite(rji)) return 0;
            if (fabs(rij - rji) > sym_tol) return 0;
        }
    }

    int prev = fegetround();

    fesetround(FE_DOWNWARD);
    double tr_down = 0.0;
    for (int i = 0; i < N; ++i) tr_down += R[i * N + i];
    if (tr_down <= 0.0) { fesetround(prev); return 0; }
    double num_down = fma(tr_down, tr_down, 0.0);

    fesetround(FE_UPWARD);
    double hs2_up = 0.0;
    for (int k = 0; k < N * N; ++k) {
        double v = R[k];
        hs2_up = fma(v, v, hs2_up);
    }
    double denom_up = fma((double)N, hs2_up, 0.0);

    fesetround(FE_DOWNWARD);
    double rho_lower = num_down / denom_up;
    fesetround(prev);

    double min_pos_eig = 0.0;
    int nplus = uuie_jacobi_nplus(R, N, &min_pos_eig);
    if (nplus < 0) return 0;

    fesetround(FE_DOWNWARD);
    double jacobi_frac = (double)nplus / (double)N;
    fesetround(prev);

    *out_tr_down = tr_down;
    *out_hs2_up = hs2_up;
    *out_rho_lower = rho_lower;
    *out_nplus = nplus;
    *out_jacobi_frac = jacobi_frac;

    return (isfinite(rho_lower) && (rho_lower > target_rho || jacobi_frac > target_rho)) ? 1 : 0;
}

int main(int argc, char **argv) {
    if (argc < 4) return 2;
    int N = atoi(argv[1]);
    double target = atof(argv[2]);
    FILE *fp = fopen(argv[3], "r");
    if (!fp || N <= 0) return 2;

    double *R = (double *)malloc((size_t)N * (size_t)N * sizeof(double));
    if (!R) { fclose(fp); return 2; }

    for (int i = 0; i < N * N; ++i) {
        if (fscanf(fp, "%lf", &R[i]) != 1) { free(R); fclose(fp); return 2; }
    }
    fclose(fp);

    double tr_d = 0.0, hs2_u = 0.0, rho_l = 0.0, j_frac = 0.0;
    int nplus = 0;
    int ok = uuie_verify_certificate(R, N, target, &tr_d, &hs2_u, &rho_l, &nplus, &j_frac);
    free(R);

    printf("rank_trace_cert(%d, %.17g, %.17g, %.17g, %d, %.17g, %s).\n",
           N, tr_d, hs2_u, rho_l, nplus, j_frac, ok ? "valid" : "reject");
    return ok ? 0 : 1;
}
