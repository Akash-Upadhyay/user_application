#!/bin/bash
# Script for Jenkins to deploy to Kubernetes without minikube direct interaction
# Assumes kubectl is configured to talk to a Kubernetes cluster

set -e  # Exit on any error

# Variables
NAMESPACE="default"
K8S_DIR="./k8s"

echo "Starting Kubernetes deployment..."

# Use pre-configured kubectl context
echo "Using current kubectl context"
kubectl config current-context || echo "No kubectl context available"

# Create namespace if it doesn't exist
if ! kubectl get namespace "${NAMESPACE}" &> /dev/null; then
  echo "Creating namespace: ${NAMESPACE}"
  kubectl create namespace "${NAMESPACE}"
fi

# Set context to the namespace
kubectl config set-context --current --namespace="${NAMESPACE}"

# Check if k8s directory exists
if [ ! -d "${K8S_DIR}" ]; then
  echo "Error: Kubernetes directory '${K8S_DIR}' not found"
  exit 1
fi

# Apply all Kubernetes manifests
echo "Applying Kubernetes manifests from ${K8S_DIR}..."
kubectl apply -k "${K8S_DIR}/"

# Wait for pods to be ready
echo "Waiting for pods to become ready..."
kubectl wait --for=condition=available --timeout=300s deployment/mysql || echo "MySQL deployment timeout"
kubectl wait --for=condition=available --timeout=300s deployment/auth-service || echo "Auth service deployment timeout"
kubectl wait --for=condition=available --timeout=300s deployment/user-service || echo "User service deployment timeout"
kubectl wait --for=condition=available --timeout=300s deployment/analytics-service || echo "Analytics service deployment timeout"
kubectl wait --for=condition=available --timeout=300s deployment/api-gateway || echo "API gateway deployment timeout"
kubectl wait --for=condition=available --timeout=300s deployment/frontend || echo "Frontend deployment timeout"

# Show pod status
echo "Pod status:"
kubectl get pods

# Show services
echo "Services:"
kubectl get services

# Show ingress
echo "Ingress:"
kubectl get ingress

echo "Deployment complete!"
echo "Note: If using minikube, remember to:"
echo "1. Run 'minikube tunnel' on the host machine"
echo "2. Add minikube IP to /etc/hosts as 'microservices.local'" 