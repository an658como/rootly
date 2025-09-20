class Api::IncidentsController < Api::BaseController
  before_action :set_incident, only: [ :show, :update, :resolve ]

  # GET /api/incidents
  def index
    incidents = Incident.recent.limit(50)
    render_json_success(
      {
        incidents: incidents.as_json(
          only: [ :id, :title, :description, :status, :severity, :created_by, :assigned_to,
                 :resolved_at, :acknowledged_at, :incident_number, :created_at, :updated_at,
                 :slack_channel_id, :slack_channel_name, :declared_by, :slack_message_ts ]
        )
      }
    )
  end

  # GET /api/incidents/:id
  def show
    render_json_success(
      {
        incident: @incident.as_json(
          only: [ :id, :title, :description, :status, :severity, :created_by, :assigned_to,
                 :resolved_at, :acknowledged_at, :incident_number, :created_at, :updated_at,
                 :slack_channel_id, :slack_channel_name, :declared_by, :slack_message_ts ]
        )
      }
    )
  end

  # POST /api/incidents
  def create
    incident = Incident.new(incident_params)

    if incident.save
      render_json_success(
        {
          incident: incident.as_json(
            only: [ :id, :title, :description, :status, :severity, :created_by, :assigned_to,
                 :resolved_at, :acknowledged_at, :incident_number, :created_at, :updated_at,
                 :slack_channel_id, :slack_channel_name, :declared_by, :slack_message_ts ]
          )
        },
        "Incident #{incident.incident_number} created successfully"
      )
    else
      render_json_error(incident.errors.full_messages.join(", "))
    end
  end

  # PATCH/PUT /api/incidents/:id
  def update
    if @incident.update(incident_params)
      render_json_success(
        {
          incident: @incident.as_json(
            only: [ :id, :title, :description, :status, :severity, :created_by, :assigned_to,
                 :resolved_at, :acknowledged_at, :incident_number, :created_at, :updated_at,
                 :slack_channel_id, :slack_channel_name, :declared_by, :slack_message_ts ]
          )
        },
        "Incident #{@incident.incident_number} updated successfully"
      )
    else
      render_json_error(@incident.errors.full_messages.join(", "))
    end
  end

  # POST /api/incidents/:id/resolve
  def resolve
    if @incident.resolved?
      render_json_error("Incident #{@incident.incident_number} is already resolved")
      return
    end

    @incident.resolve!
    render_json_success(
      {
        incident: @incident.as_json(
          only: [ :id, :title, :description, :status, :severity, :created_by, :assigned_to,
                 :resolved_at, :acknowledged_at, :incident_number, :created_at, :updated_at,
                 :slack_channel_id, :slack_channel_name, :declared_by, :slack_message_ts ]
        )
      },
      "Incident #{@incident.incident_number} resolved successfully"
    )
  end

  # POST /api/incidents/:id/acknowledge
  def acknowledge
    if @incident.acknowledged?
      render_json_error("Incident #{@incident.incident_number} is already acknowledged")
      return
    end

    @incident.acknowledge!
    render_json_success(
      {
        incident: @incident.as_json(
          only: [ :id, :title, :description, :status, :severity, :created_by, :assigned_to,
                 :resolved_at, :acknowledged_at, :incident_number, :created_at, :updated_at,
                 :slack_channel_id, :slack_channel_name, :declared_by, :slack_message_ts ]
        )
      },
      "Incident #{@incident.incident_number} acknowledged successfully"
    )
  end

  private

  def set_incident
    @incident = Incident.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_json_error("Incident not found", :not_found)
  end

  def incident_params
    params.require(:incident).permit(
      :title, :description, :status, :severity, :created_by, :assigned_to,
      :slack_channel_id, :slack_channel_name, :declared_by, :slack_message_ts
    )
  end
end
