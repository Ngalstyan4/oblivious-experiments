#!/usr/bin/env bash

#./leap_benchmark.sh mmult_eigen mmult_eigen taskset -c 0 ./cpp/mmult_eigen 4 4096 mat
#GOMP_CPU_AFFINITY="0-1" OMP_SCHEDULE=static OMP_NUM_THREADS=2 ./leap_benchmark.sh mmult_eigen_par_2 mmult_eigen_par ./cpp/mmult_eigen_par 4 4096 mat
#GOMP_CPU_AFFINITY="0-2" OMP_SCHEDULE=static OMP_NUM_THREADS=3 ./leap_benchmark.sh mmult_eigen_par_3 mmult_eigen_par ./cpp/mmult_eigen_par 4 4096 mat
#GOMP_CPU_AFFINITY="0-3" OMP_SCHEDULE=static OMP_NUM_THREADS=4 ./leap_benchmark.sh mmult_eigen_par_4 mmult_eigen_par ./cpp/mmult_eigen_par 4 4096 mat

#./leap_benchmark.sh mmult_eigen_vec mmult_eigen_vec taskset -c 0 ./cpp/mmult_eigen_vec 4 16384 vec
#./leap_benchmark.sh mmult_eigen_dot mmult_eigen_dot taskset -c 0 ./cpp/mmult_eigen_dot 4 134217728 dot
./leap_benchmark.sh sort_merge sort_merge taskset -c 0 ./cpp/sort_merge 42 268435456 bitonic_merge false
#./leap_benchmark.sh sparse_eigen sparse_eigen taskset -c 0 ./cpp/sparse_eigen 4 5500 false
