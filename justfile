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

# === GCP Compute Engine Deployment ===

# Create GCP VM instance with Container-Optimized OS
gcp-create-instance:
    gcloud compute instances create cmd-injection-vm \
        --project={{project_id}} \
        --zone={{zone}} \
        --machine-type=e2-micro \
        --image-family=cos-stable \
        --image-project=cos-cloud \
        --boot-disk-size=10GB \
        --tags=http-server

# Create firewall rule to allow HTTP traffic
gcp-create-firewall:
    gcloud compute firewall-rules create allow-http-cmd-injection \
        --project={{project_id}} \
        --allow=tcp:80 \
        --target-tags=http-server

# Copy files to GCP instance
gcp-copy-files:
    gcloud compute scp --zone={{zone}} --recurse \
        Dockerfile index.html vulnerable.php safe.php \
        cmd-injection-vm:~/

# Build and run container on VM (run after SSH)
gcp-build-container:
    @echo "Run these commands after SSHing into the VM:"
    @echo "  docker build -t {{image_name}} ."
    @echo "  docker run -d -p 80:80 --name {{image_name}} {{image_name}}"
    @echo "  sudo iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT"

# SSH into the GCP instance
gcp-ssh:
    gcloud compute ssh cmd-injection-vm --zone={{zone}}

# Get the external IP of the instance
gcp-ip:
    @gcloud compute instances describe cmd-injection-vm \
        --zone={{zone}} \
        --format='get(networkInterfaces[0].accessConfigs[0].natIP)'

# View container logs
gcp-logs:
    gcloud compute ssh cmd-injection-vm --zone={{zone}} \
        --command="docker logs {{image_name}}"

# Delete GCP resources
gcp-cleanup:
    gcloud compute instances delete cmd-injection-vm --zone={{zone}} --quiet
    gcloud compute firewall-rules delete allow-http-cmd-injection --quiet

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
