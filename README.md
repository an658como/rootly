# Incident Tracking System

A modern incident tracking system built with Ruby on Rails 7, Hotwire Turbo, and Slack bot integration.

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

## 🔧 Development Phases

### ✅ Phase 1: Core Rails App (Complete)

- Rails 7 setup with Hotwire
- Incident model with enums and validations
- Full CRUD operations (Create, Read, Update, Delete)
- Beautiful Tailwind CSS dashboard
- Quick actions (Acknowledge, Resolve)

### 🔄 Phase 2: Real-time Updates (Next)

- Action Cable integration
- Turbo Streams for live updates
- Real-time incident status changes

### 🤖 Phase 3: Slack Integration (Planned)

- Slack bot setup
- `/rootly incident <title>` command
- `/rootly resolve <incident_id>` command

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

## 📝 API Endpoints

### REST API

- `GET /incidents` - List all incidents
- `POST /incidents` - Create new incident
- `GET /incidents/:id` - Show incident details
- `PATCH /incidents/:id` - Update incident
- `DELETE /incidents/:id` - Delete incident
- `PATCH /incidents/:id/acknowledge` - Acknowledge incident
- `PATCH /incidents/:id/resolve` - Resolve incident

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
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.
