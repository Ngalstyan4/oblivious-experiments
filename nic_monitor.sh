t0=$(($(date +%s%N)/1000000))
xmit0=$(cat "/sys/class/infiniband/mlx4_0/ports/1/counters/port_xmit_data");
while true; do
	xmit=$(cat "/sys/class/infiniband/mlx4_0/ports/1/counters/port_xmit_data");
	xmit=$((($xmit-$xmit0) * 4))
	t=$(($(date +%s%N)/1000000))
	t=$(($t-$t0))
	echo $t,$xmit
	sleep 0.01; done
