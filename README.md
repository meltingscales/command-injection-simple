# Command Injection Lab - Sleep Timer

An educational lab demonstrating command injection vulnerabilities using a simple sleep timer implemented in PHP.

## Overview

This lab provides two versions of a web-based sleep timer:

1. **Vulnerable Version** (`vulnerable.php`) - Demonstrates command injection vulnerability
2. **Safe Version** (`safe.php`) - Shows proper input validation and secure coding practices

## Educational Purpose

**⚠️ WARNING: This lab is for educational purposes only!**

- Use only in controlled, isolated environments
- Never deploy the vulnerable version to production
- This demonstrates real security vulnerabilities for learning

## Project Structure

```
.
├── index.html          # Main frontend interface
├── vulnerable.php      # Vulnerable backend (command injection)
├── safe.php           # Secure backend (properly validated)
├── Dockerfile         # Container configuration
├── justfile           # Command runner with all deployment commands
├── .dockerignore      # Docker ignore file
└── README.md          # This file
```

## Quick Start (Local Development)

### Prerequisites
- Docker installed on your system
- [just](https://github.com/casey/just) command runner (optional but recommended)

### Running Locally

Using just (recommended):
```bash
# Build and run in one command
just up

# Or run individual commands
just build
just run

# View logs
just logs

# Stop the container
just stop

# Clean up everything
just clean
```

Or using Docker directly:
```bash
# Build the Docker image
docker build -t command-injection-lab .

# Run the container
docker run -d -p 8080:80 --name command-injection-lab command-injection-lab

# Access at http://localhost:8080

# Stop the container
docker stop command-injection-lab
docker rm command-injection-lab
```

## Deployment to Google Cloud Platform (GCP)

### Prerequisites

- Google Cloud account with billing enabled
- `gcloud` CLI installed and configured
- Project created in GCP
- [just](https://github.com/casey/just) command runner (optional but recommended)

### Configuration

Set your GCP project configuration:

```bash
# Set environment variables (or edit justfile defaults)
export PROJECT_ID="your-project-id"
export REGION="us-central1"
export ZONE="us-central1-a"

# View current configuration
just config
```

### Option 1: Deploy to Cloud Run (Recommended)

Cloud Run is a managed serverless platform that's cost-effective and easy to use.

Using just:
```bash
# Setup GCP project (first time only)
just gcp-setup

# Build, deploy, and get URL in one command
just cloudrun-up

# Or run individual steps
just cloudrun-build
just cloudrun-deploy
just cloudrun-url

# View logs
just cloudrun-logs

# Clean up
just cloudrun-down
```

Or using gcloud directly:
```bash
# Login and configure
gcloud auth login
export PROJECT_ID="your-project-id"
export REGION="us-central1"
gcloud config set project $PROJECT_ID

# Enable APIs
gcloud services enable cloudbuild.googleapis.com run.googleapis.com

# Build and deploy
gcloud builds submit --tag gcr.io/$PROJECT_ID/command-injection-lab
gcloud run deploy command-injection-lab \
  --image gcr.io/$PROJECT_ID/command-injection-lab \
  --platform managed --region $REGION \
  --allow-unauthenticated --port 80 --memory 512Mi

# Get URL
gcloud run services describe command-injection-lab \
  --region $REGION --format 'value(status.url)'
```

### Option 2: Deploy to Google Kubernetes Engine (GKE)

For more control and learning about Kubernetes deployments.

Using just:
```bash
# Create cluster
just gke-create-cluster

# Setup Artifact Registry
just gke-setup-registry

# Build and push image
just gke-build

# Deploy to GKE (generates k8s-deployment.yaml and applies it)
just gke-deploy

# Get external IP (run after a few minutes)
just gke-ip

# Clean up
just gke-down
```

Or using gcloud/kubectl directly:
```bash
# Create cluster
gcloud container clusters create cmd-injection-cluster \
  --zone us-central1-a --num-nodes 2 --machine-type e2-small

# Setup registry
gcloud artifacts repositories create docker-repo \
  --repository-format=docker --location=$REGION
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Build and push
docker build -t ${REGION}-docker.pkg.dev/$PROJECT_ID/docker-repo/command-injection-lab:v1 .
docker push ${REGION}-docker.pkg.dev/$PROJECT_ID/docker-repo/command-injection-lab:v1

# Deploy (create k8s-deployment.yaml first, see justfile for template)
kubectl apply -f k8s-deployment.yaml
kubectl get service command-injection-lab --watch
```

### Option 3: Deploy to Compute Engine (VM)

For maximum control over the environment.

Using just:
```bash
# Deploy VM (requires image built to GCR first)
just cloudrun-build  # Build image to GCR
just compute-deploy

# Get external IP
just compute-ip

# SSH into VM (optional)
just compute-ssh

# Clean up
just compute-down
```

Or using gcloud directly:
```bash
# Deploy VM with container
gcloud compute instances create-with-container cmd-injection-vm \
  --container-image=gcr.io/$PROJECT_ID/command-injection-lab \
  --machine-type=e2-micro --zone=us-central1-a --tags=http-server

# Create firewall rule
gcloud compute firewall-rules create allow-http \
  --allow tcp:80 --target-tags http-server --source-ranges 0.0.0.0/0

# Get IP
gcloud compute instances describe cmd-injection-vm \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

## Understanding the Vulnerabilities

### Vulnerable Version

The vulnerable version directly concatenates user input into a shell command:

```php
$command = "sleep " . $seconds;
exec($command);
```

This allows attackers to inject additional commands using shell metacharacters.

### Example Exploits

Try these inputs on the **vulnerable version**:

1. `5; whoami` - Execute whoami after sleep
2. `2; ls -la` - List directory contents
3. `1; cat /etc/passwd` - Read system files
4. `3 && echo "Injected!"` - Use AND operator
5. `1 | cat /etc/hostname` - Use pipe operator

### Safe Version

The safe version implements multiple defenses:

1. **Input validation** - Checks if input is numeric
2. **Type casting** - Converts to integer
3. **Bounds checking** - Enforces reasonable limits (0-30 seconds)
4. **Escaping** - Uses `escapeshellarg()` for additional protection

```php
if (!is_numeric($seconds)) {
    echo json_encode(['error' => 'Invalid input']);
    exit;
}

$seconds_int = intval($seconds);

if ($seconds_int < 0 || $seconds_int > 30) {
    echo json_encode(['error' => 'Out of bounds']);
    exit;
}

$safe_seconds = escapeshellarg($seconds_int);
```

## Security Best Practices Demonstrated

1. **Input Validation** - Always validate and sanitize user input
2. **Type Checking** - Ensure input matches expected type
3. **Whitelisting** - Allow only known-good patterns
4. **Bounds Checking** - Enforce reasonable limits
5. **Escaping** - Use proper escaping functions
6. **Least Privilege** - Run processes with minimal permissions
7. **Avoid Shell Execution** - Use native functions when possible

## Cost Estimation (GCP)

### Cloud Run (Most Cost-Effective)
- **Free tier**: 2 million requests/month
- **Typical cost**: $0-5/month for learning purposes
- **Best for**: Educational labs, demos

### GKE
- **Cost**: ~$75/month (cluster + nodes)
- **Best for**: Learning Kubernetes

### Compute Engine
- **e2-micro**: ~$7-10/month
- **Best for**: Long-running instances

## Available Just Commands

Run `just` or `just --list` to see all available commands:

```bash
just --list
```

Key commands:
- **Local**: `up`, `build`, `run`, `stop`, `logs`, `restart`, `clean`
- **Cloud Run**: `cloudrun-up`, `cloudrun-build`, `cloudrun-deploy`, `cloudrun-url`, `cloudrun-logs`, `cloudrun-down`
- **GKE**: `gke-create-cluster`, `gke-setup-registry`, `gke-build`, `gke-deploy`, `gke-ip`, `gke-down`
- **Compute Engine**: `compute-deploy`, `compute-ip`, `compute-ssh`, `compute-down`
- **Setup**: `gcp-setup`, `config`

## Troubleshooting

### Container won't start
```bash
# Check logs locally
just logs
# Or: docker logs command-injection-lab

# For Cloud Run
just cloudrun-logs
```

### View current configuration
```bash
just config
```

### Test endpoints locally
```bash
just test
```

## Learning Resources

- [OWASP Command Injection](https://owasp.org/www-community/attacks/Command_Injection)
- [PHP Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/PHP_Configuration_Cheat_Sheet.html)
- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)

## License

This educational lab is provided as-is for learning purposes.

## Disclaimer

This software contains intentional security vulnerabilities and should only be used in isolated, educational environments. The authors are not responsible for any misuse of this software.
