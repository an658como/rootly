#!/bin/bash
# Helper script to quickly update ngrok URL in development configuration

if [ $# -eq 0 ]; then
    echo "Usage: ./update-ngrok.sh <ngrok-subdomain>"
    echo "Example: ./update-ngrok.sh 74e66eb36be8"
    echo ""
    echo "This script will:"
    echo "  1. Update config/environments/development.rb with new ngrok URL"
    echo "  2. Restart the web container"
    echo "  3. Display your Slack webhook URLs"
    exit 1
fi

NGROK_SUBDOMAIN=$1
NGROK_URL="${NGROK_SUBDOMAIN}.ngrok-free.app"

echo "🔄 Updating development.rb with ngrok URL: $NGROK_URL"

# Check if development.rb exists
if [ ! -f "config/environments/development.rb" ]; then
    echo "❌ Error: config/environments/development.rb not found"
    echo "Make sure you're running this from the project root directory"
    exit 1
fi

# Update the specific ngrok host line
sed -i.bak "s/config\.hosts << \".*\.ngrok-free\.app\"/config.hosts << \"$NGROK_URL\"/" config/environments/development.rb

# Update the ActionCable allowed origins line  
sed -i.bak "s|\"https://.*\.ngrok-free\.app\"|\"https://$NGROK_URL\"|" config/environments/development.rb

echo "📝 Configuration updated"

# Check if docker-compose is available
if command -v docker-compose &> /dev/null; then
    echo "🔄 Restarting web container..."
    docker-compose restart web
    
    if [ $? -eq 0 ]; then
        echo "✅ Web container restarted successfully"
    else
        echo "⚠️  Failed to restart web container - you may need to restart manually"
    fi
else
    echo "⚠️  docker-compose not found - please restart your web container manually"
fi

echo ""
echo "🎉 ngrok setup complete!"
echo "🔗 Your ngrok URL: https://$NGROK_URL"
echo ""
echo "📋 Use these URLs in your Slack app configuration:"
echo "   Slash Commands:      https://$NGROK_URL/api/slack/commands"
echo "   Interactive Components: https://$NGROK_URL/api/slack/interactive"
echo ""
echo "🧪 Test your setup:"
echo "   curl -I https://$NGROK_URL"
echo ""
echo "📖 For full Slack setup instructions, see SLACK_SETUP.md"
