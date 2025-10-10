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
├── .dockerignore      # Docker ignore file
└── README.md          # This file
```

## Quick Start (Local Development)

### Prerequisites
- Docker installed on your system

### Running Locally

1. Build the Docker image:
```bash
docker build -t command-injection-lab .
```

2. Run the container:
```bash
docker run -d -p 8080:80 --name cmd-injection-lab command-injection-lab
```

3. Access the application:
```
http://localhost:8080
```

4. Stop the container:
```bash
docker stop cmd-injection-lab
docker rm cmd-injection-lab
```

## Deployment to Google Cloud Platform (GCP)

### Prerequisites

- Google Cloud account with billing enabled
- `gcloud` CLI installed and configured
- Project created in GCP

### Option 1: Deploy to Cloud Run (Recommended)

Cloud Run is a managed serverless platform that's cost-effective and easy to use.

#### Step 1: Set up gcloud

```bash
# Login to Google Cloud
gcloud auth login

# Set your project ID
export PROJECT_ID="your-project-id"
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

#### Step 2: Build and push the container

```bash
# Set region
export REGION="us-central1"

# Build the image using Cloud Build
gcloud builds submit --tag gcr.io/$PROJECT_ID/command-injection-lab
```

#### Step 3: Deploy to Cloud Run

```bash
# Deploy the container
gcloud run deploy command-injection-lab \
  --image gcr.io/$PROJECT_ID/command-injection-lab \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --port 80 \
  --memory 512Mi

# Get the deployed URL
gcloud run services describe command-injection-lab \
  --region $REGION \
  --format 'value(status.url)'
```

#### Step 4: Access your application

The command above will output a URL like: `https://command-injection-lab-xxxxx-uc.a.run.app`

Visit this URL to access your lab.

#### Clean up Cloud Run deployment

```bash
# Delete the service
gcloud run services delete command-injection-lab --region $REGION

# Delete the container image
gcloud container images delete gcr.io/$PROJECT_ID/command-injection-lab
```

### Option 2: Deploy to Google Kubernetes Engine (GKE)

For more control and learning about Kubernetes deployments.

#### Step 1: Create a GKE cluster

```bash
# Set variables
export CLUSTER_NAME="cmd-injection-cluster"
export ZONE="us-central1-a"

# Create a small cluster
gcloud container clusters create $CLUSTER_NAME \
  --zone $ZONE \
  --num-nodes 2 \
  --machine-type e2-small \
  --enable-autoscaling \
  --min-nodes 1 \
  --max-nodes 3

# Get credentials
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE
```

#### Step 2: Build and push image to Artifact Registry

```bash
# Create repository
gcloud artifacts repositories create docker-repo \
  --repository-format=docker \
  --location=$REGION

# Configure Docker
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Build and push
docker build -t ${REGION}-docker.pkg.dev/$PROJECT_ID/docker-repo/command-injection-lab:v1 .
docker push ${REGION}-docker.pkg.dev/$PROJECT_ID/docker-repo/command-injection-lab:v1
```

#### Step 3: Deploy to GKE

Create a deployment file `k8s-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: command-injection-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: command-injection-lab
  template:
    metadata:
      labels:
        app: command-injection-lab
    spec:
      containers:
      - name: command-injection-lab
        image: REGION-docker.pkg.dev/PROJECT_ID/docker-repo/command-injection-lab:v1
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: command-injection-lab
spec:
  type: LoadBalancer
  selector:
    app: command-injection-lab
  ports:
  - port: 80
    targetPort: 80
```

Deploy:

```bash
# Update the YAML with your values
sed -i "s/REGION/$REGION/g" k8s-deployment.yaml
sed -i "s/PROJECT_ID/$PROJECT_ID/g" k8s-deployment.yaml

# Apply the deployment
kubectl apply -f k8s-deployment.yaml

# Wait for external IP
kubectl get service command-injection-lab --watch
```

#### Clean up GKE deployment

```bash
# Delete Kubernetes resources
kubectl delete -f k8s-deployment.yaml

# Delete the cluster
gcloud container clusters delete $CLUSTER_NAME --zone $ZONE
```

### Option 3: Deploy to Compute Engine (VM)

For maximum control over the environment.

#### Step 1: Create a VM instance

```bash
# Create VM with container-optimized OS
gcloud compute instances create-with-container cmd-injection-vm \
  --container-image=gcr.io/$PROJECT_ID/command-injection-lab \
  --machine-type=e2-micro \
  --zone=us-central1-a \
  --tags=http-server

# Create firewall rule
gcloud compute firewall-rules create allow-http \
  --allow tcp:80 \
  --target-tags http-server \
  --source-ranges 0.0.0.0/0
```

#### Step 2: Get the external IP

```bash
gcloud compute instances describe cmd-injection-vm \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

Visit `http://EXTERNAL_IP` to access the lab.

#### Clean up Compute Engine deployment

```bash
# Delete the VM
gcloud compute instances delete cmd-injection-vm --zone=us-central1-a

# Delete firewall rule
gcloud compute firewall-rules delete allow-http
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

## Troubleshooting

### Container won't start
```bash
# Check logs
docker logs cmd-injection-lab

# Or for Cloud Run
gcloud run services logs read command-injection-lab --region $REGION
```

### Permission issues
```bash
# Ensure proper permissions in container
docker exec -it cmd-injection-lab ls -la /var/www/html
```

### Firewall issues
```bash
# List firewall rules
gcloud compute firewall-rules list

# Ensure HTTP access is allowed
gcloud compute firewall-rules describe allow-http
```

## Learning Resources

- [OWASP Command Injection](https://owasp.org/www-community/attacks/Command_Injection)
- [PHP Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/PHP_Configuration_Cheat_Sheet.html)
- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)

## License

This educational lab is provided as-is for learning purposes.

## Disclaimer

This software contains intentional security vulnerabilities and should only be used in isolated, educational environments. The authors are not responsible for any misuse of this software.
