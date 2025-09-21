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

## Step 7: Test Your Integration

Once your app is deployed and environment variables are set, test the integration:

### 1. Test Slash Command

- In any Slack channel, type: `/rootly declare Test Incident`
- Verify the modal opens with the incident form
- Fill out the form and submit
- Check that the incident is created successfully

### 2. Test Channel Creation

- After declaring an incident, verify:
  - A new channel is created (e.g., `#incident-inc-2025-xxx`)
  - You are automatically invited to the channel
  - The incident summary is posted in the channel

### 3. Test Resolve Command

- In an incident channel, type: `/rootly resolve`
- Verify the incident is marked as resolved
- Check that a confirmation message is displayed

### 4. Verify Logs

Check your Rails application logs for any errors:

```bash
# Monitor logs for Slack webhook requests
tail -f log/production.log | grep -i slack
```

### 5. Common Test Cases

- **Valid incident creation**: Title, description, severity selection
- **Empty title**: Should show validation error
- **Resolve non-existent incident**: Should show "incident not found"
- **Resolve already resolved incident**: Should show "already resolved"

If any tests fail, check your environment variables and Slack app configuration.
