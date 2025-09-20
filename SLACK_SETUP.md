# Slack App Setup Guide

This guide will help you set up a real Slack app to integrate with your incident tracking system.

## Prerequisites

- Admin access to a Slack workspace
- Your incident tracking app deployed and accessible via HTTPS
- Basic understanding of Slack app configuration

## Step 1: Create a Slack App

1. Go to [https://api.slack.com/apps](https://api.slack.com/apps)
2. Click **"Create New App"**
3. Choose **"From scratch"**
4. Enter app details:
   - **App Name**: `Rootly Incident Bot`
   - **Development Slack Workspace**: Select your workspace
5. Click **"Create App"**

## Step 2: Configure OAuth & Permissions

1. In your app settings, go to **"OAuth & Permissions"**
2. Scroll down to **"Scopes"** and add these **Bot Token Scopes**:

   ```
   channels:manage     # Create and manage channels
   channels:read       # Read channel information
   chat:write          # Send messages as the bot
   commands            # Add slash commands
   users:read          # Read user information
   channels:join       # Join channels
   groups:write        # Create private channels (if needed)
   ```

3. Scroll up and click **"Install to Workspace"**
4. Authorize the app
5. Copy the **"Bot User OAuth Token"** (starts with `xoxb-`)

## Step 3: Set Up Slash Commands

1. Go to **"Slash Commands"** in your app settings
2. Click **"Create New Command"**
3. Configure the `/rootly` command:
   ```
   Command: /rootly
   Request URL: https://your-domain.com/api/slack/commands
   Short Description: Manage incidents with Rootly
   Usage Hint: declare <title> | resolve
   ```
4. Click **"Save"**

## Step 4: Enable Interactive Components

1. Go to **"Interactivity & Shortcuts"**
2. Turn on **"Interactivity"**
3. Set **Request URL**: `https://your-domain.com/api/slack/interactive`
4. Click **"Save Changes"**

## Step 5: Configure Event Subscriptions (Optional)

1. Go to **"Event Subscriptions"**
2. Turn on **"Enable Events"**
3. Set **Request URL**: `https://your-domain.com/api/slack/events`
4. Subscribe to bot events (if needed):
   ```
   message.channels    # Listen to channel messages
   channel_created     # Know when channels are created
   ```

## Step 6: Environment Variables

Add these environment variables to your Rails application:

```bash
# .env or your deployment environment
SLACK_BOT_TOKEN=xoxb-your-bot-token-here
SLACK_SIGNING_SECRET=your-signing-secret-here
SLACK_CLIENT_ID=your-client-id-here
SLACK_CLIENT_SECRET=your-client-secret-here
```

You can find these values in your Slack app settings:

- **Bot Token**: OAuth & Permissions → Bot User OAuth Token
- **Signing Secret**: Basic Information → App Credentials → Signing Secret
- **Client ID & Secret**: Basic Information → App Credentials

## Step 7: Update Your Rails App

1. **Add the slack-ruby-client gem** (already done):

   ```ruby
   gem 'slack-ruby-client'
   ```

2. **Create a Slack service class** (optional, for better organization):

   ```ruby
   # app/services/slack_service.rb
   class SlackService
     def initialize
       @client = Slack::Web::Client.new(token: ENV['SLACK_BOT_TOKEN'])
     end

     def create_channel(name, purpose = nil)
       @client.conversations_create(name: name, is_private: false)
     end

     def post_message(channel, text: nil, blocks: nil)
       @client.chat_postMessage(channel: channel, text: text, blocks: blocks)
     end
   end
   ```

3. **Update the Slack controller** to use real API calls:

   ```ruby
   # In app/controllers/api/slack_controller.rb
   def create_incident_channel(incident, user_name)
     slack_service = SlackService.new
     channel_name = "incident-#{incident.incident_number.downcase}"

     begin
       response = slack_service.create_channel(channel_name)
       {
         success: true,
         channel_id: response.channel.id,
         channel_name: channel_name
       }
     rescue Slack::Web::Api::Errors::SlackError => e
       Rails.logger.error "Slack API Error: #{e.message}"
       { success: false, error: e.message }
     end
   end
   ```

## Step 8: Test Your Integration

1. **Test slash commands**:

   ```
   /rootly declare Database is down
   /rootly resolve
   /rootly help
   ```

2. **Verify functionality**:
   - ✅ Modal opens for incident declaration
   - ✅ Incident is created in your Rails app
   - ✅ Dedicated channel is created
   - ✅ Incident summary is posted to channel
   - ✅ Resolution works in incident channels

## Step 9: Deploy to Production

1. **HTTPS Required**: Slack requires HTTPS for all webhook URLs
2. **Environment Variables**: Set all required environment variables
3. **Update URLs**: Update all Slack app URLs to your production domain
4. **Test Thoroughly**: Test all functionality in your production Slack workspace

## Troubleshooting

### Common Issues

1. **"URL verification failed"**

   - Ensure your app is accessible via HTTPS
   - Check that the endpoint returns a 200 status
   - Verify the request signature validation

2. **"Missing scope" errors**

   - Review the required scopes in Step 2
   - Reinstall the app to workspace after adding scopes

3. **Signature verification fails**

   - Ensure `SLACK_SIGNING_SECRET` is correctly set
   - Check that you're using the raw request body
   - Verify timestamp is within 5 minutes

4. **Bot can't create channels**
   - Ensure `channels:manage` scope is added
   - Check that the bot is installed to the workspace
   - Verify the bot token is valid

### Useful Slack API Documentation

- [Slack API Documentation](https://api.slack.com/web)
- [Block Kit Builder](https://app.slack.com/block-kit-builder) - Design rich messages
- [Slack Ruby Client](https://github.com/slack-ruby/slack-ruby-client) - Ruby gem docs

## Security Considerations

1. **Always verify request signatures** in production
2. **Use HTTPS** for all webhook URLs
3. **Store tokens securely** using environment variables
4. **Implement rate limiting** to prevent abuse
5. **Log security events** for monitoring

## Next Steps

Once your Slack integration is working:

1. **Add more commands** (e.g., `/rootly status`, `/rootly assign`)
2. **Implement user mentions** and notifications
3. **Add incident templates** for common scenarios
4. **Create incident reports** and analytics
5. **Set up monitoring** and alerting for the integration

---

## Support

If you need help with the Slack integration:

1. Check the Rails logs for error messages
2. Use Slack's [API Tester](https://api.slack.com/methods) to test API calls
3. Review the [Slack API documentation](https://api.slack.com/)
4. Test with a simple curl command to isolate issues

Happy incident management! 🚨✨
