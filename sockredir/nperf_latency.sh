req_size=32

for i in {1..4}
do
	let "req_size=req_size*2"
	resp_size=64
	for j in {1..9}
	do
		let "resp_size=resp_size*2"
		echo "Req/Resp size: $req_size $resp_size" >> result_lat.txt
	for k in {1..2}
	do
		let "time=30*$k"
		netperf -P 0 -t TCP_RR -H 127.0.0.1 -p 1000 -l $time -- -r $req_size,$resp_size -o P50_LATENCY,P90_LATENCY,P99_LATENCY >> result_lat.txt
		./load.sh
		netperf -P 0 -t TCP_RR -H 127.0.0.1 -p 1000 -l $time -- -r $req_size,$resp_size -o P50_LATENCY,P90_LATENCY,P99_LATENCY >> result_lat.txt
		./unload.sh
	done
	echo "" >> result_lat.txt
	done
done
