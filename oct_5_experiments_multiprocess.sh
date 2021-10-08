#!/bin/bash
#args:./benchmark.sh [results_dir] [RSS_in_pages]             [command to run in cgroup under memory pressure]

if [[ ! -d /mydata/traces ]]
then
	mkdir -p /mydata/traces
	sudo mkdir -p /data/
	sudo chown $USER -R /data
	ln -s /mydata/traces /data/traces
fi

sudo rm -rf /data/traces/*

EXP_RATIOS="100 90 80 70 60 50 40 30 20"
for n in 7 8 9 10 11 6 5 4 3 2 1
do
	for ratio in $EXP_RATIOS
	do
		export NUM_PROCS=$n
		export CPUS=`seq 0 19`
		if [ $ratio = "100" ]
		then
			export PUT_HEADER=1
		else
			export PUT_HEADER=0
		fi
		export RATIOS=$ratio

		#sudo rm -rf /data/traces/*
		yes | sudo  ./benchmark.sh python 107903 ~/miniconda3/bin/python python/mmult.py 4 4096 mat

		#sudo rm -rf /data/traces/*
		yes | sudo ./benchmark.sh mmult_eigen 101394 ./cpp/mmult_eigen 4 4096 mat

		#sudo rm -rf /data/traces/*
		yes | sudo ./benchmark.sh mmult_eigen_vec 524718 ./cpp/mmult_eigen_vec 4 16384 vec

		#sudo rm -rf /data/traces/*
		yes | sudo ./benchmark.sh mmult_eigen_dot 524652 ./cpp/mmult_eigen_dot 4 134217728 dot

		#sudo rm -rf /data/traces/*
		yes | sudo ./benchmark.sh sparse_eigen 296292 ./cpp/sparse_eigen 4 5500 false

	done

	sudo mv experiment_results experiment_results_nproc_$NUM_PROCS
done

exit

sudo rm -rf /data/traces/*

for n in 1 2 3 4 5 6
do
	for ratio in $EXP_RATIOS
	do
		export NUM_PROCS=$n
		export CPUS=`seq 0 19`
		if [ $ratio = "100" ]
		then
			export PUT_HEADER=1
		else
			export PUT_HEADER=0
		fi
		yes | sudo PROG_NAME=python ./benchmark.sh pyfft 1055762 ~/miniconda3/bin/python python/fft.py 0 67108864

	done
	sudo mv experiment_results experiment_results_fft_nproc_$NUM_PROCS
done


