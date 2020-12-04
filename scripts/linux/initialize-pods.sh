#!/bin/bash
RUN_TEST_SAMENODE=$1
#creazione daemonset
kubectl apply -f /vagrant/ext/kites/kubernetes/net-test-dev_ds.yaml
sleep 60
#creazione single-pod
if $RUN_TEST_SAMENODE; then
    kubectl apply -f /vagrant/ext/kites/kubernetes/net-test-single-pod.yaml
    sleep 30
fi