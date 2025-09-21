# Incident Tracking System

A modern incident tracking system built with Ruby on Rails 7, Hotwire Turbo, and Slack bot integration.

Demo Link: https://youtu.be/9uCTsI-52Vk

## 🚀 Features

- **Web Dashboard** - Beautiful incident management interface
- **Real-time Updates** - Live updates using Turbo Streams
- **Slack Integration** - Create and resolve incidents from Slack
- **Docker Support** - Fully containerized development environment

## 🛠️ Technology Stack

- **Backend**: Ruby on Rails 7.1+ with Hotwire (Turbo + Stimulus)
- **Frontend**: Hotwire Turbo Frames/Streams + Tailwind CSS
- **Database**: PostgreSQL (production) / SQLite (development)
- **Real-time**: Action Cable + Turbo Streams
- **Containerization**: Docker & Docker Compose

## 📋 Prerequisites

- Docker Desktop
- Docker Compose

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd incident_ticketing
```

### 2. Build and Start the Application

```bash
# Build Docker images
docker-compose build

# Start all services
docker-compose up -d

# Create and migrate database
docker-compose exec web bundle exec rails db:create
docker-compose exec web bundle exec rails db:migrate
```

### 3. Access the Application

- **Web Dashboard**: http://localhost:3000
- **Database**: PostgreSQL on localhost:5432
- **Redis**: Redis on localhost:6380

## 🔄 Development Commands

### Fresh Start (Complete Rebuild)

```bash
# Drop everything and rebuild from scratch
docker-compose down -v --remove-orphans
docker system prune -a -f --volumes

# Rebuild and start
docker-compose build --no-cache
docker-compose up -d

# Recreate database
docker-compose exec web bundle exec rails db:create
docker-compose exec web bundle exec rails db:migrate
```

### Daily Development

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f web

# Rails console
docker-compose exec web bundle exec rails console

# Run migrations
docker-compose exec web bundle exec rails db:migrate
```

## 📊 Sample Data

Create some test incidents in the Rails console:

```ruby
# Access Rails console
docker-compose exec web bundle exec rails console

# Create sample incidents
Incident.create!(
  title: "Database Connection Issues",
  description: "Users reporting slow response times",
  severity: :high,
  status: :open,
  created_by: "admin@company.com"
)

Incident.create!(
  title: "Payment Gateway Down",
  description: "Payment processing is failing",
  severity: :critical,
  status: :investigating,
  created_by: "ops@company.com",
  assigned_to: "dev@company.com"
)
```

## 🎯 Usage

### Creating Incidents

1. Visit http://localhost:3000
2. Click "New Incident"
3. Fill out the form with incident details
4. Submit to create incident with auto-generated incident number (e.g., INC-2025-001)

### Managing Incidents

- **View**: Click on any incident card to see details
- **Edit**: Click "Edit" button to modify incident
- **Acknowledge**: Quick action to acknowledge incident
- **Resolve**: Quick action to mark incident as resolved
- **Delete**: Available in edit form with confirmation

### Incident Statuses

- **Open**: Newly created, needs attention
- **Investigating**: Being actively worked on
- **Resolved**: Issue has been fixed

### Severity Levels

- **Low**: Minor issues
- **Medium**: Moderate impact
- **High**: Significant impact
- **Critical**: System down or major outage

## 🐛 Troubleshooting

### Port Conflicts

If you get port conflicts, check what's running:

```bash
# Check port usage
lsof -i :3000  # Rails app
lsof -i :5432  # PostgreSQL
lsof -i :6380  # Redis
```

### Database Issues

```bash
# Reset database completely
docker-compose exec web bundle exec rails db:drop db:create db:migrate
```

### Container Issues

```bash
# View container status
docker-compose ps

# Restart specific service
docker-compose restart web

# View service logs
docker-compose logs web
```

## 🌐 ngrok Setup for Slack Testing

To test Slack integration locally, you need to expose your local Rails app via ngrok so Slack can send webhooks.

### 1. Install ngrok

```bash
# macOS with Homebrew
brew install ngrok

# Or download from https://ngrok.com/download
```

### 2. Start ngrok

```bash
# In a separate terminal, expose port 3000
ngrok http 3000

# You'll get output like:
# Forwarding  https://74e66eb36be8.ngrok-free.app -> http://localhost:3000
```

### 3. Configure Rails for ngrok

**Important**: Every time you restart ngrok, you get a new URL. Update these configurations with your new ngrok URL.

Edit `config/environments/development.rb` and add/update:

```ruby
# Allow ngrok hosts for Slack integration
config.hosts << "YOUR_NGROK_SUBDOMAIN.ngrok-free.app"  # Replace with your actual ngrok URL
# Allow any ngrok subdomain (for when ngrok URL changes)
config.hosts << /.*\.ngrok-free\.app/
config.hosts << /.*\.ngrok\.io/

# Action Cable configuration for development
config.action_cable.url = "ws://localhost:3000/cable"
config.action_cable.allowed_request_origins = [
  "http://localhost:3000",
  "https://YOUR_NGROK_SUBDOMAIN.ngrok-free.app"  # Replace with your actual ngrok URL
]
```

### 4. Restart Rails

```bash
# Restart the web container to apply configuration changes
docker-compose restart web
```

### 5. Test ngrok Integration

```bash
# Test that your app is accessible via ngrok
curl -I https://YOUR_NGROK_SUBDOMAIN.ngrok-free.app

# Test Slack API endpoints
curl -X POST https://YOUR_NGROK_SUBDOMAIN.ngrok-free.app/api/slack/commands \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d 'command=/rootly&text=declare Test incident&user_id=U123&user_name=test.user&channel_id=C123&channel_name=general'
```

### 6. Configure Slack App

Use these URLs in your Slack app configuration:

- **Slash Commands**: `https://YOUR_NGROK_SUBDOMAIN.ngrok-free.app/api/slack/commands`
- **Interactive Components**: `https://YOUR_NGROK_SUBDOMAIN.ngrok-free.app/api/slack/interactive`

### 7. Quick ngrok URL Update Script

Create a helper script to quickly update the ngrok URL:

```bash
#!/bin/bash
# save as update-ngrok.sh

if [ $# -eq 0 ]; then
    echo "Usage: ./update-ngrok.sh <ngrok-subdomain>"
    echo "Example: ./update-ngrok.sh 74e66eb36be8"
    exit 1
fi

NGROK_SUBDOMAIN=$1
NGROK_URL="${NGROK_SUBDOMAIN}.ngrok-free.app"

echo "Updating development.rb with ngrok URL: $NGROK_URL"

# Update the specific ngrok host line
sed -i.bak "s/config\.hosts << \".*\.ngrok-free\.app\"/config.hosts << \"$NGROK_URL\"/" config/environments/development.rb
sed -i.bak "s|\"https://.*\.ngrok-free\.app\"|\"https://$NGROK_URL\"|" config/environments/development.rb

echo "Restarting web container..."
docker-compose restart web

echo "✅ Updated ngrok URL to: https://$NGROK_URL"
echo "🔗 Your Slack webhook URLs:"
echo "   Commands: https://$NGROK_URL/api/slack/commands"
echo "   Interactive: https://$NGROK_URL/api/slack/interactive"
```

Usage:

```bash
chmod +x update-ngrok.sh
./update-ngrok.sh 74e66eb36be8  # Replace with your ngrok subdomain
```

### ngrok Troubleshooting

**Problem**: `Blocked host` error
**Solution**: Make sure you've added your ngrok URL to `config.hosts` and restarted Rails

**Problem**: ActionCable not working via ngrok
**Solution**: Add your ngrok URL to `config.action_cable.allowed_request_origins`

**Problem**: ngrok URL changed
**Solution**: Update both `config.hosts` and `action_cable.allowed_request_origins`, then restart Rails

## 📝 API Endpoints

### REST API

- `GET /incidents` - List all incidents
- `POST /incidents` - Create new incident
- `GET /incidents/:id` - Show incident details
- `PATCH /incidents/:id` - Update incident
- `DELETE /incidents/:id` - Delete incident
- `PATCH /incidents/:id/acknowledge` - Acknowledge incident
- `PATCH /incidents/:id/resolve` - Resolve incident

### Slack API Endpoints

- `POST /api/slack/commands` - Handle Slack slash commands
- `POST /api/slack/interactive` - Handle Slack interactive components (modals, buttons)

### Example API Usage

```bash
# Create incident via API
curl -X POST http://localhost:3000/incidents \
  -H "Content-Type: application/json" \
  -d '{
    "incident": {
      "title": "API Test Incident",
      "description": "Testing API creation",
      "severity": "medium",
      "created_by": "api@test.com"
    }
  }'

# Test Slack command via ngrok
curl -X POST https://YOUR_NGROK_URL.ngrok-free.app/api/slack/interactive \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d 'payload={"type":"view_submission","view":{"callback_id":"incident_declaration","state":{"values":{"incident_title":{"title_input":{"value":"Test Incident"}},"incident_description":{"description_input":{"value":"Testing Slack integration"}},"incident_severity":{"severity_select":{"selected_option":{"value":"high"}}}}},"private_metadata":"{\"user_id\":\"U123\",\"user_name\":\"test.user\",\"original_channel\":\"C123\"}"}}'
```

## 🏗️ Design Choices & Architecture

### Why Turbo Streams?

**Real-time Updates Without JavaScript Complexity**

We chose Turbo Streams over traditional JavaScript frameworks (React, Vue) for several key reasons:

1. **Server-Side Rendering First**: Turbo Streams allow us to maintain Rails' strength in server-side rendering while adding real-time capabilities
2. **Minimal JavaScript**: No complex state management or virtual DOM - just HTML over the wire
3. **Progressive Enhancement**: The app works perfectly without JavaScript, then enhances with real-time features
4. **Rails Integration**: Native integration with Action Cable and Rails broadcasting makes real-time updates trivial
5. **Performance**: Sending targeted HTML fragments is more efficient than full JSON API responses + client-side rendering

**Example**: When an incident is created via Slack, Turbo Streams automatically:

- Prepends the new incident card to all open dashboards
- Updates the statistics counters
- No page refresh needed, no complex state synchronization

### Why Tailwind CSS?

**Utility-First Styling for Rapid Development**

1. **Rapid Prototyping**: Build beautiful interfaces quickly without writing custom CSS
2. **Consistency**: Design system built into the utility classes ensures visual consistency
3. **Maintainability**: No CSS files to maintain, styles are co-located with HTML
4. **Responsive Design**: Built-in responsive utilities make mobile-first design easy
5. **Performance**: Only the CSS you use gets included in the final bundle
6. **Team Productivity**: Designers and developers can work with the same utility vocabulary

**Example**: Our incident cards use Tailwind classes like `bg-white shadow rounded-lg hover:shadow-lg transition-shadow` for consistent, interactive design without custom CSS.

### Dual Controller Architecture

**Why We Have Separate Controllers for Web UI and Slack API**

#### 1. **Separation of Concerns**

**Web Controllers** (`IncidentsController`):

- Handle HTML responses and redirects
- Manage user sessions and authentication
- Provide full CRUD operations with rich UI
- Handle form validations with user-friendly error messages
- Support Turbo Frame navigation

**API Controllers** (`Api::IncidentsController`, `Api::SlackController`):

- Handle JSON responses only
- Stateless operations (no sessions)
- Focused on data exchange
- Slack-specific authentication (signature verification)
- Webhook-optimized response formats

#### 2. **Different Response Formats**

```ruby
# Web Controller - Rich HTML responses
def create
  if @incident.save
    redirect_to incidents_path, notice: "Incident created successfully"
  else
    render :new, status: :unprocessable_entity
  end
end

# API Controller - JSON responses
def create
  if incident.save
    render_json_success({ incident: incident.as_json }, message: "Created successfully")
  else
    render_json_error(incident.errors.full_messages.join(", "))
  end
end
```

#### 3. **Different Authentication Models**

- **Web**: Cookie-based sessions, CSRF protection
- **Slack API**: Signature verification, stateless tokens

#### 4. **Different Error Handling**

- **Web**: User-friendly error pages, form validation highlights
- **API**: Structured JSON error responses, HTTP status codes

#### 5. **Different Performance Requirements**

- **Web**: Can afford richer responses, multiple database queries for better UX
- **API**: Must respond quickly to avoid Slack timeouts, optimized for webhook constraints

### Action Cable + Turbo Streams Integration

**Real-time Bi-directional Updates**

```ruby
# Model broadcasts changes automatically
after_create_commit :broadcast_incident_created
after_update_commit :broadcast_incident_updated

def broadcast_incident_created
  broadcast_prepend_to "incidents",
    partial: "incidents/incident_card",
    locals: { incident: self }
end
```

This architecture enables:

- **Slack → Web**: Incidents created in Slack appear instantly on web dashboards
- **Web → Slack**: Status changes in web UI could trigger Slack notifications (future feature)
- **Multi-user**: All connected users see updates in real-time

### Database Design Choices

**Slack Integration Fields**

We added Slack-specific fields to the main `incidents` table rather than separate tables:

```ruby
# Slack integration fields
t.string :slack_channel_id      # For API calls
t.string :slack_channel_name    # For user display
t.string :declared_by           # Slack username
t.string :slack_message_ts      # For threading
```

**Why not separate tables?**

1. **Simplicity**: Most incidents will have Slack integration
2. **Performance**: Avoids joins for common queries
3. **Atomic Operations**: Incident + Slack data updated together
4. **Rails Conventions**: Single model, single responsibility

### Technology Stack Rationale

| Technology       | Why Chosen                                          | Alternative Considered   |
| ---------------- | --------------------------------------------------- | ------------------------ |
| **Rails 7**      | Mature, productive, great for rapid development     | FastAPI, Django, Express |
| **Hotwire**      | Rails-native, minimal JS, progressive enhancement   | React SPA, Vue.js        |
| **Tailwind**     | Utility-first, rapid development, consistent design | Bootstrap, custom CSS    |
| **PostgreSQL**   | Robust, great Rails support, JSON fields            | MySQL, SQLite            |
| **Action Cable** | Native Rails WebSocket, integrates with Turbo       | Socket.io, Pusher        |
| **Docker**       | Consistent dev environment, easy deployment         | Native installation      |

### Scalability Considerations

**Current Architecture Supports**:

- Multiple concurrent users (Action Cable handles WebSocket connections)
- High read loads (database indexing on incident_number, status, created_at)
- Slack rate limits (error handling and retries built-in)
