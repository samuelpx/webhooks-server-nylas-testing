#!/bin/bash
# Enhanced auto-deploy script with proper app name handling

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

# Check if fly.toml already exists
if [ -f "fly.toml" ]; then
    # Extract the current app name from fly.toml
    CURRENT_APP=$(grep "^app = " fly.toml | sed "s/app = ['\"]\\(.*\\)['\"]/\\1/" | tr -d "'\"")
    
    echo "⚠️  Found existing fly.toml with app name: $CURRENT_APP"
    echo ""
    echo "Choose an option:"
    echo "1) Deploy with a NEW app name (recommended for first-time deployment)"
    echo "2) Keep the existing app name '$CURRENT_APP' (only if you own this app)"
    echo "3) Let Fly.io auto-generate a random name"
    echo ""
    
    read -p "Enter your choice (1-3): " CHOICE
    
    case $CHOICE in
        1)
            # Prompt for custom app name
            echo ""
            read -p "Enter your desired app name (lowercase, letters/numbers/hyphens only): " APP_NAME
            
            # Validate app name
            if [[ ! "$APP_NAME" =~ ^[a-z0-9-]+$ ]]; then
                echo "❌ Invalid app name. Use only lowercase letters, numbers, and hyphens."
                exit 1
            fi
            
            # Update the fly.toml with the new app name
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS version
                sed -i '' "s/app = .*/app = '$APP_NAME'/" fly.toml
            else
                # Linux version
                sed -i "s/app = .*/app = '$APP_NAME'/" fly.toml
            fi
            
            echo "✅ Updated fly.toml with app name: $APP_NAME"
            ;;
            
        2)
            # Keep existing name
            APP_NAME=$CURRENT_APP
            echo "✅ Keeping existing app name: $APP_NAME"
            ;;
            
        3)
            # Remove fly.toml to let Fly.io generate everything
            echo "🗑️  Removing fly.toml to let Fly.io auto-generate configuration..."
            rm fly.toml
            APP_NAME="auto-generated"
            ;;
            
        *)
            echo "❌ Invalid choice. Exiting."
            exit 1
            ;;
    esac
else
    # No fly.toml exists
    echo "No fly.toml found. Choose an option:"
    echo "1) Enter a custom app name"
    echo "2) Let Fly.io auto-generate a name"
    echo ""
    
    read -p "Enter your choice (1-2): " CHOICE
    
    case $CHOICE in
        1)
            echo ""
            read -p "Enter your desired app name (lowercase, letters/numbers/hyphens only): " APP_NAME
            
            # Validate app name
            if [[ ! "$APP_NAME" =~ ^[a-z0-9-]+$ ]]; then
                echo "❌ Invalid app name. Use only lowercase letters, numbers, and hyphens."
                exit 1
            fi
            ;;
            
        2)
            APP_NAME="auto-generated"
            ;;
            
        *)
            echo "❌ Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

echo ""
echo "🚀 Deploying webhook server..."

# Deploy based on the configuration
if [ -f "fly.toml" ]; then
    # fly.toml exists (either original or modified)
    flyctl deploy
else
    # No fly.toml - let flyctl launch create everything
    if [ "$APP_NAME" == "auto-generated" ]; then
        flyctl launch --no-deploy
    else
        flyctl launch --no-deploy --name "$APP_NAME"
    fi
    
    # Now deploy
    flyctl deploy
fi

# Get the final app name (in case it was auto-generated)
if [ -f "fly.toml" ]; then
    FINAL_APP_NAME=$(grep "^app = " fly.toml | sed "s/app = ['\"]\\(.*\\)['\"]/\\1/" | tr -d "'\"")
else
    echo "❌ Error: fly.toml not found after deployment"
    exit 1
fi

echo ""
echo "✅ Deployed successfully!"
echo "🌐 Webhook URL: https://$FINAL_APP_NAME.fly.dev/"
echo "❤️  Health check: https://$FINAL_APP_NAME.fly.dev/health"
echo "📊 Metrics: https://$FINAL_APP_NAME.fly.dev/metrics"
echo ""
echo "📋 Useful commands:"
echo "   flyctl logs       # View webhook logs"
echo "   flyctl status     # Check if running"  
echo "   flyctl destroy    # Delete when done"
echo ""
echo "🎉 Ready to receive webhooks!"

# Optional: Offer to save the app name for future reference
echo ""
read -p "Would you like to save the app name to a .env file for future reference? (y/n): " SAVE_ENV

if [[ "$SAVE_ENV" =~ ^[Yy]$ ]]; then
    echo "FLY_APP_NAME=$FINAL_APP_NAME" > .env
    echo "✅ App name saved to .env file"
    
    # Add .env to .gitignore if it's not already there
    if ! grep -q "^.env$" .gitignore 2>/dev/null; then
        echo ".env" >> .gitignore
        echo "✅ Added .env to .gitignore"
    fi
fi
