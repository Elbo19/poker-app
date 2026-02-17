# Texas Hold'em Poker Hand Evaluator & Probability Calculator

A full-stack poker application with Go backend, Flutter frontend, deployed on Google Kubernetes Engine (GKE).

## Features

- **Hand Evaluation**: Evaluates poker hands from hole cards and community cards
- **Hand Comparison**: Compares two poker hands and determines the winner
- **Monte Carlo Probability Calculator**: Calculates win probability using Monte Carlo simulation
- **Scalable Architecture**: Deployed on Kubernetes with horizontal pod autoscaling
- **Load Tested**: Includes k6 load testing scripts

## API Specification

### Card Format
Cards are specified as 2-character strings:
- First character: Suit (H=Hearts, D=Diamonds, C=Clubs, S=Spades)
- Second character: Rank (2-9, T=Ten, J=Jack, Q=Queen, K=King, A=Ace)

Examples: `HA` (Heart-Ace), `S7` (Spade-7), `CT` (Club-Ten)

### Endpoints

#### 1. Health Check
```
GET /health
Response: {"status": "healthy", "version": "1.0.0"}
```

#### 2. Evaluate Hand
```
POST /api/evaluate
Content-Type: application/json

Request:
{
  "holeCards": ["HA", "HK"],
  "communityCards": ["HQ", "HJ", "HT", "D2", "C3"]
}

Response:
{
  "handRank": "Royal Flush",
  "description": "Royal Flush",
  "cards": ["♥A", "♥K", "♥Q", "♥J", "♥T"],
  "success": true
}
```

#### 3. Compare Hands
```
POST /api/compare
Content-Type: application/json

Request:
{
  "player1HoleCards": ["HA", "HK"],
  "player1CommunityCards": ["HQ", "HJ", "HT", "D2", "C3"],
  "player2HoleCards": ["SA", "SK"],
  "player2CommunityCards": ["HQ", "HJ", "HT", "D2", "C3"]
}

Response:
{
  "player1Hand": "Royal Flush",
  "player1Description": "Royal Flush",
  "player2Hand": "Straight",
  "player2Description": "Straight, Ace high",
  "winner": "player1",
  "success": true
}
```

#### 4. Calculate Win Probability
```
POST /api/probability
Content-Type: application/json

Request:
{
  "holeCards": ["HA", "HK"],
  "communityCards": ["HQ", "HJ", "HT"],
  "numPlayers": 6,
  "simulations": 10000
}

Response:
{
  "winProbability": 0.8523,
  "tieProbability": 0.0012,
  "lossProbability": 0.1465,
  "simulations": 10000,
  "success": true
}
```

## Project Structure

```
poker-app/
├── backend/                 # Go backend service
│   ├── cmd/server/         # Main application
│   ├── internal/
│   │   ├── poker/          # Poker logic
│   │   └── handler/        # HTTP handlers
│   ├── Dockerfile
│   └── go.mod
├── frontend/               # Flutter web app
│   ├── lib/main.dart
│   └── pubspec.yaml
├── k8s/                    # Kubernetes manifests
│   └── deployment.yaml
├── loadtest/               # k6 load testing scripts
│   └── load-test.js
└── README.md
```

## Development Setup

### Prerequisites
- Go 1.21+
- Flutter 3.0+
- Docker
- kubectl
- Google Cloud SDK
- gke-gcloud-auth-plugin
- k6

### Backend Development

1. **Navigate to backend directory**:
   ```bash
   cd backend
   ```

2. **Install dependencies**:
   ```bash
   go mod download
   ```

3. **Run tests**:
   ```bash
   go test ./internal/poker -v
   ```

4. **Run locally**:
   ```bash
   go run ./cmd/server
   ```

5. **Test API**:
   ```bash
   # Health check
   curl http://localhost:8080/health

   # Evaluate hand
   curl -X POST http://localhost:8080/api/evaluate \
     -H "Content-Type: application/json" \
     -d '{"holeCards":["HA","HK"],"communityCards":["HQ","HJ","HT","D2","C3"]}'
   ```

### Frontend Development

1. **Navigate to frontend directory**:
   ```bash
   cd frontend
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Update API URL** in `lib/main.dart`:
   ```dart
   final String apiUrl = 'http://localhost:8080';
   ```

4. **Run web app**:
   ```bash
   flutter run -d chrome
   ```

## Docker Containerization

### Build Backend Image

1. **Navigate to backend directory**:
   ```bash
   cd backend
   ```

2. **Build for amd64 (GKE requirement)**:
   ```bash
   docker build --platform linux/amd64 -t poker-backend:latest .
   ```

3. **Test locally**:
   ```bash
   docker run -p 8080:8080 poker-backend:latest
   ```

## Google Kubernetes Engine (GKE) Deployment

### Step 1: Setup GKE Project

1. **Set your project ID**:
   ```bash
   export PROJECT_ID="your-gcp-project-id"
   export REGION="us-central1"
   export CLUSTER_NAME="poker-cluster"
   ```

2. **Enable required APIs**:
   ```bash
   gcloud services enable container.googleapis.com
   gcloud services enable containerregistry.googleapis.com
   ```

3. **Create GKE cluster**:
   ```bash
   gcloud container clusters create $CLUSTER_NAME \
     --region $REGION \
     --num-nodes 3 \
     --machine-type n1-standard-2 \
     --enable-autoscaling \
     --min-nodes 3 \
     --max-nodes 10
   ```

4. **Get credentials**:
   ```bash
   gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION
   ```

### Step 2: Push Docker Image to GCR

1. **Tag image**:
   ```bash
   docker tag poker-backend:latest gcr.io/$PROJECT_ID/poker-backend:latest
   ```

2. **Configure Docker auth**:
   ```bash
   gcloud auth configure-docker
   ```

3. **Push image**:
   ```bash
   docker push gcr.io/$PROJECT_ID/poker-backend:latest
   ```

### Step 3: Deploy to GKE

1. **Update deployment.yaml**:
   Edit `k8s/deployment.yaml` and replace `YOUR_PROJECT_ID` with your actual project ID:
   ```yaml
   image: gcr.io/YOUR_PROJECT_ID/poker-backend:latest
   ```

2. **Apply Kubernetes manifests**:
   ```bash
   kubectl apply -f k8s/deployment.yaml
   ```

3. **Check deployment status**:
   ```bash
   kubectl get pods
   kubectl get services
   kubectl get hpa
   ```

4. **Get external IP**:
   ```bash
   kubectl get service poker-backend-service
   ```
   Wait for `EXTERNAL-IP` to appear (may take a few minutes).

5. **Test the deployment**:
   ```bash
   export API_URL="http://EXTERNAL-IP"
   curl $API_URL/health
   ```

### Step 4: Update Frontend

Update the `apiUrl` in `frontend/lib/main.dart` with your external IP:
```dart
final String apiUrl = 'http://YOUR_EXTERNAL_IP';
```

## Load Testing

### Run k6 Load Tests

1. **Set API URL**:
   ```bash
   export API_URL="http://YOUR_EXTERNAL_IP"
   ```

2. **Run tests**:
   ```bash
   k6 run loadtest/load-test.js
   ```

3. **Monitor Kubernetes**:
   ```bash
   # Watch pods scaling
   watch kubectl get pods

   # Watch HPA
   watch kubectl get hpa

   # View logs
   kubectl logs -f deployment/poker-backend
   ```

### Load Test Results

The test simulates:
- Ramp up to 100 concurrent users
- Multiple API endpoints
- Threshold: 95% of requests < 500ms
- Error rate < 10%

## Monitoring

### View Logs
```bash
kubectl logs -f deployment/poker-backend
```

### Describe Deployment
```bash
kubectl describe deployment poker-backend
```

### Check Autoscaling
```bash
kubectl get hpa poker-backend-hpa --watch
```

### View Metrics
```bash
kubectl top nodes
kubectl top pods
```

## Troubleshooting

### Pods not starting
```bash
kubectl describe pod POD_NAME
kubectl logs POD_NAME
```

### Service not accessible
```bash
kubectl get svc
kubectl describe svc poker-backend-service
```

### Image pull errors
```bash
# Verify image exists
gcloud container images list --repository=gcr.io/$PROJECT_ID

# Check image details
gcloud container images describe gcr.io/$PROJECT_ID/poker-backend:latest
```

## Cleanup

To avoid charges, delete resources when done:

```bash
# Delete Kubernetes resources
kubectl delete -f k8s/deployment.yaml

# Delete GKE cluster
gcloud container clusters delete $CLUSTER_NAME --region $REGION

# Delete Docker images
gcloud container images delete gcr.io/$PROJECT_ID/poker-backend:latest
```

## Technology Stack

- **Backend**: Go 1.21
- **Frontend**: Flutter/Dart
- **Container Runtime**: Docker
- **Orchestration**: Kubernetes (GKE)
- **Load Testing**: k6
- **Cloud Platform**: Google Cloud Platform

## Testing

### Unit Tests
```bash
cd backend
go test ./internal/poker -v -cover
```

### API Tests
Use the provided examples in the API Specification section.

### Load Tests
See the Load Testing section above.

## Performance Considerations

- **Horizontal Pod Autoscaling**: Automatically scales from 3 to 10 pods based on CPU/Memory
- **Resource Limits**: Each pod has memory and CPU limits
- **Health Checks**: Liveness and readiness probes ensure pod health
- **Monte Carlo Simulations**: Adjust simulation count based on accuracy vs. performance needs

## Future Enhancements

- [ ] Add authentication/authorization
- [ ] Implement caching for common hand evaluations
- [ ] Add WebSocket support for real-time updates
- [ ] Implement database for storing game history
- [ ] Add more advanced poker statistics
- [ ] Implement CI/CD pipeline

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## License

MIT License

## Resources

- [Peter Norvig's Poker Hand Evaluator](http://norvig.com/poker.html)
- [Texas Hold'em Rules (Wikipedia)](https://en.wikipedia.org/wiki/Texas_hold_%27em)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine)
