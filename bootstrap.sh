#!/bin/bash
kind create cluster --config cluster.yml

kubectl apply -f .infrastructure/namespace.yml
kubectl apply -f .infrastructure/secret.yml
kubectl apply -f .infrastructure/configMap.yml
kubectl apply -f .infrastructure/clusterIp.yml
kubectl apply -f .infrastructure/statefulSet.yml

kubectl apply -f .infrastructure/namespace-todoapp.yml
kubectl apply -f .infrastructure/app-db-secret.yml
kubectl apply -f .infrastructure/deployment.yml