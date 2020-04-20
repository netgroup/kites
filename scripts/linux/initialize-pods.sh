#!/bin/bash
kubectl apply -f /vagrant/ext/kites/kubernetes/net-test_ds.yaml
sleep 60
kubectl apply -f /vagrant/ext/kites/kubernetes/net-test-single-pod.yaml
sleep 30