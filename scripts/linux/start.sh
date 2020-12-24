#!/bin/bash
calc() { awk "BEGIN{ printf \"%.2f\n\", $* }"; }
CNI=$1
N=$2
RUN_TEST_TCP="true"
RUN_TEST_UDP="true"
RUN_TEST_SAME="true"
RUN_TEST_SAMENODE="true"
RUN_TEST_DIFF="true"
RUN_TEST_CPU="true"
while [ "$1" != "" ]
do
	arg=$1
	case $arg in
        --test-type|-t)
			shift
			RUN_TEST_TCP="false"
			RUN_TEST_UDP="false"
			for i in $(awk '{gsub(/,/," ");print}' <<< "$1")
			do
				case $i in
					all)
						RUN_TEST_TCP="true"
						RUN_TEST_UDP="true"
						;;
					tcp)
						RUN_TEST_TCP="true"
						;;
					udp)
						RUN_TEST_UDP="true"
						;;
					*) echo "Unknown test '${i}', " ;;
				esac
			done
			echo "Benchmark will run only following tests: ${1}"
			;;
		--configurations|-config)
			shift
			RUN_TEST_SAME="false"
			RUN_TEST_SAMENODE="false"
			RUN_TEST_DIFF="false"
			for i in $(awk '{gsub(/,/," ");print}' <<< "$1")
			do
				case $i in
					all)
						RUN_TEST_SAME="true"
						RUN_TEST_SAMENODE="true"
						RUN_TEST_DIFF="true"
						;;
					samepod)
						RUN_TEST_SAME="true"
						;;
					samenode)
						RUN_TEST_SAMENODE="true"
						;;
					diffnode)
						RUN_TEST_DIFF="true"
						;;
					*) echo "Unknown test '${i}', " ;;
				esac
			done
			echo "Benchmark will run only following configuration: ${1}"
			;;
		--nocpu|-nc)
			RUN_TEST_CPU="false"
			echo "cpu monitoring won't be performed"
			echo "RUN_TEST_CPU=$RUN_TEST_CPU"
		;;
		
    esac
    shift
done

start=`date +%s`
sudo apt install -y sshpass
if $RUN_TEST_CPU; then
	/vagrant/ext/kites/scripts/linux/cpu-monitoring.sh $N "IDLE" 10 "IDLE"
fi
/vagrant/ext/kites/scripts/linux/initialize-net-test.sh $CNI $N $RUN_TEST_UDP $RUN_TEST_SAME $RUN_TEST_SAMENODE $RUN_TEST_DIFF
/vagrant/ext/kites/scripts/linux/make-net-test.sh $N $RUN_TEST_TCP $RUN_TEST_UDP $RUN_TEST_SAME $RUN_TEST_SAMENODE $RUN_TEST_DIFF $RUN_TEST_CPU
/vagrant/ext/kites/scripts/linux/parse-test.sh $CNI $N $RUN_TEST_TCP $RUN_TEST_UDP $RUN_TEST_CPU
end=`date +%s`
exec_time=$(expr $end - $start)
exec_min=$(calc $exec_time/60)
echo "Execution time was $exec_min minutes ($exec_time seconds)."

#echo -e "\n ### REMOVE FILE IN 5 MINUTES ### \n"
#sleep 5m
#/vagrant/ext/kites/scripts/linux/remove-all.sh
