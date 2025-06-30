#!/bin/bash
# Super simple auto-deploy - Fly.io handles everything

set -e

echo "🎯 Nylas Webhook Server - Auto Deploy"
echo "====================================="

# Check if flyctl is installed
if ! command -v flyctl &> /dev/null; then
    echo "❌ flyctl not found"
    echo "📥 Install it: https://fly.io/docs/flyctl/install/"
    echo "   macOS: brew install flyctl"
    echo "   Linux: curl -L https://fly.io/install.sh | sh"
    exit 1
fi

# Check if logged in
if ! flyctl auth whoami &> /dev/null; then
    echo "🔐 Please login to Fly.io first:"
    flyctl auth login
fi

echo ""
echo "🚀 Deploying webhook server..."
echo "   (Fly.io will auto-generate a unique name)"

# Let fly.io handle everything automatically
flyctl launch

# Get the app name that was created
APP_NAME=$(grep "^app = " fly.toml | sed "s/app = '\(.*\)'/\1/" | tr -d "'")

echo ""
echo "✅ Deployed successfully!"
echo "🌐 Webhook URL: https://$APP_NAME.fly.dev/"
echo "❤️  Health check: https://$APP_NAME.fly.dev/health"
echo "📊 Metrics: https://$APP_NAME.fly.dev/metrics"
echo ""
echo "📋 Useful commands:"
echo "   flyctl logs       # View webhook logs"
echo "   flyctl status     # Check if running"  
echo "   flyctl destroy    # Delete when done"
echo ""
echo "🎉 Ready to receive webhooks!"
