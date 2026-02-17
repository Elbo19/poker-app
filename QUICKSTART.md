# Quick Start Guide

## Prerequisites Checklist

- [ ] Go 1.21+ installed
- [ ] Flutter 3.0+ installed
- [ ] Docker installed and running
- [ ] kubectl installed
- [ ] Google Cloud SDK (gcloud) installed
- [ ] gke-gcloud-auth-plugin installed
- [ ] k6 installed (for load testing)
- [ ] GCP project created

## Deployment Steps

### Option 1: Automated Deployment (Recommended)

1. **Make the deployment script executable**:
   ```bash
   chmod +x deploy.sh
   ```

2. **Run the deployment script**:
   ```bash
   ./deploy.sh
   ```

3. **Follow the prompts** and enter your GCP Project ID

4. **Wait for completion** - The script will:
   - Enable required GCP APIs
   - Create GKE cluster (if doesn't exist)
   - Build and push Docker image
   - Deploy to Kubernetes
   - Display your API URL

### Option 2: Manual Deployment

Follow the detailed steps in the main [README.md](README.md) file.

## Testing Your Deployment

Once deployed, test your API:

```bash
# Replace YOUR_IP with the external IP from deployment
export API_URL="http://YOUR_IP"

# Test health endpoint
curl $API_URL/health

# Test hand evaluation
curl -X POST $API_URL/api/evaluate \
  -H "Content-Type: application/json" \
  -d '{
    "holeCards": ["HA", "HK"],
    "communityCards": ["HQ", "HJ", "HT", "D2", "C3"]
  }'

# Test probability calculation
curl -X POST $API_URL/api/probability \
  -H "Content-Type: application/json" \
  -d '{
    "holeCards": ["HA", "HK"],
    "communityCards": ["HQ", "HJ", "HT"],
    "numPlayers": 6,
    "simulations": 1000
  }'
```

## Running the Frontend

1. **Navigate to frontend directory**:
   ```bash
   cd frontend
   ```

2. **Update API URL** in `lib/main.dart`:
   ```dart
   final String apiUrl = 'http://YOUR_EXTERNAL_IP';
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the web app**:
   ```bash
   flutter run -d chrome
   ```

## Running Load Tests

```bash
export API_URL="http://YOUR_EXTERNAL_IP"
k6 run loadtest/load-test.js
```

## Monitoring

```bash
# Watch pods
watch kubectl get pods

# Watch autoscaling
watch kubectl get hpa

# View logs
kubectl logs -f deployment/poker-backend

# View metrics
kubectl top pods
```

## Common Issues

### Issue: Docker build fails on M1/M2 Mac
**Solution**: Ensure you're building for amd64:
```bash
docker build --platform linux/amd64 -t poker-backend:latest .
```

### Issue: Can't connect to cluster
**Solution**: Get credentials again:
```bash
gcloud container clusters get-credentials poker-cluster --region us-central1
```

### Issue: Image pull error in Kubernetes
**Solution**: Configure Docker authentication:
```bash
gcloud auth configure-docker
```

### Issue: External IP stays "<pending>"
**Solution**: Wait a few minutes. GCP is allocating an IP address.

## Cleanup

To delete all resources and avoid charges:

```bash
# Delete Kubernetes resources
kubectl delete -f k8s/deployment-updated.yaml

# Delete GKE cluster
gcloud container clusters delete poker-cluster --region us-central1

# Delete Docker images
gcloud container images delete gcr.io/YOUR_PROJECT_ID/poker-backend:latest
```

## Next Steps

1. Initialize a Git repository and push to GitHub
2. Run load tests to verify scalability
3. Customize the Flutter frontend
4. Set up CI/CD pipeline
5. Add monitoring and alerting
6. Implement authentication

## Support

For issues or questions, refer to:
- Main [README.md](README.md)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Google Kubernetes Engine Docs](https://cloud.google.com/kubernetes-engine/docs)
