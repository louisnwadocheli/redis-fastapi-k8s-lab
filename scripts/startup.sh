#!/bin/bash

set -e

echo "Applying Redis ConfigMap..."
kubectl apply -f k8s/redis-configmap.yaml

echo "Applying Redis Secret..."
kubectl apply -f k8s/redis-secret.yaml

echo "Applying Redis PVC..."
kubectl apply -f k8s/redis-pvc.yaml

echo "Deploying Redis..."
kubectl apply -f k8s/redis-deployment.yaml

echo "Creating Redis Service..."
kubectl apply -f k8s/redis-service.yaml

echo "Deploying Python API..."
kubectl apply -f k8s/deployment.yaml

echo "Creating Python API ClusterIP Service..."
kubectl apply -f k8s/service.yaml

echo "Creating Ingress..."
kubectl apply -f k8s/ingress.yaml

echo "Waiting for Redis deployment..."
kubectl rollout status deployment/redis

echo "Waiting for Python API deployment..."
kubectl rollout status deployment/python-api

echo "Current Pods:"
kubectl get pods

echo "Current Services:"
kubectl get svc

echo "Current Ingress:"
kubectl get ingress

echo "Deployment complete."
echo "Test with:"
echo "curl http://localhost:8080/api/"