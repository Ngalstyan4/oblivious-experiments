sudo    GOMP_CPU_AFFINITY="1-2" OMP_SCHEDULE=static OMP_NUM_THREADS=2  ./run_cgroup.sh 40m   ./cpp/mmult_eigen_par 42 4096  mat
