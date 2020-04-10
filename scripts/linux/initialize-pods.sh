#!/bin/sh
kubectl apply -f /vagrant/kubernetes/kites/net-test_ds.yaml
sleep 45
kubectl apply -f /vagrant/kubernetes/kites/net-test-single-pod.yaml
sleep 5