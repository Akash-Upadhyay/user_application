#!/bin/bash
# Fix permissions for Jenkins to access minikube certs

# Make minikube directory readable
sudo chmod -R 755 /home/akash/.minikube

# Make certificate files readable 
sudo chmod 644 /home/akash/.minikube/ca.crt
sudo chmod 644 /home/akash/.minikube/profiles/minikube/client.crt
sudo chmod 644 /home/akash/.minikube/profiles/minikube/client.key

# Check Jenkins user
JENKINS_USER=$(ps -o user= -p $(pgrep jenkins) | head -n 1)
if [ -z "$JENKINS_USER" ]; then
  JENKINS_USER="jenkins"  # Default if not found
fi
echo "Jenkins appears to be running as user: $JENKINS_USER"

# Copy kube config to Jenkins user home
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp /home/akash/.kube/config /var/lib/jenkins/.kube/config
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube

# Also make .kube directory in jenkins home readable
sudo chmod -R 755 /var/lib/jenkins/.kube

# Create symbolic links so Jenkins can find minikube certs
sudo mkdir -p /var/lib/jenkins/.minikube
sudo ln -sf /home/akash/.minikube/ca.crt /var/lib/jenkins/.minikube/ca.crt
sudo mkdir -p /var/lib/jenkins/.minikube/profiles/minikube
sudo ln -sf /home/akash/.minikube/profiles/minikube/client.crt /var/lib/jenkins/.minikube/profiles/minikube/client.crt
sudo ln -sf /home/akash/.minikube/profiles/minikube/client.key /var/lib/jenkins/.minikube/profiles/minikube/client.key
sudo chown -R jenkins:jenkins /var/lib/jenkins/.minikube

echo "Permissions fixed for Jenkins to access Kubernetes"
echo "Make sure to restart Jenkins if needed: sudo systemctl restart jenkins" 