#include <omp.h>
#include <stdio.h>

int main(void) {
    omp_set_dynamic(0);
    omp_set_num_threads(2);
    for (int run = 0; run < 2; run++) {
        int sum = 0;
        int threads = 0;
#pragma omp parallel reduction(+:sum)
        {
#pragma omp single
            threads = omp_get_num_threads();
#pragma omp for
            for (int value = 1; value <= 100; value++) sum += value;
        }
        if (sum != 5050 || threads != 2) {
            fprintf(stderr, "OpenMP run %d failed: sum=%d threads=%d\n", run + 1, sum, threads);
            return 1;
        }
        printf("OpenMP parallel reduction %d PASS\n", run + 1);
    }
    return 0;
}
