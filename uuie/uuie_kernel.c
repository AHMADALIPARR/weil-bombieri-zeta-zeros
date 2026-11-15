/* uuie_kernel.c — Zero-dependency directed-rounding numerical oracle */
#include <fenv.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#pragma STDC FENV_ACCESS ON

static inline double uuie_sinc(double x) {
    double ax = fabs(x);
    if (ax < 1e-8) {
        double x2 = x * x;
        return 1.0 - x2 * (1.0 / 6.0) + (x2 * x2) * (1.0 / 120.0);
    }
    return sin(x) / x;
}

/* Exact int64 rational p/q -> double with directed rounding (dir < 0: down, dir > 0: up) */
double uuie_rat_to_f64(int64_t p, int64_t q, int dir) {
    int prev = fegetround();
    fesetround(dir < 0 ? FE_DOWNWARD : (dir > 0 ? FE_UPWARD : FE_TONEAREST));
    double res = (double)p / (double)q;
    fesetround(prev);
    return res;
}

/*
 * Computes certified lower bound on rho = (tr R)^2 / (N * ||R||_HS^2)
 * via directed FMA chains, plus conjugate-symmetry & finiteness checks.
 * Returns 1 if valid certificate (rho_lower > target), 0 otherwise.
 */
int uuie_verify_certificate(
    const double *R, int N, double target_rho,
    double *out_tr_down, double *out_hs2_up, double *out_rho_lower
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

    /* 1. Lower bound on trace(R) */
    fesetround(FE_DOWNWARD);
    double tr_down = 0.0;
    for (int i = 0; i < N; ++i) {
        tr_down += R[i * N + i];
    }
    if (tr_down <= 0.0) {
        fesetround(prev);
        return 0;
    }
    double num_down = fma(tr_down, tr_down, 0.0);

    /* 2. Upper bound on ||R||_HS^2 = sum_{i,j} R_ij^2 */
    fesetround(FE_UPWARD);
    double hs2_up = 0.0;
    for (int k = 0; k < N * N; ++k) {
        double v = R[k];
        hs2_up = fma(v, v, hs2_up);
    }
    double denom_up = fma((double)N, hs2_up, 0.0);

    /* 3. Certified lower bound on ratio */
    fesetround(FE_DOWNWARD);
    double rho_lower = num_down / denom_up;

    fesetround(prev);

    *out_tr_down = tr_down;
    *out_hs2_up = hs2_up;
    *out_rho_lower = rho_lower;

    return (isfinite(rho_lower) && rho_lower > target_rho) ? 1 : 0;
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
        if (fscanf(fp, "%lf", &R[i]) != 1) {
            free(R);
            fclose(fp);
            return 2;
        }
    }
    fclose(fp);

    double tr_d = 0.0, hs2_u = 0.0, rho_l = 0.0;
    int ok = uuie_verify_certificate(R, N, target, &tr_d, &hs2_u, &rho_l);
    free(R);

    /* Emit deterministic Horn oracle ground fact */
    printf("rank_trace_cert(%d, %.17g, %.17g, %.17g, %s).\n",
           N, tr_d, hs2_u, rho_l, ok ? "valid" : "reject");
    return ok ? 0 : 1;
}
