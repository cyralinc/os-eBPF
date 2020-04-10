msg_size=128
for i in {1..20}
do
	if [ $msg_size -ge 1024 ]; then
		let "msg_size=msg_size+1024"
	else
		let "msg_size=msg_size*2"
	fi
	for j in {1..2}
	do
		let "time=30*$j"
		let "rx_size=$msg_size"
		echo "$time tx=$msg_size rx=$rx_size" >> result_tp.txt
		netperf -H 127.0.0.1 -p 1000 -l $time -- -m $msg_size -M $rx_size -D | awk 'NR==7 {print $5/1000}' >> result_tp.txt
		./load.sh
		netperf -H 127.0.0.1 -p 1000 -l $time -- -m $msg_size -M $rx_size | awk 'NR==7 {print $5/1000}' >> result_tp.txt
		./unload.sh
	done
	echo "" >> result_tp.txt
done
