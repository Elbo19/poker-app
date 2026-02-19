#!/bin/bash

# Poker App Frontend GKE Deployment Script
# This script deploys the Flutter web frontend to Google Kubernetes Engine

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}Poker App Frontend GKE Deployment Script${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# Check if required tools are installed
command -v gcloud >/dev/null 2>&1 || { echo -e "${RED}Error: gcloud is not installed${NC}" >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}Error: kubectl is not installed${NC}" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Error: docker is not installed${NC}" >&2; exit 1; }

# Configuration
PROJECT_ID="pocker-487519"
REGION="us-central1"
ZONE="${REGION}-a"
CLUSTER_NAME="poker-cluster"
FRONTEND_IP="34.28.159.31"
BACKEND_IP="${BACKEND_IP:-136.113.179.68}"  # Default to existing backend IP
FRONTEND_IMAGE="us-central1-docker.pkg.dev/$PROJECT_ID/poker-repo/poker-frontend:latest"

echo -e "${GREEN}Configuration:${NC}"
echo "  Project ID: $PROJECT_ID"
echo "  Zone: $ZONE"
echo "  Cluster: $CLUSTER_NAME"
echo "  Frontend IP: $FRONTEND_IP"
echo "  Backend API: http://$BACKEND_IP"
echo "  Image: $FRONTEND_IMAGE"
echo ""

# Ask for confirmation
echo -e "${YELLOW}Is the backend API at http://$BACKEND_IP correct?${NC}"
echo "If not, set BACKEND_IP environment variable before running this script."
read -p "Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Set project
echo -e "${YELLOW}Setting GCP project...${NC}"
gcloud config set project "$PROJECT_ID"

# Get cluster credentials
echo -e "${YELLOW}Getting cluster credentials...${NC}"
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE"

# Reserve or check static IP
echo -e "${YELLOW}Checking static IP reservation...${NC}"
if ! gcloud compute addresses describe poker-frontend-ip --region="$REGION" &>/dev/null; then
    echo -e "${YELLOW}Reserving new static IP address...${NC}"
    gcloud compute addresses create poker-frontend-ip \
        --region="$REGION"
    
    # Get the assigned IP
    ASSIGNED_IP=$(gcloud compute addresses describe poker-frontend-ip --region="$REGION" --format="get(address)")
    echo -e "${GREEN}Reserved IP: $ASSIGNED_IP${NC}"
    FRONTEND_IP="$ASSIGNED_IP"
else
    echo -e "${GREEN}Static IP already reserved${NC}"
    EXISTING_IP=$(gcloud compute addresses describe poker-frontend-ip --region="$REGION" --format="get(address)")
    echo -e "${GREEN}Existing IP: $EXISTING_IP${NC}"
    FRONTEND_IP="$EXISTING_IP"
fi

# Build Flutter web app
echo -e "${YELLOW}Building Flutter web application...${NC}"
cd frontend

# Update backend URL in build
echo -e "${YELLOW}Note: Backend URL in main.dart is set to: http://$BACKEND_IP${NC}"
echo "Make sure frontend/lib/main.dart has the correct backend URL before building."

# Build Docker image
echo -e "${YELLOW}Building Docker image for frontend...${NC}"
docker build --platform linux/amd64 -t poker-frontend:latest .
cd ..

# Tag and push image to Artifact Registry
echo -e "${YELLOW}Tagging and pushing image to Artifact Registry...${NC}"
gcloud auth configure-docker us-central1-docker.pkg.dev --quiet
docker tag poker-frontend:latest "$FRONTEND_IMAGE"
docker push "$FRONTEND_IMAGE"

# Deploy to Kubernetes
echo -e "${YELLOW}Deploying frontend to Kubernetes...${NC}"
kubectl apply -f k8s/frontend-deployment.yaml

# Wait for deployment
echo -e "${YELLOW}Waiting for deployment to complete...${NC}"
kubectl rollout status deployment/poker-frontend

# Wait for external IP assignment
echo -e "${YELLOW}Waiting for LoadBalancer IP assignment...${NC}"
echo "This may take a few minutes..."

ASSIGNED_IP=""
ATTEMPTS=0
MAX_ATTEMPTS=30

while [ -z "$ASSIGNED_IP" ] && [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    ASSIGNED_IP=$(kubectl get service poker-frontend-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -z "$ASSIGNED_IP" ]; then
        echo -n "."
        sleep 10
        ATTEMPTS=$((ATTEMPTS + 1))
    fi
done
echo ""

if [ -z "$ASSIGNED_IP" ]; then
    echo -e "${RED}Warning: Could not retrieve LoadBalancer IP after 5 minutes${NC}"
    echo "Check manually with: kubectl get service poker-frontend-service"
else
    echo ""
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}Frontend Deployment Complete!${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo ""
    echo -e "${GREEN}Your frontend is now available at:${NC}"
    echo -e "${YELLOW}http://$ASSIGNED_IP${NC}"
    echo ""
    
    if [ "$ASSIGNED_IP" != "$FRONTEND_IP" ]; then
        echo -e "${RED}Warning: Assigned IP ($ASSIGNED_IP) differs from requested IP ($FRONTEND_IP)${NC}"
        echo "This might happen if the IP was not properly reserved or is in use."
    fi
    
    echo -e "${GREEN}Backend API is configured at:${NC}"
    echo -e "${YELLOW}http://$BACKEND_IP${NC}"
    echo ""
    echo -e "${GREEN}Test your deployment:${NC}"
    echo "  curl http://$ASSIGNED_IP/health"
    echo ""
    echo -e "${GREEN}View resources:${NC}"
    echo "  kubectl get pods -l app=poker-frontend"
    echo "  kubectl get service poker-frontend-service"
    echo "  kubectl get hpa poker-frontend-hpa"
    echo ""
    echo -e "${GREEN}View logs:${NC}"
    echo "  kubectl logs -f deployment/poker-frontend"
    echo ""
    echo -e "${GREEN}Scale deployment:${NC}"
    echo "  kubectl scale deployment poker-frontend --replicas=3"
    echo ""
fi

