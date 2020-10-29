#!/bin/bash
#creazione daemonset
kubectl apply -f /vagrant/ext/kites/kubernetes/net-test-dev_ds.yaml
sleep 60
#creazione single-pod
kubectl apply -f /vagrant/ext/kites/kubernetes/net-test-single-pod.yaml
sleep 30