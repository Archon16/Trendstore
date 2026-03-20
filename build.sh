#! /bin/bash

IMAGE_NAME="trend-app"
IMAGE_TAG="latest"
DOCKERHUB_USERNAME="archon16"

echo "Building the Docker image..."

docker build -t $IMAGE_NAME:$IMAGE_TAG .
docker tag $IMAGE_NAME:$IMAGE_TAG $DOCKERHUB_USERNAME/$IMAGE_NAME:$IMAGE_TAG

if [ $? -eq 0 ]; then
    echo "Build Successful $IMAGE_NAME:$IMAGE_TAG"
else
    echo "Build Failed"
    exit 1
fi