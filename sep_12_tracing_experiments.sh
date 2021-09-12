#!/bin/bash
#args:./benchmark.sh [results_dir] [RSS_in_pages]             [command to run in cgroup under memory pressure]

WORKLOAD=mmult_eigen
if [[ ! -d /mydata/traces ]]
then
	mkdir -p /mydata/traces
	sudo mkdir -p /data/
	sudo chown $USER -R /data
	ln -s /mydata/traces /data/traces
fi

echo "WORKLOAD,US_SIZE,PS_PERCENT,PS_SIZE_100,PS_SIZE_50,PS_SIZE_30,PS_SIZE_20,PS_SIZE_10" | sudo tee ./experiment_results/$WORKLOAD/tape_sizes.csv
for us_size in 2 {10..100..20}
do
	sudo rm -rf /data/traces/*
	for ps_percent in {100..10..10}
	do
		# remove only postprocessed files if us_size did not change
		if [ -d /data/traces/$WORKLOAD ]
		then
			pushd /data/traces/$WORKLOAD
				ls | grep -v main.bin| sudo xargs rm -rf
			popd
		fi
		yes | sudo SKIP_LINUX=true US=$us_size POSTPROCESS_PERCENT=$ps_percent RATIOS="30 20 10" ./benchmark.sh $WORKLOAD 101394 taskset -c 0 ./cpp/$WORKLOAD 4 4096 mat
		mv ./experiment_results/$WORKLOAD ./experiment_results/$WORKLOAD_us_size_$ps_percent
		TRACE_SIZE=$(stat -c %s "/data/traces/$WORKLOAD/main.bin.0")
		PS_SIZE_100=$(stat -c %s "/data/traces/$WORKLOAD/100/main.tape.0")
		PS_SIZE_50=$(stat -c %s "/data/traces/$WORKLOAD/50/main.tape.0")
		PS_SIZE_30=$(stat -c %s "/data/traces/$WORKLOAD/30/main.tape.0")
		PS_SIZE_20=$(stat -c %s "/data/traces/$WORKLOAD/20/main.tape.0")
		PS_SIZE_10=$(stat -c %s "/data/traces/$WORKLOAD/10/main.tape.0")
		echo $WORKLOAD,$us_size,$ps_percent,$PS_SIZE_100,$PS_SIZE_50,$PS_SIZE_30,$PS_SIZE_20,$PS_SIZE_10 | sudo tee --append ./experiment_results/$WORKLOAD/tape_sizes.csv
	done
done

