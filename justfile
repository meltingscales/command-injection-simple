# Command Injection Lab - Cloud Run Deployment
# Deploys to Google Cloud Run with automatic *.run.app domain

# Default recipe - show available commands
default:
    @just --list

# Deploy to Cloud Run (gets automatic *.run.app domain)
deploy PROJECT_ID:
    #!/usr/bin/env bash
    set -euo pipefail
    # Build image with Cloud Build
    gcloud builds submit \
      --tag gcr.io/{{PROJECT_ID}}/cmd-injection-lab \
      --project={{PROJECT_ID}}
    # Deploy to Cloud Run
    gcloud run deploy cmd-injection-lab \
      --image gcr.io/{{PROJECT_ID}}/cmd-injection-lab \
      --platform managed \
      --region us-central1 \
      --allow-unauthenticated \
      --port 8080 \
      --memory 512Mi \
      --cpu 1 \
      --timeout 60 \
      --max-instances 1 \
      --project={{PROJECT_ID}}
    echo ""
    echo "Deployment complete! Your URL:"
    gcloud run services describe cmd-injection-lab \
      --region us-central1 \
      --project={{PROJECT_ID}} \
      --format='value(status.url)'

# Get service URL
get-url PROJECT_ID:
    gcloud run services describe cmd-injection-lab \
      --region us-central1 \
      --project={{PROJECT_ID}} \
      --format='value(status.url)'

# View logs
logs PROJECT_ID:
    gcloud run services logs read cmd-injection-lab \
      --region us-central1 \
      --project={{PROJECT_ID}} \
      --limit 50

# Follow logs in real-time
logs-follow PROJECT_ID:
    gcloud run services logs tail cmd-injection-lab \
      --region us-central1 \
      --project={{PROJECT_ID}}

# Delete service
delete PROJECT_ID:
    gcloud run services delete cmd-injection-lab \
      --region us-central1 \
      --project={{PROJECT_ID}}

# Test connection
test PROJECT_ID:
    #!/usr/bin/env bash
    URL=$(gcloud run services describe cmd-injection-lab --region us-central1 --project={{PROJECT_ID}} --format='value(status.url)')
    echo "Testing vulnerable endpoint..."
    curl -s -X POST -d "seconds=1" "$URL/vulnerable.php"
    echo -e "\n\nTesting safe endpoint..."
    curl -s -X POST -d "seconds=1" "$URL/safe.php"
