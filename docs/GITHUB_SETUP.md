# Setting Up GitHub Repository

## Initialize Local Repository

```bash
cd ~/projects/poker-app
git init
git add .
git commit -m "Initial commit: Texas Hold'em Poker App with Go backend, Flutter frontend, and GKE deployment"
```

## Create GitHub Repository

1. Go to [GitHub](https://github.com/new)
2. Create a new repository named `poker-app`
3. **Do NOT** initialize with README, .gitignore, or license (we already have these)

## Push to GitHub

```bash
# Add remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/poker-app.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## Repository Setup

### Add Description
```
Texas Hold'em Poker Hand Evaluator & Probability Calculator - Go backend, Flutter frontend, deployed on Google Kubernetes Engine
```

### Add Topics
- `poker`
- `golang`
- `flutter`
- `kubernetes`
- `gke`
- `monte-carlo`
- `docker`
- `rest-api`
- `texas-holdem`

### Create Repository Secrets (for CI/CD later)

Go to Settings > Secrets and variables > Actions, and add:
- `GCP_PROJECT_ID`: Your GCP project ID
- `GCP_SA_KEY`: Service account key JSON (base64 encoded)

## GitHub Actions CI/CD (Optional)

Create `.github/workflows/deploy.yml`:

```yaml
name: Build and Deploy to GKE

on:
  push:
    branches: [ main ]

env:
  PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
  GKE_CLUSTER: poker-cluster
  GKE_REGION: us-central1
  IMAGE: poker-backend

jobs:
  setup-build-publish-deploy:
    name: Setup, Build, Publish, and Deploy
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v3

    - name: Setup Cloud SDK
      uses: google-github-actions/setup-gcloud@v1
      with:
        service_account_key: ${{ secrets.GCP_SA_KEY }}
        project_id: ${{ secrets.GCP_PROJECT_ID }}

    - name: Configure Docker
      run: gcloud auth configure-docker

    - name: Build Docker Image
      run: |
        cd backend
        docker build --platform linux/amd64 -t gcr.io/$PROJECT_ID/$IMAGE:$GITHUB_SHA .

    - name: Push Docker Image
      run: docker push gcr.io/$PROJECT_ID/$IMAGE:$GITHUB_SHA

    - name: Get GKE Credentials
      run: |
        gcloud container clusters get-credentials $GKE_CLUSTER --region $GKE_REGION

    - name: Deploy to GKE
      run: |
        sed "s/YOUR_PROJECT_ID/$PROJECT_ID/g" k8s/deployment.yaml | \\
        sed "s/:latest/:$GITHUB_SHA/g" | \\
        kubectl apply -f -

    - name: Verify Deployment
      run: kubectl rollout status deployment/poker-backend
```

## Branch Protection (Recommended)

1. Go to Settings > Branches
2. Add rule for `main` branch:
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date

## Project Website

You can use GitHub Pages to host your Flutter web app:

1. Build Flutter for web:
   ```bash
   cd frontend
   flutter build web
   ```

2. Copy `build/web` contents to a `docs/` folder in your repository

3. Enable GitHub Pages in repository settings:
   - Settings > Pages
   - Source: Deploy from branch
   - Branch: main, folder: /docs

## README Badges

Add these badges to the top of your README.md:

```markdown
![Build Status](https://github.com/YOUR_USERNAME/poker-app/workflows/Build%20and%20Deploy%20to%20GKE/badge.svg)
![Go Version](https://img.shields.io/badge/Go-1.21+-00ADD8?logo=go)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker)
![Kubernetes](https://img.shields.io/badge/Kubernetes-GKE-326CE5?logo=kubernetes)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)
```

## License

Add a LICENSE file (MIT License):

```
MIT License

Copyright (c) 2026 Your Name

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Collaborate

Invite collaborators in Settings > Collaborators and teams.
