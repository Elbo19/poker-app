#!/bin/bash

# Poker App GKE Deployment Script
# This script automates the deployment of the poker application to Google Kubernetes Engine

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Poker App GKE Deployment Script${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""

# Check if required tools are installed
command -v gcloud >/dev/null 2>&1 || { echo -e "${RED}Error: gcloud is not installed${NC}" >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}Error: kubectl is not installed${NC}" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Error: docker is not installed${NC}" >&2; exit 1; }

# Get project configuration
echo -e "${YELLOW}Please enter your GCP Project ID:${NC}"
read -r PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: Project ID cannot be empty${NC}"
    exit 1
fi

REGION="${REGION:-us-central1}"
CLUSTER_NAME="${CLUSTER_NAME:-poker-cluster}"
IMAGE_NAME="us-central1-docker.pkg.dev/$PROJECT_ID/poker-repo/poker-backend:latest"

echo ""
echo -e "${GREEN}Configuration:${NC}"
echo "  Project ID: $PROJECT_ID"
echo "  Zone: ${REGION}-a (zonal deployment)"
echo "  Cluster: $CLUSTER_NAME"
echo "  Machine Type: e2-small (2 vCPUs, 2GB RAM)"
echo "  Nodes: 2 (fits within 12 CPU quota)"
echo "  Image: $IMAGE_NAME"
echo ""

# Set project
echo -e "${YELLOW}Setting GCP project...${NC}"
gcloud config set project "$PROJECT_ID"

# Enable APIs
echo -e "${YELLOW}Enabling required GCP APIs...${NC}"
gcloud services enable container.googleapis.com artifactregistry.googleapis.com

# Check if cluster exists
ZONE="${REGION}-a"  # Use single zone to reduce resource usage
if gcloud container clusters describe "$CLUSTER_NAME" --zone="$ZONE" &>/dev/null; then
    echo -e "${GREEN}Cluster $CLUSTER_NAME already exists${NC}"
else
    echo -e "${YELLOW}Creating GKE cluster (zonal, fits within 12 CPU quota)...${NC}"
    gcloud container clusters create "$CLUSTER_NAME" \
        --zone "$ZONE" \
        --num-nodes 2 \
        --machine-type e2-small \
        --enable-autoscaling \
        --min-nodes 1 \
        --max-nodes 5 \
        --scopes=https://www.googleapis.com/auth/cloud-platform
fi

# Get cluster credentials
echo -e "${YELLOW}Getting cluster credentials...${NC}"
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE"

# Ensure Artifact Registry repository exists
echo -e "${YELLOW}Ensuring Artifact Registry repository exists...${NC}"
if ! gcloud artifacts repositories describe poker-repo --location=us-central1 &>/dev/null; then
    gcloud artifacts repositories create poker-repo \
        --repository-format=docker \
        --location=us-central1 \
        --description="Docker repository for poker app"
fi

# Build Docker image
echo -e "${YELLOW}Building Docker image for amd64...${NC}"
cd backend
docker build --platform linux/amd64 -t poker-backend:latest .
cd ..

# Tag and push image to Artifact Registry
echo -e "${YELLOW}Tagging and pushing image to Artifact Registry...${NC}"
gcloud auth configure-docker us-central1-docker.pkg.dev --quiet
docker tag poker-backend:latest "$IMAGE_NAME"
docker push "$IMAGE_NAME"

# Update deployment.yaml with project ID
echo -e "${YELLOW}Updating Kubernetes deployment manifest...${NC}"
sed "s/YOUR_PROJECT_ID/$PROJECT_ID/g" k8s/deployment.yaml > k8s/deployment-updated.yaml

# Deploy to Kubernetes
echo -e "${YELLOW}Deploying to Kubernetes...${NC}"
kubectl apply -f k8s/deployment-updated.yaml

# Wait for deployment
echo -e "${YELLOW}Waiting for deployment to complete...${NC}"
kubectl rollout status deployment/poker-backend

# Get service details
echo -e "${YELLOW}Waiting for external IP...${NC}"
echo "This may take a few minutes..."

EXTERNAL_IP=""
while [ -z "$EXTERNAL_IP" ]; do
    EXTERNAL_IP=$(kubectl get service poker-backend-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    [ -z "$EXTERNAL_IP" ] && sleep 10
done

echo ""
echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""
echo -e "${GREEN}Your API is now available at:${NC}"
echo -e "${YELLOW}http://$EXTERNAL_IP${NC}"
echo ""
echo -e "${GREEN}Test your deployment:${NC}"
echo "  curl http://$EXTERNAL_IP/health"
echo ""
echo -e "${GREEN}View resources:${NC}"
echo "  kubectl get pods"
echo "  kubectl get services"
echo "  kubectl get hpa"
echo ""
echo -e "${GREEN}View logs:${NC}"
echo "  kubectl logs -f deployment/poker-backend"
echo ""
echo -e "${YELLOW}Update your Flutter app${NC} lib/main.dart with:"
echo "  final String apiUrl = 'http://$EXTERNAL_IP';"
echo ""
echo -e "${GREEN}Run load tests:${NC}"
echo "  export API_URL=http://$EXTERNAL_IP"
echo "  k6 run loadtest/load-test.js"
echo ""
