#!/bin/bash

# Function to check if a command exists
check_command() {
  if ! command -v $1 &> /dev/null; then
    echo "❌ $1 command not found! Please install it first."
    exit 1
  fi
}

# Check if required commands exist
check_command kubectl
check_command minikube

# Check if minikube is running
if ! minikube status &>/dev/null; then
  echo "❌ Minikube is not running. Starting minikube..."
  minikube start
fi

# Enable the Ingress addon for Minikube
echo "Enabling NGINX Ingress Controller..."
minikube addons enable ingress

# Wait for the ingress controller to be ready
echo "Waiting for NGINX Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s || echo "⚠️ Ingress controller wait timed out, continuing anyway..."

# Create the k8s directory if it doesn't exist
mkdir -p k8s

# Apply Kubernetes resources
echo "Applying Kubernetes resources..."
kubectl delete -k k8s/
kubectl apply -k k8s/

# Function to wait for pod readiness with improved error handling
wait_for_pod() {
  local app=$1
  local timeout=300
  local start_time=$(date +%s)
  local end_time=$((start_time + timeout))
  local current_time=0
  
  echo "Waiting for $app deployment to be ready (timeout: ${timeout}s)..."
  
  while [ $(date +%s) -lt $end_time ]; do
    if kubectl get deployment $app -o jsonpath='{.status.availableReplicas}' 2>/dev/null | grep -q "1"; then
      echo "✅ $app is ready"
      return 0
    fi
    
    # Show pod status and any issues
    pod_name=$(kubectl get pods -l app=$app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -n "$pod_name" ]; then
      pod_status=$(kubectl get pod $pod_name -o jsonpath='{.status.phase}' 2>/dev/null)
      echo "⏳ $app pod ($pod_name) status: $pod_status"
      
      # If pod is not running, show more details
      if [ "$pod_status" != "Running" ]; then
        echo "📋 Pod events:"
        kubectl describe pod $pod_name | grep -A 10 Events: | tail -n 10
      fi
    else
      echo "⏳ Waiting for $app pod to be created..."
    fi
    
    sleep 10
  done
  
  echo "❌ Timed out waiting for $app"
  return 1
}

# Wait for each service to be ready
wait_for_pod "mysql"
wait_for_pod "auth-service"
wait_for_pod "user-service"
wait_for_pod "analytics-service"
wait_for_pod "api-gateway"
wait_for_pod "frontend"

# Get the Minikube IP
MINIKUBE_IP=$(minikube ip)

echo "Adding the following entry to /etc/hosts to access the application:"
echo "$MINIKUBE_IP microservices.local"
echo "Run the following command with sudo to add it:"
echo "echo \"$MINIKUBE_IP microservices.local\" | sudo tee -a /etc/hosts"

echo
echo "Application deployed on Kubernetes!"
echo "You can access the application at:"
echo "Frontend: http://microservices.local"
echo "API Gateway: http://microservices.local/api"
echo "To check the status of the pods, run: kubectl get pods"
echo

# Create a tunnel in background (optional)
echo "Starting a minikube tunnel to expose services (this will run in the background)..."
minikube tunnel > /dev/null 2>&1 &
TUNNEL_PID=$!
echo "Minikube tunnel started (PID: $TUNNEL_PID)"

# Show application status
echo "Deployed resources:"
kubectl get all

echo
echo "To stop the minikube tunnel, run: kill $TUNNEL_PID"

kubectl edit deployment mysql 