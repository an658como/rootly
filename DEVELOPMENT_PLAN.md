# Incident Tracking System - Development Plan

## Overview

Building a simple incident tracking system with Ruby on Rails + Hotwire Turbo and Slack bot integration.

## Technology Stack

- **Backend**: Ruby on Rails 7.1+ with Hotwire (Turbo + Stimulus)
- **Frontend**: Hotwire Turbo Frames/Streams + Tailwind CSS
- **Database**: SQLite (demo) → PostgreSQL (production)
- **Slack Bot**: Ruby with slack-ruby-bot gem
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

9. ⏳ **API Endpoints** - For Slack bot to communicate

   - `Api::IncidentsController`
   - JSON API for creating/updating incidents
   - Authentication for Slack requests

10. ⏳ **Slack Bot Setup** - Basic `/rootly incident` command

    - slack-ruby-bot gem setup
    - Slack app configuration
    - Webhook endpoint setup

11. ⏳ **Command Parsing** - Handle the title parameter

    - Parse `/rootly incident <title>` command
    - Create incident via API
    - Send confirmation to Slack

12. ⏳ **Resolve Command** - `/rootly resolve` functionality
    - Parse `/rootly resolve <incident_id>` command
    - Update incident status
    - Send confirmation to Slack

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

### `/rootly incident <title>`

- Creates new incident with "open" status
- Assigns unique ID
- Posts confirmation back to Slack
- Broadcasts update to dashboard via Turbo Streams

### `/rootly resolve <incident_id>`

- Updates incident status to "resolved"
- Adds resolution timestamp
- Notifies in Slack
- Updates dashboard in real-time

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

- **Current Phase**: Phase 3 - Slack Integration
- **Completed**: ✅ Phase 1 (Core Rails App) & ✅ Phase 2 (Enhanced Web Experience)
- **Next Action**: Create API endpoints for Slack bot communication
- **Ready to proceed**: Full web dashboard with real-time multi-tab updates working perfectly!

## Notes

- Starting with simplest possible implementation
- Will expand features iteratively
- Focus on getting basic functionality working first
- Each phase builds on the previous one
