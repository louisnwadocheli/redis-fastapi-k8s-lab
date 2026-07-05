pipeline {

    agent any

    environment {
        AWS_REGION = 'eu-west-2'
        ECR_REPOSITORY = 'python-api'
        AWS_ACCOUNT_ID = '762810755713'
        IMAGE_NAME = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"

        GIT_USER_NAME = 'jenkins-ci'
        GIT_USER_EMAIL = 'jenkins-ci@example.com'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm

                script {
                    env.IMAGE_TAG = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                }

                echo "Using image tag: ${IMAGE_TAG}"
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build \
                  -t ${ECR_REPOSITORY}:${IMAGE_TAG} .
                """
            }
        }

        stage('Run Tests') {
            steps {
                sh """
                docker run --rm \
                  ${ECR_REPOSITORY}:${IMAGE_TAG} \
                  python -m py_compile app.py
                """
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-ecr'
                ]]) {
                    sh """
                    aws ecr get-login-password \
                    --region ${AWS_REGION} \
                    | docker login \
                      --username AWS \
                      --password-stdin \
                      ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    """
                }
            }
        }

        stage('Push Image to ECR') {
            steps {
                sh """
                docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${IMAGE_NAME}:${IMAGE_TAG}
                docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${IMAGE_NAME}:latest

                docker push ${IMAGE_NAME}:${IMAGE_TAG}
                docker push ${IMAGE_NAME}:latest
                """
            }
        }

        stage('Update Helm Values') {
            steps {
                sh """
                sed -i 's/tag: .*/tag: ${IMAGE_TAG}/' helm/redis-fastapi/values-eks.yaml

                echo "Updated values-eks.yaml:"
                grep -A 5 "image:" helm/redis-fastapi/values-eks.yaml
                """
            }
        }

        stage('Commit and Push Helm Update') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'redis-github-https',
                    usernameVariable: 'GIT_USERNAME',
                    passwordVariable: 'GIT_TOKEN'
                )]) {
                    sh """
                    git config user.name "${GIT_USER_NAME}"
                    git config user.email "${GIT_USER_EMAIL}"

                    git add helm/redis-fastapi/values-eks.yaml

                    git commit -m "Update image tag to ${IMAGE_TAG}" || echo "No changes to commit"

                    git push https://${GIT_USERNAME}:${GIT_TOKEN}@github.com/louisnwadocheli/redis-fastapi-k8s-lab.git HEAD:main
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline Successful"
            echo "Image pushed: ${IMAGE_NAME}:${IMAGE_TAG}"
            echo "Helm values updated with image tag: ${IMAGE_TAG}"
        }

        failure {
            echo "Pipeline Failed"
        }
    }
}