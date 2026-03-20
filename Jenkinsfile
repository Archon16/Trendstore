pipeline {
    agent any

    environment {
        DOCKERHUB_USERNAME = "archon16"
        IMAGE_NAME = "trend-app"
        IMAGE_TAG = "latest"
        CONTAINER_NAME = "trend-app"
    }

    stages {

        stage('Install kubectl') {
            steps {
                echo 'Installing kubectl...'
                sh '''
                    if ! command -v kubectl &> /dev/null; then
                        curl -LO "https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl"
                        chmod +x kubectl
                        sudo mv kubectl /usr/local/bin/
                    else
                        echo "kubectl already installed"
                    fi
                    kubectl version --client
                '''
            }
        }

        stage('Configure kubectl') {
            steps {
                echo 'Configuring kubectl for EKS...'
                sh '''
                    aws eks update-kubeconfig --name trend-cluster --region us-east-1
                    kubectl get nodes
                '''
            }
        }

        stage('Checkout') {
            steps {
                echo 'Cloning repository...'
                git branch: 'main',
                    credentialsId: 'github-creds',
                    url: 'https://github.com/archon16/Trendstore.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh 'docker build -t $IMAGE_NAME:$IMAGE_TAG .'
            }
        }

        stage('Push to DockerHub') {
            steps {
                echo 'Pushing to DockerHub...'
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker tag $IMAGE_NAME:$IMAGE_TAG $DOCKER_USER/$IMAGE_NAME:$IMAGE_TAG
                        docker push $DOCKER_USER/$IMAGE_NAME:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying to EKS...'
                withCredentials([file(
                    credentialsId: 'kubeconfig',
                    variable: 'KUBECONFIG'
                )]) {
                    sh '''
                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/service.yaml
                        kubectl rollout status deployment/trend-app
                    '''
                }
            }
        }

    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}