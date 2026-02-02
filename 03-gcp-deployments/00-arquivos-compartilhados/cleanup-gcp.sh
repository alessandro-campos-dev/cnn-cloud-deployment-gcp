#!/bin/bash

# Cleanup script for GCP resources
# Usage: ./scripts/cleanup-gcp.sh [service|all]

set -e

PROJECT_ID="YOUR_PROJECT_ID"
REGION="southamerica-east1"

# Function to cleanup Cloud Run
cleanup_cloud_run() {
    echo "Cleaning up Cloud Run..."
    gcloud run services delete cnn-classifier --region ${REGION} --quiet || true
    gcloud run services delete cnn-classifier-us --region us-central1 --quiet || true
    echo "Cloud Run cleanup complete."
}

# Function to cleanup Cloud Functions
cleanup_cloud_functions() {
    echo "Cleaning up Cloud Functions..."
    gcloud functions delete cnn-classifier-predict --region ${REGION} --quiet || true
    gcloud functions delete cnn-classifier-batch --region ${REGION} --quiet || true
    echo "Cloud Functions cleanup complete."
}

# Function to cleanup App Engine
cleanup_app_engine() {
    echo "Cleaning up App Engine..."
    gcloud app versions delete --service default --quiet || true
    echo "App Engine cleanup complete."
}

# Function to cleanup GKE
cleanup_gke() {
    echo "Cleaning up GKE..."
    kubectl delete -f src/gcp-deployments/gke/ --ignore-not-found=true || true
    echo "GKE cleanup complete."
}

# Function to cleanup Compute Engine
cleanup_gce() {
    echo "Cleaning up Compute Engine..."
    gcloud compute instances delete cnn-classifier-vm --zone=${REGION}-a --quiet || true
    echo "Compute Engine cleanup complete."
}

# Function to cleanup Container Registry images
cleanup_images() {
    echo "Cleaning up Container Registry images..."
    gcloud container images delete gcr.io/${PROJECT_ID}/cnn-classifier:latest --quiet || true
    gcloud container images delete gcr.io/${PROJECT_ID}/cnn-classifier --force-delete-tags --quiet || true
    echo "Container Registry cleanup complete."
}

# Main cleanup logic
if [ "$1" = "all" ]; then
    cleanup_cloud_run
    cleanup_cloud_functions
    cleanup_app_engine
    cleanup_gke
    cleanup_gce
    cleanup_images
    echo "✅ All GCP resources cleaned up!"
else
    case $1 in
        "cloud-run")
            cleanup_cloud_run
            ;;
        "cloud-functions")
            cleanup_cloud_functions
            ;;
        "app-engine")
            cleanup_app_engine
            ;;
        "gke")
            cleanup_gke
            ;;
        "gce")
            cleanup_gce
            ;;
        "images")
            cleanup_images
            ;;
        *)
            echo "Usage: $0 [cloud-run|cloud-functions|app-engine|gke|gce|images|all]"
            exit 1
            ;;
    esac
fi