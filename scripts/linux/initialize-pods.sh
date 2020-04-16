#!/bin/bash
kubectl apply -f /vagrant/kubernetes/kites/net-test_ds.yaml
sleep 60
kubectl apply -f /vagrant/kubernetes/kites/net-test-single-pod.yaml
sleep 30