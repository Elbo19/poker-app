# Docker Deployment Guide

## Quick Start

### Build and Run
```bash
# Build and start all services
docker-compose up -d

# View running containers
docker-compose ps

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

## Services

### Backend (Go)
- **Port**: 8080
- **Health Check**: http://localhost:8080/health
- **API Endpoints**:
  - `GET /` - API information
  - `GET /health` - Health check
  - `POST /api/evaluate` - Evaluate a poker hand
  - `POST /api/compare` - Compare two poker hands
  - `POST /api/probability` - Calculate win probability

### Frontend (Flutter Web)
- **Port**: 80
- **Health Check**: http://localhost/health
- **URL**: http://localhost

## Testing the API

### Health Check
```bash
curl http://localhost:8080/health
```

### Compare Hands
```bash
curl -X POST http://localhost:8080/api/compare \
  -H "Content-Type: application/json" \
  -d '{
    "player1HoleCards": ["SA", "HA"],
    "player1CommunityCards": ["DQ", "C8", "S6", "H4", "D2"],
    "player2HoleCards": ["SK", "HK"],
    "player2CommunityCards": ["DQ", "C8", "S6", "H4", "D2"]
  }'
```

Expected response:
```json
{
  "player1Hand": "One Pair",
  "player1Description": "One Pair, Aces",
  "player2Hand": "One Pair",
  "player2Description": "One Pair, Kings",
  "winner": "player1",
  "success": true
}
```

### Evaluate Hand
```bash
curl -X POST http://localhost:8080/api/evaluate \
  -H "Content-Type: application/json" \
  -d '{
    "holeCards": ["SA", "HA"],
    "communityCards": ["DQ", "C8", "S6", "H4", "D2"]
  }'
```

## Docker Commands

### Rebuild Containers
```bash
# Rebuild after code changes
docker-compose build

# Rebuild without cache
docker-compose build --no-cache

# Rebuild specific service
docker-compose build backend
```

### Container Management
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose stop

# Remove containers
docker-compose down

# Remove containers and volumes
docker-compose down -v

# Restart services
docker-compose restart

# View container status
docker-compose ps

# View logs
docker-compose logs -f [service_name]
```

### Accessing Containers
```bash
# Access backend container shell
docker-compose exec backend sh

# Access frontend container shell
docker-compose exec frontend sh
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│                  Docker Host                     │
│                                                  │
│  ┌────────────────┐       ┌──────────────────┐ │
│  │   Frontend     │       │     Backend      │ │
│  │ (Flutter Web)  │◄──────┤   (Go Server)    │ │
│  │                │       │                  │ │
│  │  Port: 80      │       │   Port: 8080     │ │
│  └────────────────┘       └──────────────────┘ │
│         │                          │            │
│         └──────────┬───────────────┘            │
│                    │                            │
│            ┌───────▼────────┐                   │
│            │ poker-network  │                   │
│            │ (Bridge)       │                   │
│            └────────────────┘                   │
└─────────────────────────────────────────────────┘
         │                    │
         ▼                    ▼
    Port 80              Port 8080
  (Frontend)            (API)
```

## Development Workflow

### 1. Make Code Changes
Edit files in `backend/` or `frontend/`

### 2. Rebuild
```bash
# For backend changes
docker-compose build backend
docker-compose up -d backend

# For frontend changes
docker-compose build frontend
docker-compose up -d frontend
```

### 3. Test
```bash
# Check logs
docker-compose logs -f

# Test API
curl http://localhost:8080/health

# Test frontend
curl http://localhost/health
```

## Production Deployment

### Build for Production
```bash
# Build images
docker-compose build

# Tag images for registry
docker tag poker-app-backend:latest your-registry/poker-backend:latest
docker tag poker-app-frontend:latest your-registry/poker-frontend:latest

# Push to registry
docker push your-registry/poker-backend:latest
docker push your-registry/poker-frontend:latest
```

### Environment Variables
Create a `.env` file for production:
```env
PORT=8080
BACKEND_URL=http://backend:8080
```

## Troubleshooting

### Container Not Starting
```bash
# Check logs
docker-compose logs backend
docker-compose logs frontend

# Inspect container
docker inspect poker-backend
```

### Port Already in Use
```bash
# Find process using port 8080
lsof -i :8080

# Kill process
kill -9 <PID>

# Or change port in docker-compose.yml
```

### Build Issues
```bash
# Clean build
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Network Issues
```bash
# Remove network
docker-compose down
docker network prune

# Recreate
docker-compose up -d
```

## Health Checks

Both services have health checks configured:
- **Backend**: Checks `/health` endpoint every 30s
- **Frontend**: Checks `/health` endpoint every 30s

View health status:
```bash
docker-compose ps
```

## Performance

### Image Sizes
- Backend: ~15-20 MB (Alpine-based)
- Frontend: ~50-60 MB (nginx + Flutter web)

### Resource Usage
- Backend: ~10-20 MB RAM
- Frontend: ~5-10 MB RAM

## Current Status

✅ **Backend**: Running on port 8080  
✅ **Frontend**: Running on port 80  
✅ **Health Checks**: Passing  
✅ **API Tests**: All endpoints working  
✅ **Network**: Bridge network configured  

## Testing with Excel Test Cases

To run the Excel test cases against the Dockerized backend:

```bash
# Make sure containers are running
docker-compose ps

# Run tests
python3 test_excel_cases.py
```

Expected results: 53/55 tests passing (96% pass rate)
