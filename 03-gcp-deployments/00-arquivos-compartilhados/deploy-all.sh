#!/bin/bash

# Script to deploy to all GCP services
# Usage: ./scripts/deploy-all.sh [service]
# If no service specified, deploys to all

set -e

PROJECT_ID="YOUR_PROJECT_ID"
REGION="southamerica-east1"
IMAGE_NAME="cnn-classifier"
TAG="latest"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting deployment to GCP services...${NC}"

# Function to deploy to Cloud Run
deploy_cloud_run() {
    echo -e "${YELLOW}📦 Deploying to Cloud Run...${NC}"
    
    # Build and push image
    docker build -t gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG} -f src/gcp-deployments/cloud-run/Dockerfile .
    docker push gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG}
    
    # Deploy to Cloud Run
    gcloud run deploy ${IMAGE_NAME} \
        --image gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG} \
        --platform managed \
        --region ${REGION} \
        --allow-unauthenticated \
        --memory 512Mi \
        --cpu 1 \
        --max-instances 10 \
        --timeout 300s
    
    echo -e "${GREEN}✅ Cloud Run deployment complete!${NC}"
    gcloud run services describe ${IMAGE_NAME} --region ${REGION} --format="value(status.url)"
}

# Function to deploy to Cloud Functions
deploy_cloud_functions() {
    echo -e "${YELLOW}⚡ Deploying to Cloud Functions...${NC}"
    
    cd src/gcp-deployments/cloud-functions
    gcloud functions deploy cnn-classifier-predict \
        --runtime python311 \
        --trigger-http \
        --allow-unauthenticated \
        --region ${REGION} \
        --memory 512MB \
        --timeout 300s \
        --max-instances 10 \
        --entry-point predict_image
    
    cd ../../..
    echo -e "${GREEN}✅ Cloud Functions deployment complete!${NC}"
}

# Function to deploy to App Engine
deploy_app_engine() {
    echo -e "${YELLOW}🌐 Deploying to App Engine...${NC}"
    
    gcloud app deploy src/gcp-deployments/app-engine/app.yaml \
        --project ${PROJECT_ID} \
        --quiet
    
    echo -e "${GREEN}✅ App Engine deployment complete!${NC}"
    echo "Your app is available at: https://${PROJECT_ID}.uc.r.appspot.com"
}

# Function to deploy to GKE
deploy_gke() {
    echo -e "${YELLOW}🐳 Deploying to GKE...${NC}"
    
    # Set GKE cluster
    CLUSTER_NAME="cnn-cluster"
    ZONE="${REGION}-a"
    
    # Build and push image
    docker build -t gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG} .
    docker push gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG}
    
    # Update image in deployment
    sed -i "s|gcr.io/YOUR_PROJECT_ID/cnn-classifier:latest|gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG}|g" src/gcp-deployments/gke/deployment.yaml
    
    # Apply Kubernetes manifests
    kubectl apply -f src/gcp-deployments/gke/namespace.yaml
    kubectl apply -f src/gcp-deployments/gke/configmap.yaml
    kubectl apply -f src/gcp-deployments/gke/deployment.yaml
    kubectl apply -f src/gcp-deployments/gke/service.yaml
    kubectl apply -f src/gcp-deployments/gke/hpa.yaml
    
    echo -e "${GREEN}✅ GKE deployment complete!${NC}"
    echo "Waiting for external IP..."
    kubectl get service cnn-classifier-service --namespace cnn-classifier
}

# Function to deploy to Compute Engine
deploy_gce() {
    echo -e "${YELLOW}🖥️  Deploying to Compute Engine...${NC}"
    
    INSTANCE_NAME="cnn-classifier-vm"
    ZONE="${REGION}-a"
    
    # Create instance
    gcloud compute instances create ${INSTANCE_NAME} \
        --zone=${ZONE} \
        --machine-type=e2-medium \
        --tags=http-server,https-server \
        --image-family=debian-11 \
        --image-project=debian-cloud \
        --metadata-from-file startup-script=src/gcp-deployments/gce/startup-script.sh \
        --scopes=cloud-platform
    
    echo -e "${GREEN}✅ Compute Engine instance created!${NC}"
    echo "SSH into the instance: gcloud compute ssh ${INSTANCE_NAME} --zone=${ZONE}"
}

# Function to display URLs
show_urls() {
    echo -e "\n${GREEN}🌍 Deployment URLs:${NC}"
    echo "----------------------------------------"
    
    # Cloud Run
    CLOUD_RUN_URL=$(gcloud run services describe ${IMAGE_NAME} --region ${REGION} --format="value(status.url)" 2>/dev/null || echo "Not deployed")
    echo "Cloud Run: ${CLOUD_RUN_URL}"
    
    # Cloud Functions
    CLOUD_FUNCTIONS_URL=$(gcloud functions describe cnn-classifier-predict --region ${REGION} --format="value(httpsTrigger.url)" 2>/dev/null || echo "Not deployed")
    echo "Cloud Functions: ${CLOUD_FUNCTIONS_URL}"
    
    # App Engine
    echo "App Engine: https://${PROJECT_ID}.uc.r.appspot.com"
    
    # GKE
    GKE_IP=$(kubectl get service cnn-classifier-service --namespace cnn-classifier --output=jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Not deployed")
    if [ "$GKE_IP" != "Not deployed" ]; then
        echo "GKE: http://${GKE_IP}"
    else
        echo "GKE: ${GKE_IP}"
    fi
    
    # Compute Engine
    GCE_IP=$(gcloud compute instances describe cnn-classifier-vm --zone=${REGION}-a --format='value(networkInterfaces[0].accessConfigs[0].natIP)' 2>/dev/null || echo "Not deployed")
    echo "Compute Engine: http://${GCE_IP}:8080"
    
    echo "----------------------------------------"
}

# Main deployment logic
if [ $# -eq 0 ]; then
    # Deploy to all services
    deploy_cloud_run
    deploy_cloud_functions
    deploy_app_engine
    deploy_gke
    deploy_gce
    show_urls
else
    case $1 in
        "cloud-run")
            deploy_cloud_run
            ;;
        "cloud-functions")
            deploy_cloud_functions
            ;;
        "app-engine")
            deploy_app_engine
            ;;
        "gke")
            deploy_gke
            ;;
        "gce")
            deploy_gce
            ;;
        "urls")
            show_urls
            ;;
        *)
            echo -e "${RED}❌ Unknown service: $1${NC}"
            echo "Available services: cloud-run, cloud-functions, app-engine, gke, gce, urls"
            exit 1
            ;;
    esac
fi

echo -e "\n${GREEN}✨ All deployments completed successfully!${NC}"