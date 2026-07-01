#!/bin/bash

set -e

echo "Deleting Python API resources..."
kubectl delete -f k8s/service.yaml --ignore-not-found
kubectl delete -f k8s/deployment.yaml --ignore-not-found

echo "Deleting Redis resources..."
kubectl delete -f k8s/redis-service.yaml --ignore-not-found
kubectl delete -f k8s/redis-deployment.yaml --ignore-not-found
kubectl delete -f k8s/redis-pvc.yaml --ignore-not-found
kubectl delete -f k8s/redis-secret.yaml --ignore-not-found
kubectl delete -f k8s/redis-configmap.yaml --ignore-not-found

echo "Cleanup complete."
