#!/bin/sh
kubectl delete daemonset net-test-ds
kubectl delete pods net-test-single-pod
watch kubectl get pod -o wide 
