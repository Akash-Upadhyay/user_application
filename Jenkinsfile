pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = "mt2024013"
        AUTH_SERVICE_IMAGE = "${DOCKER_REGISTRY}/auth-service"
        USER_SERVICE_IMAGE = "${DOCKER_REGISTRY}/user-service"
        API_GATEWAY_IMAGE = "${DOCKER_REGISTRY}/api-gateway"
        ANALYTICS_SERVICE_IMAGE = "${DOCKER_REGISTRY}/analytics-service"
        FRONTEND_IMAGE = "${DOCKER_REGISTRY}/frontend"
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/Akash-Upadhyay/user_application.git'
            }
        }


        stage('Build Docker Images') {
            steps {
                sh 'docker build -t ${AUTH_SERVICE_IMAGE} ./auth-service'
                sh 'docker build -t ${USER_SERVICE_IMAGE} ./user-service'
                sh 'docker build -t ${API_GATEWAY_IMAGE} ./api-gateway'
                sh 'docker build -t ${ANALYTICS_SERVICE_IMAGE} ./analytics-service'
                sh 'docker build -t ${FRONTEND_IMAGE} ./frontend'
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withDockerRegistry([credentialsId: 'docker-hub-credentials', url: '']) {
                    sh 'docker push ${AUTH_SERVICE_IMAGE}'
                    sh 'docker push ${USER_SERVICE_IMAGE}'
                    sh 'docker push ${API_GATEWAY_IMAGE}'
                    sh 'docker push ${ANALYTICS_SERVICE_IMAGE}'
                    sh 'docker push ${FRONTEND_IMAGE}'
                }
            }
        }

        stage('Deploy Using Ansible') {
            steps {
                sh 'ansible-playbook -i inventory.ini ansible-playbook.yml'
            }
        }
    }

    post {
        success {
            echo "Build and Deployment Successful!"
        }
        failure {
            echo "Build Failed!"
        }
    }
} 