#!/bin/bash
# Script to set up Kubernetes cluster with minikube and configure it for Jenkins

set -e  # Exit on any error

# Variables
KUBE_CONFIG_PATH="/var/lib/jenkins/.kube"
JENKINS_USER="jenkins"

# Check for required tools
for cmd in minikube kubectl; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is required but not installed. Please install it first."
        exit 1
    fi
done

# Start minikube if not running
if ! minikube status &>/dev/null; then
    echo "Starting Minikube..."
    minikube start
else
    echo "Minikube is already running."
fi

# Enable ingress addon
echo "Enabling ingress addon..."
minikube addons enable ingress

# Get minikube IP
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# Add minikube IP to /etc/hosts if not already there
if ! grep -q "microservices.local" /etc/hosts; then
    echo "Adding microservices.local to /etc/hosts..."
    echo "$MINIKUBE_IP microservices.local" | sudo tee -a /etc/hosts
else
    echo "microservices.local already in /etc/hosts"
fi

# Configure kubectl for Jenkins
echo "Configuring kubectl for Jenkins..."

# Create .kube directory for Jenkins user if it doesn't exist
sudo mkdir -p ${KUBE_CONFIG_PATH}

# Copy the kubectl config to Jenkins
sudo cp ~/.kube/config ${KUBE_CONFIG_PATH}/
sudo chown -R ${JENKINS_USER}:${JENKINS_USER} ${KUBE_CONFIG_PATH}

# Check if minikube tunnel is running
if ! pgrep -f "minikube tunnel" > /dev/null; then
    echo "Starting minikube tunnel (will run in the background)..."
    nohup minikube tunnel > /dev/null 2>&1 &
    echo "Minikube tunnel started with PID: $!"
else
    echo "Minikube tunnel is already running."
fi

echo "Setup complete! Jenkins should now be able to deploy to Kubernetes."
echo ""
echo "To confirm:"
echo "1. Check if the cluster is accessible: kubectl cluster-info"
echo "2. Verify that the ingress controller is running: kubectl get pods -n ingress-nginx"
echo "3. Ensure Jenkins has the necessary permissions: sudo kubectl auth can-i --as system:serviceaccount:default:default get pods" 