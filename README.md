# Nylas Webhook Test Server

A simple Go server for receiving and testing webhooks, designed to be deployed on **Fly.io**.

Perfect for testing Nylas webhook integrations or any webhook-based service during development.

## ⚡ Quick Deploy to Fly.io

### Option 1: Automatic Deploy (Recommended)
```bash
# Fork this repo first (click the Fork button on GitHub)
# Then clone YOUR fork
git clone https://github.com/YOUR-USERNAME/webhook-server
cd webhook-server

# Deploy to Fly.io
./deploy-auto.sh
```

### Option 2: Manual Deploy
```bash
# Install Fly.io CLI if you don't have it
curl -L https://fly.io/install.sh | sh

# Login to Fly.io (free account)
flyctl auth login

# Deploy (Fly.io will auto-generate app name)
flyctl launch
```

### Your Webhook URLs
After deployment, you'll get:
- **Webhook endpoint**: `https://your-app-name.fly.dev/`
- **Health check**: `https://your-app-name.fly.dev/health`
- **Metrics**: `https://your-app-name.fly.dev/metrics`

## 🎯 What This Server Does

- ✅ **Receives webhook POSTs** and logs them with pretty formatting
- ✅ **Handles Nylas webhook challenges** (responds to GET requests with `?challenge=`)
- ✅ **Shows request size** in bytes/KB/MB (helpful for debugging large payloads)
- ✅ **Logs webhook signatures** (Nylas `x-nylas-signature` header)
- ✅ **Pretty-prints JSON** payloads for easy reading
- ✅ **Prometheus metrics** built-in for monitoring
- ✅ **Health check endpoint** for uptime monitoring

## 📋 Usage Examples

### Testing Webhook Delivery
Point your webhook service (Nylas, etc.) to your deployed URL:
```
https://your-app-name.fly.dev/
```

### View Real-time Logs
```bash
flyctl logs
```

### Check Server Status
```bash
flyctl status
```

### Monitor Your Webhooks
Visit `https://your-app-name.fly.dev/metrics` for Prometheus metrics including:
- Request count by HTTP method
- Request duration histograms
- Server health status

## 💰 Cost

Fly.io provides **$5/month in free credits** which easily covers webhook testing:
- Server sleeps when not receiving requests (zero cost)
- Only pay when actively processing webhooks
- Perfect for development and testing

## 🛠️ Local Development

```bash
# Run locally
export PORT=3000
go run main.go

# Test locally
curl http://localhost:3000/health
```

## 🗑️ Cleanup

When you're done testing:
```bash
flyctl destroy
```

## 🔧 Configuration

The server automatically handles:
- **Port**: Uses `PORT` environment variable (defaults to 3000)
- **Logging**: Structured output for webhook analysis
- **Health checks**: Built-in `/health` endpoint
- **Auto-restart**: Fly.io handles server restarts

## 📚 Perfect For

- Testing Nylas webhook integrations
- Debugging webhook payloads and headers
- Development environment webhook endpoints
- Quick webhook inspection during API development
- Learning webhook patterns and structures

---

*Need help? Check the [Fly.io docs](https://fly.io/docs/) or create an issue in this repo.*
