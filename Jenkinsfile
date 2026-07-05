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
                python3 - <<'PY'
from pathlib import Path
import os

image_tag = os.environ["IMAGE_TAG"]
path = Path("helm/redis-fastapi/values-dev.yaml")

lines = path.read_text().splitlines()
new_lines = []

inside_api = False
inside_api_image = False

 for_line_error = False

for line in lines:
    stripped = line.strip()

    if line.startswith("api:"):
        inside_api = True
        inside_api_image = False
        new_lines.append(line)
        continue

    if line.startswith("redis:") or line.startswith("ingress:"):
        inside_api = False
        inside_api_image = False
        new_lines.append(line)
        continue

    if inside_api and stripped == "image:":
        inside_api_image = True
        new_lines.append(line)
        continue

    if inside_api_image and stripped.startswith("tag:"):
        indent = line[:len(line) - len(line.lstrip())]
        new_lines.append(f"{indent}tag: {image_tag}")
        inside_api_image = False
        continue

    new_lines.append(line)

path.write_text("\\n".join(new_lines) + "\\n")
PY

                echo "Updated API image tag only:"
                grep -A 6 "repository: ${IMAGE_NAME}" helm/redis-fastapi/values-dev.yaml || true

                echo "Redis tag should remain 7:"
                grep -A 5 "redis:" helm/redis-fastapi/values-dev.yaml
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

                    git add helm/redis-fastapi/values-dev.yaml

                    git commit -m "Update API image tag to ${IMAGE_TAG}" || echo "No changes to commit"

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
            echo "Helm values updated with API image tag: ${IMAGE_TAG}"
        }

        failure {
            echo "Pipeline Failed"
        }
    }
}