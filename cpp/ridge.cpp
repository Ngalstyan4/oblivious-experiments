#include <iostream>
#include <Eigen>
#include <unistd.h>
#include <string>
#include "mem_pattern_trace.h"

// taken from https://github.com/pconstr/eigen-ridge/blob/master/eigen_ridge.hpp
template <typename M, typename V, typename P>
M ridge(const M& A, const V& y, P alpha) {
	const auto& svd =
	    A.jacobiSvd(Eigen::ComputeFullU | Eigen::ComputeFullV);
	const auto& s = svd.singularValues();
	const auto r = s.rows();
	const auto& D =
	    s.cwiseQuotient((s.array().square() + alpha).matrix()).asDiagonal();
	return svd.matrixV().leftCols(r) * D *
	       svd.matrixU().transpose().topRows(r) * y;
}

int main(int argc, char *argv[])
{
    if (argc < 3) {
        std::cout << "Invocation: ./mmult_eigen <seed> <matrix_dim> <mat|vec|dot>" << std::endl;
        exit(-1);
    }
    const int MATRIX_DIM = atoi(argv[2]);

    {
    srand(atoi(argv[1]));
    std::cout << "starting!" << std::endl;
    syscall(mem_pattern_trace, TRACE_START | TRACE_AUTO);

    Eigen::MatrixXd X = Eigen::MatrixXd::Random(MATRIX_DIM, MATRIX_DIM);
    Eigen::VectorXd v = Eigen::VectorXd::Random(MATRIX_DIM);

    // Multiplying matrix a and b and storing in array mult
    Eigen::VectorXd theta;
    theta.noalias() = ridge(X, v, 0.01);
    std::cout << theta.sum() << std::endl;
    std::cout << "done, waiting for kernel cleanup" << std::endl;
    }
    syscall(mem_pattern_trace, TRACE_END);
    return 0;
}
