# Nylas Webhook Test Server

A simple Go server for receiving and testing webhooks, designed to be deployed on **Fly.io**.

Perfect for testing Nylas webhook integrations or any webhook-based service during development. This server logs all incoming webhooks with detailed formatting, handles webhook challenges, and provides metrics for monitoring.

## 📋 Table of Contents
- [Quick Start](#-quick-start)
- [What This Server Does](#-what-this-server-does)
- [Detailed Deployment Guide](#-detailed-deployment-guide)
- [Usage Examples](#-usage-examples)
- [Local Development](#-local-development)
- [Understanding the Cost](#-understanding-the-cost)
- [Troubleshooting](#-troubleshooting)
- [Cleanup](#-cleanup)

## 🚀 Quick Start

The fastest way to get your webhook server running on Fly.io:

```bash
# Fork this repository (click Fork button on GitHub)
# This gives you your own copy to customize

# Clone YOUR forked repository
git clone https://github.com/YOUR-USERNAME/webhook-server
cd webhook-server

# Run the automated deployment script
./deploy-auto.sh
```

The deployment script will guide you through choosing a unique app name for your webhook server. This is important because each Fly.io app needs a globally unique name (like a domain name).

## 🎯 What This Server Does

This webhook server is specifically designed to help developers test and debug webhook integrations. Here's what it provides:

**Core Features:**
- **Receives and logs webhook POSTs** with pretty-formatted JSON output
- **Handles webhook challenges** automatically (responds to GET requests with `?challenge=` parameter)
- **Shows request size** in human-readable format (bytes/KB/MB)
- **Captures webhook signatures** (like Nylas `x-nylas-signature` header for verification)
- **Pretty-prints JSON payloads** for easy reading and debugging
- **Provides Prometheus metrics** at `/metrics` endpoint for monitoring
- **Health check endpoint** at `/health` for uptime monitoring
- **Auto-sleeps when idle** to minimize costs (Fly.io feature)

## 📚 Detailed Deployment Guide

### Prerequisites

Before deploying, you'll need:

1. **A Fly.io account** (free to create at [fly.io](https://fly.io))
2. **The Fly.io CLI tool** installed on your machine

Installing the Fly.io CLI:
```bash
# macOS (using Homebrew)
brew install flyctl

# Linux
curl -L https://fly.io/install.sh | sh

# Windows
powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"
```

### Step-by-Step Deployment

1. **Fork this repository first** (important!)
   
   Forking creates your own copy of the code that you can modify and deploy independently. Click the "Fork" button at the top of this repository's GitHub page.

2. **Clone your forked repository**
   ```bash
   git clone https://github.com/YOUR-USERNAME/webhook-server
   cd webhook-server
   ```

3. **Login to Fly.io**
   ```bash
   flyctl auth login
   ```
   This opens your browser for authentication.

4. **Run the deployment script**
   ```bash
   ./deploy-auto.sh
   ```

5. **Choose your app name**
   
   The script will detect that this repository contains a pre-configured `fly.toml` file and offer you three options:
   
   - **Option 1: Enter a custom app name** (Recommended)
     - Choose something meaningful like `yourname-webhook-test`
     - Must be globally unique across all Fly.io apps
     - Can only contain lowercase letters, numbers, and hyphens
   
   - **Option 2: Keep the existing name**
     - Only choose this if you actually own the `webhooks-server-nylas-testing` app
     - Will fail if someone else already deployed with this name
   
   - **Option 3: Let Fly.io auto-generate a name**
     - Fly.io will create a random unique name like `wild-butterfly-1234`
     - Good option if you don't care about the URL

6. **Wait for deployment**
   
   The script will handle all the configuration and deployment steps. This typically takes 1-2 minutes.

7. **Get your webhook URLs**
   
   After successful deployment, you'll see:
   ```
   ✅ Deployed successfully!
   🌐 Webhook URL: https://your-app-name.fly.dev/
   ❤️  Health check: https://your-app-name.fly.dev/health
   📊 Metrics: https://your-app-name.fly.dev/metrics
   ```

### Understanding What Just Happened

When you ran the deployment script, several things occurred behind the scenes:

1. **App Creation**: Fly.io created a new application with your chosen name
2. **Container Building**: Your Go code was compiled and packaged into a Docker container
3. **Global Deployment**: The container was deployed to Fly.io's infrastructure
4. **URL Assignment**: Your app was assigned a public URL at `https://your-app-name.fly.dev`
5. **Health Monitoring**: Fly.io configured health checks to monitor your app

The `fly.toml` file contains all the configuration for your deployment, including memory limits, health check settings, and auto-scaling rules.

## 📋 Usage Examples

### Testing Webhook Delivery

Once deployed, you can use your webhook URL in any service that sends webhooks. For example, with Nylas:

1. Go to your Nylas dashboard
2. Navigate to Webhooks settings
3. Add your webhook URL: `https://your-app-name.fly.dev/`
4. Nylas will send a challenge request to verify the endpoint
5. Your server automatically responds to the challenge
6. Start receiving real webhook notifications!

### Viewing Real-time Logs

To see webhooks as they arrive:
```bash
flyctl logs --app your-app-name
```

Or if you're in the project directory:
```bash
flyctl logs
```

You'll see formatted output like:
```
2024-11-14T10:23:45Z app[abc123] sjc [info] Received challenge code: abc123xyz
2024-11-14T10:24:01Z app[abc123] sjc [info] This is the signature: t=1234567890,v1=abc...
2024-11-14T10:24:01Z app[abc123] sjc [info] Webhook size: 2.34 KB
2024-11-14T10:24:01Z app[abc123] sjc [info] Received JSON body:
{
    "specversion": "1.0",
    "type": "message.created",
    "data": {
        "id": "message_123",
        "object": "message"
    }
}
```

### Monitoring Your Webhook Server

Visit your metrics endpoint to see Prometheus metrics:
```
https://your-app-name.fly.dev/metrics
```

This shows:
- Total request count by HTTP method
- Request duration histograms
- Go runtime metrics
- Process metrics

### Testing Locally Before Deployment

You can test the webhook server on your local machine:
```bash
# Install dependencies
go mod download

# Run the server
PORT=3000 go run main.go

# In another terminal, test it
curl http://localhost:3000/health
curl -X POST http://localhost:3000/ -d '{"test": "webhook"}'
```

## 💰 Understanding the Cost

Fly.io's pricing model is very developer-friendly for testing purposes:

**Free Resources:**
- $5/month in free credits (automatically applied)
- This covers approximately 2,592,000 seconds of compute time for the smallest VM
- Your webhook server automatically stops when not receiving requests (zero cost while idle)
- Restarts instantly when a webhook arrives

**What This Means:**
- For typical webhook testing, you'll likely never exceed the free tier
- The server only consumes resources when actively processing webhooks
- No charges for the public IP address or bandwidth for testing volumes

**Monitoring Usage:**
```bash
flyctl billing --app your-app-name
```

## 🔧 Configuration Details

### Environment Variables

The server uses these environment variables:

- `PORT`: The port the server listens on (default: 3000)
  - Set automatically by Fly.io
  - Can be overridden in fly.toml

### Fly.io Configuration (fly.toml)

Key settings in your fly.toml:

```toml
[http_service]
  internal_port = 3000          # Port your app listens on
  force_https = true            # All traffic forced to HTTPS
  auto_stop_machines = 'stop'   # Stop when idle
  auto_start_machines = true    # Start on incoming request
  min_machines_running = 0      # Can scale to zero

[[vm]]
  memory = '1gb'               # Memory allocation
  cpu_kind = 'shared'          # Shared CPU (cost-effective)
  cpus = 1                     # Number of CPUs
```

## 🐛 Troubleshooting

### Common Issues and Solutions

**"App name already taken" error:**
- Someone else is using that app name
- Run the deployment script again and choose a different name

**"Authentication required" error:**
- Run `flyctl auth login` to authenticate
- Make sure you have a Fly.io account

**Webhooks not being received:**
- Check that your webhook service is using HTTPS (not HTTP)
- Verify the URL is exactly `https://your-app-name.fly.dev/` (trailing slash matters for some services)
- Check logs with `flyctl logs` for any errors

**Server returns 502 Bad Gateway:**
- The server might be starting up (wait 10-15 seconds)
- Check logs for any crash errors
- Try `flyctl restart` to force a restart

**Challenge verification failing:**
- Ensure your webhook service sends the challenge as a query parameter
- The server expects `GET /?challenge=YOUR_CHALLENGE_CODE`
- Check logs to see what's being received

### Checking Server Status

```bash
# See if your app is running
flyctl status

# View recent logs
flyctl logs

# Force a restart if needed
flyctl restart

# Open your app in the browser
flyctl open
```

## 🗑️ Cleanup

When you're done testing, you can delete your webhook server to ensure no future charges:

```bash
# Delete the app (this is permanent!)
flyctl destroy --app your-app-name
```

Or if you're in the project directory:
```bash
flyctl destroy
```

This will:
- Stop and delete your application
- Remove all associated resources
- Prevent any future charges

## 🔧 Advanced Usage

### Customizing the Server

Since you forked the repository, you can modify the server code to add features:

1. **Add authentication**: Modify `main.go` to check for a secret header
2. **Store webhooks**: Add database integration to store webhook history
3. **Filter webhooks**: Add logic to only log specific webhook types
4. **Add Slack notifications**: Send important webhooks to a Slack channel

After making changes:
```bash
# Commit your changes
git add .
git commit -m "Add custom webhook filtering"

# Deploy the updated version
flyctl deploy
```

### Multiple Environments

You can deploy multiple instances for different testing scenarios:

```bash
# Deploy a staging version
flyctl launch --name yourname-webhook-staging

# Deploy a version for a specific client
flyctl launch --name yourname-webhook-clientx
```

Each deployment is independent with its own URL and logs.

## 📚 Resources

- [Fly.io Documentation](https://fly.io/docs/)
- [Nylas Webhooks Guide](https://developer.nylas.com/docs/developer-guide/webhooks/)
- [Go HTTP Server Basics](https://golang.org/doc/articles/wiki/)
- [Prometheus Metrics](https://prometheus.io/docs/guides/go-application/)

---

*Need help? Open an issue in this repository or check the [Fly.io community forum](https://community.fly.io/).*
