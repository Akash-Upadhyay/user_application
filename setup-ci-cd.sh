#!/bin/bash

# Master script to set up CI/CD pipeline for microservices application
# This script will configure both Jenkins and Kubernetes dependencies

set -e  # Exit on any error

# Variables
JENKINS_PORT=8080
K8S_NAMESPACE="microservices"
DOCKER_USERNAME="mt2024013"  # Replace with your Docker Hub username

# Check for required tools
check_command() {
  if ! command -v "$1" &> /dev/null; then
    echo "Error: $1 is required but not installed. Please install it first."
    exit 1
  fi
}

check_command docker
check_command kubectl
check_command minikube
check_command ansible
check_command java

# 1. Set up Jenkins container if not already running
if ! docker ps | grep -q jenkins; then
  echo "Setting up Jenkins container..."
  
  # Create Jenkins data directory
  mkdir -p jenkins_home
  
  # Run Jenkins container
  docker run -d \
    --name jenkins \
    -p "${JENKINS_PORT}:8080" \
    -p 50000:50000 \
    -v $(pwd)/jenkins_home:/var/jenkins_home \
    -v /var/run/docker.sock:/var/run/docker.sock \
    jenkins/jenkins:lts
  
  # Wait for Jenkins to start
  echo "Waiting for Jenkins to start..."
  until $(curl --output /dev/null --silent --head --fail http://localhost:${JENKINS_PORT}); do
    printf '.'
    sleep 5
  done
  
  # Get initial admin password
  echo "Jenkins initial admin password:"
  docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
  
  echo "Please go to http://localhost:${JENKINS_PORT} to complete Jenkins setup."
  echo "After setup, press Enter to continue with plugin installation."
  read -p ""
  
  # Run Jenkins setup script
  chmod +x jenkins-setup.sh
  ./jenkins-setup.sh
else
  echo "Jenkins is already running."
fi

# 2. Ensure Minikube is running
if ! minikube status &>/dev/null; then
  echo "Starting Minikube..."
  minikube start
else
  echo "Minikube is already running."
fi

# 3. Create Kubernetes namespace if it doesn't exist
if ! kubectl get namespace "${K8S_NAMESPACE}" &>/dev/null; then
  echo "Creating Kubernetes namespace: ${K8S_NAMESPACE}"
  kubectl create namespace "${K8S_NAMESPACE}"
else
  echo "Kubernetes namespace ${K8S_NAMESPACE} already exists."
fi

# 4. Configure Kubernetes context for Jenkins
kubectl config use-context minikube
kubectl config set-context --current --namespace="${K8S_NAMESPACE}"

# 5. Create Kubernetes secrets for Docker registry
echo "Creating Kubernetes secret for Docker registry..."
read -sp "Enter your Docker Hub password: " DOCKER_PASSWORD
echo

kubectl create secret docker-registry docker-registry-credentials \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username="${DOCKER_USERNAME}" \
  --docker-password="${DOCKER_PASSWORD}" \
  --docker-email="${DOCKER_USERNAME}@example.com" \
  --namespace="${K8S_NAMESPACE}" \
  --dry-run=client -o yaml | kubectl apply -f -

# 6. Create or update service account for Jenkins
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: ${K8S_NAMESPACE}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins-admin
subjects:
- kind: ServiceAccount
  name: jenkins
  namespace: ${K8S_NAMESPACE}
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF

# 7. Set up Ansible inventory
echo "Configuring Ansible inventory..."
if [ -f "inventory.ini" ]; then
  echo "Inventory file already exists."
else
  cat > inventory.ini <<EOF
[localhost]
127.0.0.1 ansible_connection=local

[kubernetes_master]
127.0.0.1 ansible_connection=local

[all:vars]
deployment_strategy=kubernetes  # Options: 'ansible', 'kubernetes'
EOF
fi

# 8. Configure Minikube tunnel service
echo "Setting up Minikube tunnel service..."
cat > minikube-tunnel.service <<EOF
[Unit]
Description=Minikube Tunnel Service
After=network.target

[Service]
Type=simple
User=$(whoami)
ExecStart=$(which minikube) tunnel
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "To install the Minikube tunnel as a service, run:"
echo "sudo cp minikube-tunnel.service /etc/systemd/system/"
echo "sudo systemctl daemon-reload"
echo "sudo systemctl enable minikube-tunnel.service"
echo "sudo systemctl start minikube-tunnel.service"

# 9. Verify setup
echo "Verifying setup..."
echo "Jenkins: http://localhost:${JENKINS_PORT}"
echo "Kubernetes cluster: $(kubectl cluster-info | head -n 1)"
echo "Minikube IP: $(minikube ip)"

echo "CI/CD setup complete!"
echo "Next steps:"
echo "1. Complete the Jenkins setup at http://localhost:${JENKINS_PORT}"
echo "2. Set up your GitHub repository with the Jenkinsfile"
echo "3. Configure the Jenkins pipeline to use your GitHub repository"
echo "4. Run the pipeline to deploy your application" 