pipeline {

    agent any

    environment {
        AWS_REGION = 'eu-west-2'
        ECR_REPOSITORY = 'python-api'
        AWS_ACCOUNT_ID = '762810755713'
        IMAGE_NAME = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"
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

        stage('Push Image') {
            steps {

                sh """
                docker tag \
                  ${ECR_REPOSITORY}:${IMAGE_TAG} \
                  ${IMAGE_NAME}:${IMAGE_TAG}

                docker push \
                  ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

    }

    post {

        success {
            echo "Pipeline Successful"
            echo "Image pushed: ${IMAGE_NAME}:${IMAGE_TAG}"
        }

        failure {
            echo "Pipeline Failed"
        }

    }

}