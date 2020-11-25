#!/bin/bash
CNI=$1
N=$2
RUN_TEST_TCP="true"
RUN_TEST_UDP="true"

while [ "$1" != "" ]
do
	arg=$1
	case $arg in
        --only-tests|-ot)
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
					*) echo "Unknown test slug '${i}', " ;;
				esac
			done
			echo "Benchmark will run only following tests: ${1}"
			;;
    esac
    shift
done

start=`date +%s`
/vagrant/ext/kites/scripts/linux/cpu-monitoring.sh $N 
/vagrant/ext/kites/scripts/linux/initialize-net-test.sh $CNI $N $RUN_TEST_UDP
/vagrant/ext/kites/scripts/linux/make-net-test.sh $N $RUN_TEST_TCP $RUN_TEST_UDP
/vagrant/ext/kites/scripts/linux/parse-test.sh $CNI $N $RUN_TEST_TCP $RUN_TEST_UDP
end=`date +%s`
echo "Execution time was $(expr $end - $start) seconds."
#echo -e "\n ### REMOVE FILE IN 5 MINUTES ### \n"
#sleep 5m
#/vagrant/ext/kites/scripts/linux/remove-all.sh
