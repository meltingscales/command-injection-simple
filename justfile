# Command Injection Lab - Justfile
# Run commands with: just <command-name>

# Default values - customize these
project_id := env_var_or_default('PROJECT_ID', 'your-project-id')
region := env_var_or_default('REGION', 'us-central1')
zone := env_var_or_default('ZONE', 'us-central1-a')
image_name := "command-injection-lab"

# Show available commands
default:
    @just --list

# === Docker Commands ===

# Build the Docker image
build:
    docker build -t {{image_name}} .

# Run the container locally on port 8080
run:
    docker run -d -p 8080:80 --name {{image_name}} {{image_name}}
    @echo "Application running at http://localhost:8080"

# Stop the running container
stop:
    docker stop {{image_name}}
    docker rm {{image_name}}

# View container logs
logs:
    docker logs -f {{image_name}}

# Restart the container
restart: stop run

# Build and run
up: build run

# Clean up Docker resources
clean:
    -docker stop {{image_name}}
    -docker rm {{image_name}}
    -docker rmi {{image_name}}

# === GCP Setup ===

# Configure gcloud project
gcp-setup:
    @echo "Setting up GCP project: {{project_id}}"
    gcloud config set project {{project_id}}
    gcloud services enable cloudbuild.googleapis.com
    gcloud services enable run.googleapis.com
    gcloud services enable artifactregistry.googleapis.com
    @echo "GCP setup complete!"

# === Cloud Run Deployment ===

# Build image using Cloud Build
cloudrun-build:
    gcloud builds submit --tag gcr.io/{{project_id}}/{{image_name}}

# Deploy to Cloud Run
cloudrun-deploy:
    gcloud run deploy {{image_name}} \
        --image gcr.io/{{project_id}}/{{image_name}} \
        --platform managed \
        --region {{region}} \
        --allow-unauthenticated \
        --port 80 \
        --memory 512Mi

# Build and deploy to Cloud Run
cloudrun-up: cloudrun-build cloudrun-deploy
    @echo "\nDeployment complete! Getting URL..."
    @just cloudrun-url

# Get Cloud Run service URL
cloudrun-url:
    @gcloud run services describe {{image_name}} \
        --region {{region}} \
        --format 'value(status.url)'

# View Cloud Run logs
cloudrun-logs:
    gcloud run services logs read {{image_name}} --region {{region}}

# Delete Cloud Run service
cloudrun-down:
    gcloud run services delete {{image_name}} --region {{region}} --quiet
    gcloud container images delete gcr.io/{{project_id}}/{{image_name}} --quiet

# === GKE Deployment ===

# Create GKE cluster
gke-create-cluster:
    gcloud container clusters create cmd-injection-cluster \
        --zone {{zone}} \
        --num-nodes 2 \
        --machine-type e2-small \
        --enable-autoscaling \
        --min-nodes 1 \
        --max-nodes 3
    gcloud container clusters get-credentials cmd-injection-cluster --zone {{zone}}

# Setup Artifact Registry
gke-setup-registry:
    gcloud artifacts repositories create docker-repo \
        --repository-format=docker \
        --location={{region}}
    gcloud auth configure-docker {{region}}-docker.pkg.dev

# Build and push to Artifact Registry
gke-build:
    docker build -t {{region}}-docker.pkg.dev/{{project_id}}/docker-repo/{{image_name}}:v1 .
    docker push {{region}}-docker.pkg.dev/{{project_id}}/docker-repo/{{image_name}}:v1

# Generate Kubernetes deployment file
gke-generate-yaml:
    @echo "apiVersion: apps/v1" > k8s-deployment.yaml
    @echo "kind: Deployment" >> k8s-deployment.yaml
    @echo "metadata:" >> k8s-deployment.yaml
    @echo "  name: {{image_name}}" >> k8s-deployment.yaml
    @echo "spec:" >> k8s-deployment.yaml
    @echo "  replicas: 2" >> k8s-deployment.yaml
    @echo "  selector:" >> k8s-deployment.yaml
    @echo "    matchLabels:" >> k8s-deployment.yaml
    @echo "      app: {{image_name}}" >> k8s-deployment.yaml
    @echo "  template:" >> k8s-deployment.yaml
    @echo "    metadata:" >> k8s-deployment.yaml
    @echo "      labels:" >> k8s-deployment.yaml
    @echo "        app: {{image_name}}" >> k8s-deployment.yaml
    @echo "    spec:" >> k8s-deployment.yaml
    @echo "      containers:" >> k8s-deployment.yaml
    @echo "      - name: {{image_name}}" >> k8s-deployment.yaml
    @echo "        image: {{region}}-docker.pkg.dev/{{project_id}}/docker-repo/{{image_name}}:v1" >> k8s-deployment.yaml
    @echo "        ports:" >> k8s-deployment.yaml
    @echo "        - containerPort: 80" >> k8s-deployment.yaml
    @echo "---" >> k8s-deployment.yaml
    @echo "apiVersion: v1" >> k8s-deployment.yaml
    @echo "kind: Service" >> k8s-deployment.yaml
    @echo "metadata:" >> k8s-deployment.yaml
    @echo "  name: {{image_name}}" >> k8s-deployment.yaml
    @echo "spec:" >> k8s-deployment.yaml
    @echo "  type: LoadBalancer" >> k8s-deployment.yaml
    @echo "  selector:" >> k8s-deployment.yaml
    @echo "    app: {{image_name}}" >> k8s-deployment.yaml
    @echo "  ports:" >> k8s-deployment.yaml
    @echo "  - port: 80" >> k8s-deployment.yaml
    @echo "    targetPort: 80" >> k8s-deployment.yaml
    @echo "Generated k8s-deployment.yaml"

# Deploy to GKE
gke-deploy: gke-generate-yaml
    kubectl apply -f k8s-deployment.yaml
    @echo "\nWaiting for external IP (this may take a few minutes)..."
    @echo "Run: kubectl get service {{image_name}} --watch"

# Get GKE service IP
gke-ip:
    kubectl get service {{image_name}} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Delete GKE deployment
gke-down:
    kubectl delete -f k8s-deployment.yaml || true
    gcloud container clusters delete cmd-injection-cluster --zone {{zone}} --quiet

# === Compute Engine Deployment ===

# Deploy to Compute Engine VM
compute-deploy:
    gcloud compute instances create-with-container cmd-injection-vm \
        --container-image=gcr.io/{{project_id}}/{{image_name}} \
        --machine-type=e2-micro \
        --zone={{zone}} \
        --tags=http-server
    gcloud compute firewall-rules create allow-http \
        --allow tcp:80 \
        --target-tags http-server \
        --source-ranges 0.0.0.0/0 || true

# Get Compute Engine external IP
compute-ip:
    @gcloud compute instances describe cmd-injection-vm \
        --zone={{zone}} \
        --format='get(networkInterfaces[0].accessConfigs[0].natIP)'

# SSH into Compute Engine VM
compute-ssh:
    gcloud compute ssh cmd-injection-vm --zone={{zone}}

# Delete Compute Engine deployment
compute-down:
    gcloud compute instances delete cmd-injection-vm --zone={{zone}} --quiet
    gcloud compute firewall-rules delete allow-http --quiet

# === Helper Commands ===

# Show current configuration
config:
    @echo "Current Configuration:"
    @echo "  Project ID: {{project_id}}"
    @echo "  Region:     {{region}}"
    @echo "  Zone:       {{zone}}"
    @echo "  Image:      {{image_name}}"
    @echo ""
    @echo "To override, set environment variables:"
    @echo "  export PROJECT_ID=my-project"
    @echo "  export REGION=us-west1"
    @echo "  export ZONE=us-west1-a"

# Test application locally (requires running container)
test:
    @echo "Testing vulnerable endpoint..."
    @curl -s -X POST -d "seconds=2" http://localhost:8080/vulnerable.php | jq .
    @echo "\nTesting safe endpoint..."
    @curl -s -X POST -d "seconds=2" http://localhost:8080/safe.php | jq .
