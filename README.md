# Microservices Application

This is a simple microservices application with the following components:

## Architecture

| Microservice | Functionality | Database |
|--------------|--------------|----------|
| Auth Service | Handles login & authentication | MySQL (users table) |
| User Service | Stores user profiles | MySQL (users table) |
| Analytics Service | Provides analytics data | No DB |
| API Gateway | Routes requests to appropriate services | No DB |
| Frontend | React-based user interface | No DB |

## Setup Options

### Docker Compose Setup

1. Clone this repository
2. Install Docker and Docker Compose
3. Run `docker-compose up -d` to start all services

### Kubernetes Setup (Minikube)

1. Clone this repository
2. Install Minikube and kubectl
3. Start Minikube: `minikube start`
4. Deploy services to Kubernetes: `./deploy-k8s.sh`
5. Add host entry: `echo "$(minikube ip) microservices.local" | sudo tee -a /etc/hosts`
6. Start tunnel for ingress access: `minikube tunnel`
7. Access the application at http://microservices.local

## Services

### Docker Compose
- Frontend: http://localhost
- API Gateway: http://localhost:8000
- Auth Service: http://localhost:3001
- User Service: http://localhost:3002
- Analytics Service: http://localhost:3004
- MySQL Database: localhost:3306

### Kubernetes
- Frontend: http://microservices.local
- API Gateway: http://microservices.local/api
- Auth Service: http://microservices.local/auth
- User Service: http://microservices.local/user
- Analytics Service: http://microservices.local/analytics

## API Routes (via Gateway)

- Auth Service: `/auth/*`
- User Service: `/users/*`
- Analytics Service: `/analytics/*`

## Tech Stack

- Backend: Python with FastAPI
- Frontend: React with Bootstrap
- Database: MySQL
- ORM: SQLAlchemy
- Container: Docker & Docker Compose
- Orchestration: Kubernetes (optional)

## Deployment Options

### CI/CD Pipeline
The application includes a Jenkinsfile for automating the CI/CD pipeline:
- Code checkout
- Running tests
- Building Docker images
- Pushing to Docker registry
- Deployment using Ansible

### Kubernetes Deployment
The k8s directory contains all necessary manifests for Kubernetes deployment:
- Deployments for all microservices
- Services for internal communication
- Ingress for external access
- Persistent volume for MySQL data

#### Kubernetes Resources
- Deployments & Pods: `kubectl get pods`
- Services: `kubectl get services`
- Ingress: `kubectl get ingress`
- Logs: `kubectl logs <pod-name>`

## Features

- User registration and authentication
- User profile management
- Analytics tracking
- Responsive UI
- Microservices architecture
- Multiple deployment options (Docker Compose, Kubernetes)
- CI/CD pipeline integration 