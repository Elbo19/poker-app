# Deployment Guide for Project: pocker-487519

## Quick Deploy to Google Kubernetes Engine (GKE)

Your project ID **pocker-487519** has been configured in:
- ✅ `k8s/deployment.yaml` - Updated with your project ID
- ✅ `.gcp-config` - Environment variables ready to use

### Prerequisites

Make sure you have:
1. Google Cloud SDK (gcloud) installed
2. Docker installed
3. kubectl installed
4. An active GCP account with billing enabled

### Option 1: Automated Deployment (Recommended)

Simply run the deployment script:

```bash
cd /Users/elbetel/projects/poker-app
chmod +x deploy.sh
./deploy.sh
```

When prompted, enter: **pocker-487519**

The script will automatically:
- Enable required GCP APIs
- Create a GKE cluster (if needed)
- Build and push Docker image
- Deploy the application
- Display the external IP

### Option 2: Manual Deployment

```bash
# 1. Set project
gcloud config set project pocker-487519

# 2. Enable APIs
gcloud services enable container.googleapis.com artifactregistry.googleapis.com

# 3. Create Artifact Registry repository
gcloud artifacts repositories create poker-repo \
  --repository-format=docker \
  --location=us-central1 \
  --description="Docker repository for poker app"

# 4. Create GKE cluster
gcloud container clusters create poker-cluster \
  --zone us-central1-a \
  --num-nodes 2 \
  --machine-type e2-small \
  --enable-autoscaling \
  --min-nodes 1 \
  --max-nodes 5

# 4. Get credentials
gcloud container clusters get-credentials poker-cluster --zone us-central1-a

# 5. Build Docker image (for amd64 platform)
cd backend
docker build --platform linux/amd64 -t poker-backend:latest .
cd ..

# 6. Tag and push to Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev
docker tag poker-backend:latest us-central1-docker.pkg.dev/pocker-487519/poker-repo/poker-backend:latest
docker push us-central1-docker.pkg.dev/pocker-487519/poker-repo/poker-backend:latest

# 7. Grant permissions to GKE nodes
gcloud projects add-iam-policy-binding pocker-487519 \
  --member=serviceAccount:8503041098-compute@developer.gserviceaccount.com \
  --role=roles/artifactregistry.reader

# 8. Deploy to Kubernetes
kubectl apply -f k8s/deployment.yaml

# 9. Get external IP (may take a few minutes)
kubectl get service poker-backend-service
```

### After Deployment

1. **Get the External IP:**
   ```bash
   kubectl get service poker-backend-service
   ```
   
   **Current External IP: 136.113.179.68**

2. **Test the API:**
   ```bash
   curl http://136.113.179.68/health
   ```

3. **Frontend is already configured:**
   The frontend at `frontend/lib/main.dart` is already pointing to http://136.113.179.68
   curl http://YOUR_EXTERNAL_IP/health
   ```

4. **Deploy Frontend:**
   - Option A: Build for web and host on Firebase Hosting, Netlify, or Vercel
   - Option B: Run locally with `flutter run -d chrome`

### Monitoring

```bash
# Check pod status
kubectl get pods

# View logs
kubectl logs -l app=poker-backend

# Check autoscaling
kubectl get hpa
```

### Cleanup (if needed)

```bash
# Delete the application
kubectl delete -f k8s/deployment.yaml

# Delete the cluster
gcloud container clusters delete poker-cluster --zone us-central1-a

# Delete Docker images from Artifact Registry
gcloud artifacts docker images delete us-central1-docker.pkg.dev/pocker-487519/poker-repo/poker-backend:latest
```

## Current Status

✅ Backend deployed on GKE at **http://136.113.179.68**
✅ Frontend configured for deployment at **http://34.28.159.31**
✅ All 55 test cases passing
✅ Visual playing cards implemented
✅ Blue theme applied
✅ Using Artifact Registry for Docker images
✅ Project ID: pocker-487519

**API is live and working:**
- Health: http://136.113.179.68/health
- Evaluate: http://136.113.179.68/api/evaluate
- Probability: http://136.113.179.68/api/probability

## Deploy Frontend to GKE

### Quick Frontend Deploy

```bash
cd /Users/elbetel/projects/poker-app
chmod +x deploy-frontend.sh
./deploy-frontend.sh
```

The script will:
- Reserve static IP 34.28.159.31 for the frontend
- Build Flutter web application
- Build and push Docker image to Artifact Registry
- Deploy to GKE cluster
- Configure LoadBalancer with static IP
- Display the frontend URL

### Manual Frontend Deployment

```bash
# 1. Reserve static IP
gcloud compute addresses create poker-frontend-ip \
  --region=us-central1 \
  --addresses=34.28.159.31

# 2. Build Flutter web app
cd frontend
docker build --platform linux/amd64 -t poker-frontend:latest .
cd ..

# 3. Tag and push to Artifact Registry
docker tag poker-frontend:latest \
  us-central1-docker.pkg.dev/pocker-487519/poker-repo/poker-frontend:latest
docker push us-central1-docker.pkg.dev/pocker-487519/poker-repo/poker-frontend:latest

# 4. Deploy to Kubernetes
kubectl apply -f k8s/frontend-deployment.yaml

# 5. Check deployment status
kubectl get service poker-frontend-service
kubectl get pods -l app=poker-frontend
```

### Update Backend URL (if needed)

If your backend IP changes, update [frontend/lib/main.dart](frontend/lib/main.dart#L238-L240):

```dart
final String apiUrl = kDebugMode 
    ? 'http://localhost:8080'
    : 'http://YOUR_BACKEND_IP';
```

Then rebuild and redeploy the frontend.

## Test the Live API

```bash
# Health check
curl http://136.113.179.68/health

# Evaluate a Royal Flush
curl -X POST http://136.113.179.68/api/evaluate \
  -H "Content-Type: application/json" \
  -d '{"holeCards":["HA","SK"],"communityCards":["HK","HQ","HJ","HT","D2"]}'
```

## Need Help?

See the detailed deployment instructions in `README.md` or run:
```bash
./deploy.sh
```
