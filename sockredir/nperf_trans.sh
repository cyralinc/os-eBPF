req_size=32

for i in {1..4}
do
	let "req_size=req_size*2"
	resp_size=64
	for i in {1..9}
	do
		let "resp_size=resp_size*2"
		echo "Req/Resp size: $req_size $resp_size" >> result_trans.txt
	for i in {1..1}
	do
		let "time=60*$i"
		netperf -t TCP_RR -H 127.0.0.1 -p 1000 -l $time -- -r $req_size,$resp_size | awk 'NR==7 {print $6/1000}' >> result_trans.txt
		./load.sh
		netperf -t TCP_RR -H 127.0.0.1 -p 1000 -l $time -- -r $req_size,$resp_size | awk 'NR==7 {print $6/1000}' >> result_trans.txt
		./unload.sh
	done
	echo "" >> result_trans.txt
	done
done
