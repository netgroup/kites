#!/bin/sh
CNI=$1
/vagrant/ext/kites/scripts/linux/initialize-net-test.sh
/vagrant/ext/kites/scripts/linux/make-net-test.sh
/vagrant/ext/kites/scripts/linux/parse-test.sh $CNI
