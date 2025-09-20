# Incident Tracking System - Development Plan

## Overview

Building a simple incident tracking system with Ruby on Rails + Hotwire Turbo and Slack bot integration.

## Technology Stack

- **Backend**: Ruby on Rails 7.1+ with Hotwire (Turbo + Stimulus)
- **Frontend**: Hotwire Turbo Frames/Streams + Tailwind CSS
- **Database**: SQLite (demo) → PostgreSQL (production)
- **Slack Bot**: Ruby with slack-ruby-client gem + Sinatra for webhooks
- **Real-time**: Action Cable + Turbo Streams

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Slack Bot     │───▶│   Rails App      │───▶│   Dashboard     │
│                 │    │                  │    │                 │
│ /rootly incident│    │ • Models         │    │ • Turbo Frames  │
│ /rootly resolve │    │ • Controllers    │    │ • Live Updates  │
│                 │    │ • Action Cable   │    │ • Incident List │
└─────────────────┘    │ • API endpoints  │    └─────────────────┘
                       └──────────────────┘
```

## Step-by-Step Development Plan

### **Phase 1: Core Rails App (Start Here)**

1. ✅ **Rails Setup** - New Rails 7 app with Hotwire

   ```bash
   rails new incident_ticketing --skip-test --css tailwind --javascript importmap
   cd incident_ticketing
   ```

2. ✅ **Basic Incident Model** - Simple fields

   - `title` (string)
   - `status` (enum: open, investigating, resolved)
   - `severity` (enum: low, medium, high, critical)
   - `created_by`, `assigned_to` (email fields)
   - `description` (text, optional)
   - `incident_number` (auto-generated, e.g., INC-2025-001)
   - Timestamps for acknowledgment and resolution

3. ✅ **Dashboard Controller & Views** - Basic CRUD with Turbo Frames

   - `IncidentsController` with index, show, new, create, edit, update, destroy actions
   - Dashboard view showing incident list
   - Forms for creating and editing incidents
   - Quick actions for acknowledge/resolve
   - Turbo Frame for incident cards

4. ✅ **Simple Styling** - Make it look decent

   - Tailwind CSS for basic styling
   - Responsive incident cards
   - Clean dashboard layout

5. ✅ **Test with Manual Data** - Verify everything works
   - Seed some sample incidents
   - Test CRUD operations
   - Verify Turbo Frames work

### **Phase 2: Enhanced Web Experience**

6. ✅ **Real-time Updates** - Turbo Streams for live updates

   - Action Cable setup with Redis
   - Broadcast incident changes via `after_commit` callbacks
   - Live dashboard updates across multiple tabs
   - JavaScript Stimulus controller for ActionCable connection

7. ✅ **Status Management** - Buttons to change incident status

   - "Acknowledge" and "Resolve" buttons on incident cards
   - Multi-tab real-time updates with `broadcast_replace_to`
   - Automatic timestamp tracking for acknowledgment and resolution
   - Consistent broadcasting across create/update/resolve actions

8. ✅ **Basic Validations** - Ensure data integrity
   - Title, status, severity, created_by presence validations
   - Unique incident number generation
   - Error handling in forms with proper partials

### **Phase 3: Slack Integration**

9. ✅ **Database Schema Updates** - Add Slack-specific fields

   - ✅ Add `slack_channel_id` to incidents table (for dedicated channels)
   - ✅ Add `slack_channel_name` for human-readable channel names
   - ✅ Add `declared_by` field for Slack user who declared the incident
   - ✅ Using existing `slack_message_ts` for message threading

10. ✅ **API Endpoints** - For Slack bot to communicate

    - ✅ `Api::IncidentsController` with JSON responses (full CRUD + resolve/acknowledge)
    - ✅ Slack webhook endpoints for slash commands (`/api/slack/commands`)
    - ✅ Slack interactive component endpoints (`/api/slack/interactive`)
    - ⏳ Authentication for Slack requests (verify signatures)

11. ✅ **Slack App Setup** - Configure Slack application

    - ✅ Create Slack app with proper scopes
    - ✅ Set up slash command endpoints
    - ✅ Configure interactive components for modals
    - ✅ Set up bot permissions for channel creation
    - ✅ Complete setup documentation in `SLACK_SETUP.md`

12. ✅ **`/rootly declare` Command** - Modal-based incident creation

    - ✅ Parse `/rootly declare <title>` command (works in any channel)
    - ✅ Open Slack modal with incident form (title required, description/severity optional)
    - ✅ Create new incident in database
    - ✅ Create dedicated Slack channel for the incident
    - ✅ Post initial incident summary to the channel
    - ✅ Store channel information in database

13. ✅ **`/rootly resolve` Command** - Channel-specific resolution

    - ✅ Only works in dedicated incident channels (`#incident-*`)
    - ✅ Mark incident as resolved in database
    - ✅ Calculate resolution time and metrics
    - ✅ Post resolution summary with Block Kit design
    - ✅ Broadcast update to web dashboard via Turbo Streams

14. ✅ **Slack Block Kit Design** - Rich UI components

    - ✅ Design incident creation modal with Block Kit
    - ✅ Create incident summary cards for channels
    - ✅ Design resolution summary with metrics
    - ✅ Add interactive buttons for common actions
    - ✅ Implement consistent branding and UX

15. ✅ **Security & Production Readiness**

    - ✅ Slack request signature verification
    - ✅ Environment variable configuration
    - ✅ Error handling and logging
    - ✅ Development vs production mode handling

### **Phase 4: Integration & Polish**

13. ⏳ **Bi-directional Updates** - Slack ↔ Web dashboard

    - Slack notifications when incidents created via web
    - Real-time dashboard updates from Slack commands
    - Consistent state between platforms

14. ⏳ **Error Handling** - Graceful failures

    - Invalid command handling
    - Network error recovery
    - User-friendly error messages

15. ⏳ **Deployment Setup** - Make it production-ready
    - Docker configuration
    - Environment variables
    - Production database setup

## Slack Commands Specification

### `/rootly declare <title>`

**Usage**: Works in any Slack channel
**Flow**:

1. User types `/rootly declare Database outage affecting users`
2. Slack opens a modal with:
   - Title (pre-filled, required)
   - Description (optional textarea)
   - Severity (dropdown: Low/Medium/High/Critical)
   - Assign to (user picker, optional)
3. On submission:
   - Creates incident in database with "open" status
   - Generates unique incident number (e.g., INC-2025-003)
   - Creates dedicated Slack channel `#incident-inc-2025-003`
   - Invites responders to the channel
   - Posts rich incident summary with Block Kit
   - Broadcasts to web dashboard via Turbo Streams

**Channel Creation**:

- Channel name: `#incident-{incident_number}` (lowercase)
- Channel purpose: "Incident: {title} | Status: {status} | Declared by: {user}"
- Auto-invite: Incident responders team

### `/rootly resolve`

**Usage**: Only works in dedicated incident channels (`#incident-*`)
**Flow**:

1. User types `/rootly resolve` in incident channel
2. System validates it's an incident channel
3. Marks incident as resolved with timestamp
4. Calculates and posts resolution metrics:
   - Total resolution time
   - Time to acknowledgment (if applicable)
   - Assigned responders
   - Status timeline
5. Broadcasts update to web dashboard
6. Optionally archives the channel

**Resolution Summary** (Block Kit):

```
🎉 Incident INC-2025-003 Resolved
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Database outage affecting users
⏱️  Total time: 2h 34m
👤 Resolved by: @john.doe
📊 Impact: High severity
🔄 Status: Open → Investigating → Resolved
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
View in dashboard: https://app.com/incidents/123
```

## Initial Incident Model Structure

```ruby
# app/models/incident.rb
class Incident < ApplicationRecord
  enum status: { open: 0, resolved: 1 }

  validates :title, presence: true
  validates :status, presence: true
end
```

## Current Status

- **Current Phase**: ✅ Phase 3 - Slack Integration (COMPLETE!)
- **Completed**: ✅ Phase 1 (Core Rails App) & ✅ Phase 2 (Enhanced Web Experience) & ✅ Phase 3 (Slack Integration)
- **Recently Completed**: ✅ Full Slack bot with modals, channel creation, and security
- **Next Action**: Ready for Phase 4 (Integration & Polish) or production deployment
- **Ready to proceed**: Complete incident tracking system with Slack integration working end-to-end!

## Notes

- Starting with simplest possible implementation
- Will expand features iteratively
- Focus on getting basic functionality working first
- Each phase builds on the previous one
