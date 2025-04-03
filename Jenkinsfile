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

        stage('Run Tests') {
            steps {
                script {
                    // Auth Service Testing
                    dir('auth-service') {
                        sh '''
                        if [ -f "requirements.txt" ]; then
                            pip install -r requirements.txt
                            if [ -d "tests" ]; then
                                pytest tests/
                            else
                                echo "No tests found for auth-service"
                            fi
                        else
                            echo "No requirements.txt found for auth-service"
                        fi
                        '''
                    }

                    // User Service Testing
                    dir('user-service') {
                        sh '''
                        if [ -f "requirements.txt" ]; then
                            pip install -r requirements.txt
                            if [ -d "tests" ]; then
                                pytest tests/
                            else
                                echo "No tests found for user-service"
                            fi
                        else
                            echo "No requirements.txt found for user-service"
                        fi
                        '''
                    }

                    // API Gateway Testing
                    dir('api-gateway') {
                        sh '''
                        if [ -f "requirements.txt" ]; then
                            pip install -r requirements.txt
                            if [ -d "tests" ]; then
                                pytest tests/
                            else
                                echo "No tests found for api-gateway"
                            fi
                        else
                            echo "No requirements.txt found for api-gateway"
                        fi
                        '''
                    }

                    // Analytics Service Testing
                    dir('analytics-service') {
                        sh '''
                        if [ -f "requirements.txt" ]; then
                            pip install -r requirements.txt
                            if [ -d "tests" ]; then
                                pytest tests/
                            else
                                echo "No tests found for analytics-service"
                            fi
                        else
                            echo "No requirements.txt found for analytics-service"
                        fi
                        '''
                    }

                    // Frontend Testing
                    dir('frontend') {
                        sh '''
                        if [ -f "package.json" ]; then
                            npm install
                            if [ -d "tests" ] || [ -d "__tests__" ]; then
                                npm test
                            else
                                echo "No tests found for frontend"
                            fi
                        else
                            echo "No package.json found for frontend"
                        fi
                        '''
                    }
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    // Build Auth Service Image
                    dir('auth-service') {
                        sh "docker build -t ${AUTH_SERVICE_IMAGE}:latest ."
                    }

                    // Build User Service Image
                    dir('user-service') {
                        sh "docker build -t ${USER_SERVICE_IMAGE}:latest ."
                    }

                    // Build API Gateway Image
                    dir('api-gateway') {
                        sh "docker build -t ${API_GATEWAY_IMAGE}:latest ."
                    }

                    // Build Analytics Service Image
                    dir('analytics-service') {
                        sh "docker build -t ${ANALYTICS_SERVICE_IMAGE}:latest ."
                    }

                    // Build Frontend Image
                    dir('frontend') {
                        sh "docker build -t ${FRONTEND_IMAGE}:latest ."
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    // Login to Docker Hub
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                    }

                    // Push all images to Docker Hub
                    sh "docker push ${AUTH_SERVICE_IMAGE}:latest"
                    sh "docker push ${USER_SERVICE_IMAGE}:latest"
                    sh "docker push ${API_GATEWAY_IMAGE}:latest"
                    sh "docker push ${ANALYTICS_SERVICE_IMAGE}:latest"
                    sh "docker push ${FRONTEND_IMAGE}:latest"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                # Apply Kubernetes manifests
                kubectl apply -k k8s/
                
                # Show deployed resources
                echo "Deployments:"
                kubectl get deployments
                
                echo "Services:"
                kubectl get services
                
                echo "Pods:"
                kubectl get pods
                
                echo "Ingress:"
                kubectl get ingress
                '''
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed!"
        }
        always {
            sh 'docker system prune -f'
        }
    }
} 