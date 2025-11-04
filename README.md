# Command Injection Lab - Sleep Timer

An educational lab demonstrating command injection vulnerabilities using a simple sleep timer implemented in PHP.

See [CURL.md](./CURL.md) for examples of injection attacks you can run in the terminal.

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

## Quick Start (Cloud Run Deployment)

Deploy to Google Cloud Run for an automatic `*.run.app` domain:

```bash
just deploy YOUR_PROJECT_ID
```

This will build and deploy the lab, giving you a URL like `https://cmd-injection-lab-xxxxx-uc.a.run.app`

### Available Commands

```bash
just deploy PROJECT_ID      # Deploy to Cloud Run
just get-url PROJECT_ID     # Get your service URL
just logs PROJECT_ID        # View logs
just logs-follow PROJECT_ID # Follow logs in real-time
just test PROJECT_ID        # Test both endpoints
just delete PROJECT_ID      # Delete the service
```

### Benefits

- **No IP blocking**: Gets automatic `*.run.app` domain
- **Cost effective**: Only pay when handling requests (likely free tier)
- **Auto-scaling**: Scales to zero when idle
- **No infrastructure**: No VMs to manage

## Prerequisites
- [just](https://github.com/casey/just) command runner
- gcloud CLI configured with your GCP project

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

### Quick Setup (10 minutes)

#### 1. Set Your Project ID

First, set your GCP project ID as an environment variable:

```bash
export PROJECT_ID="your-project-id"
```

#### 2. Create GCP Compute Engine Instance

```bash
gcloud compute instances create cmd-injection-vm \
  --project=$PROJECT_ID \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=cos-stable \
  --image-project=cos-cloud \
  --boot-disk-size=10GB \
  --tags=http-server
```

Or using just:
```bash
just gcp-create-instance
```

#### 3. Create Firewall Rule

```bash
gcloud compute firewall-rules create allow-http-cmd-injection \
  --project=$PROJECT_ID \
  --allow=tcp:80 \
  --target-tags=http-server
```

Or using just:
```bash
just gcp-create-firewall
```

#### 4. Copy Files and Build Container

Copy files to the GCP instance:

```bash
gcloud compute scp --zone=us-central1-a --recurse \
  Dockerfile index.html vulnerable.php safe.php \
  cmd-injection-vm:~/
```

Or using just:
```bash
just gcp-copy-files
```

SSH into the instance:

```bash
gcloud compute ssh cmd-injection-vm --zone=us-central1-a
```

Or using just:
```bash
just gcp-ssh
```

Build and run the container:

```bash
docker build -t command-injection-lab .
docker run -d -p 80:80 --name command-injection-lab command-injection-lab
```

#### 5. Fix Container-Optimized OS Firewall

Container-Optimized OS has iptables rules that block external traffic. Add a rule to allow port 80:

```bash
sudo iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
```

Exit the SSH session:

```bash
exit
```

#### 6. Get External IP

```bash
gcloud compute instances describe cmd-injection-vm \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

Or using just:
```bash
just gcp-ip
```

#### 7. Test the Application

```bash
curl http://YOUR_EXTERNAL_IP
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

## Viewing Logs

View container logs:

```bash
gcloud compute ssh cmd-injection-vm --zone=us-central1-a \
  --command="docker logs command-injection-lab"
```

Or using just:
```bash
just gcp-logs
```

## Clean Up

Delete all GCP resources when done:

```bash
gcloud compute instances delete cmd-injection-vm --zone=us-central1-a
gcloud compute firewall-rules delete allow-http-cmd-injection
```

Or using just:
```bash
just gcp-cleanup
```

## Cost Estimation

- **e2-micro**: ~$6/month (730 hours)
- **Egress**: Minimal for lab use
- **Remember to delete when not in use!**

## Available Just Commands

Run `just` or `just --list` to see all available commands:

```bash
just --list
```

Key commands:
- **Local Docker**: `up`, `build`, `run`, `stop`, `logs`, `restart`, `clean`
- **GCP**: `gcp-create-instance`, `gcp-create-firewall`, `gcp-copy-files`, `gcp-ssh`, `gcp-ip`, `gcp-logs`, `gcp-cleanup`
- **Config**: `config`, `test`

## Troubleshooting

### Container won't start locally
```bash
# Check logs
just logs
# Or: docker logs command-injection-lab
```

### Container won't start on GCP
```bash
# Check container logs on VM
just gcp-logs

# Or SSH and check manually
just gcp-ssh
docker ps -a
docker logs command-injection-lab
```

### Can't connect to external IP
Make sure you ran the iptables command in the SSH session:
```bash
sudo iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
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
