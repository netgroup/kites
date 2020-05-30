#!/bin/bash
CNI=$1
/vagrant/ext/kites/scripts/linux/initialize-net-test.sh $CNI
/vagrant/ext/kites/scripts/linux/make-net-test.sh
/vagrant/ext/kites/scripts/linux/parse-test.sh $CNI
#/vagrant/ext/kites/scripts/linux/remove-all.sh



