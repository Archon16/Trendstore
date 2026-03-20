#! /bin/bash

IMAGE_NAME="trend-app"
IMAGE_TAG="latest"

docker compose down

echo "Deploying the Docker image..."

docker compose up -d

if [ $? -eq 0 ]; then
    echo "Deployment Successful"
else
    echo "Deployment Failed"
fi