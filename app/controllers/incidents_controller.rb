class IncidentsController < ApplicationController
  # Skip CSRF for JSON API requests, keep it for HTML forms
  skip_before_action :verify_authenticity_token, if: :json_request?
  before_action :set_incident, only: [ :show, :edit, :update, :destroy ]

  def index
    @incidents = apply_sorting(Incident.all)
    @unresolved_count = Incident.unresolved.count
    @total_count = Incident.count
    @current_sort = params[:sort] || "created_at_desc"
  end

  def show
  end

  def new
    @incident = Incident.new
  end

  def create
    @incident = Incident.new(incident_params)

    if @incident.save
      respond_to do |format|
        format.html { redirect_to incidents_path, notice: "Incident #{@incident.incident_number} was successfully created." }
        format.turbo_stream { redirect_to incidents_path, notice: "Incident #{@incident.incident_number} was successfully created." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @incident.update(incident_params)
      respond_to do |format|
        format.html { redirect_to incidents_path, notice: "Incident #{@incident.incident_number} was successfully updated." }
        format.turbo_stream { redirect_to incidents_path, notice: "Incident #{@incident.incident_number} was successfully updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    incident_number = @incident.incident_number
    @incident.destroy
    redirect_to incidents_path, notice: "Incident #{incident_number} was successfully deleted."
  end

  # Quick actions for status updates
  def acknowledge
    @incident = Incident.find(params[:id])
    @incident.acknowledge!
    redirect_to incidents_path, notice: "Incident #{@incident.incident_number} acknowledged."
  end

  def resolve
    @incident = Incident.find(params[:id])
    @incident.resolve!
    redirect_to incidents_path, notice: "Incident #{@incident.incident_number} resolved."
  end

  private

  def set_incident
    @incident = Incident.find(params[:id])
  end

  def incident_params
    params.require(:incident).permit(:title, :description, :status, :severity, :created_by, :assigned_to)
  end

  def json_request?
    request.format.json?
  end

  def apply_sorting(incidents)
    case params[:sort]
    when "title_asc"
      incidents.order(:title)
    when "title_desc"
      incidents.order(title: :desc)
    when "created_at_asc"
      incidents.order(:created_at)
    when "created_at_desc", nil
      incidents.recent # Default to recent (created_at desc)
    when "severity_asc"
      incidents.order(:severity)
    when "severity_desc"
      incidents.order(severity: :desc)
    when "status_asc"
      incidents.order(:status)
    when "status_desc"
      incidents.order(status: :desc)
    else
      incidents.recent # Fallback to default
    end
  end
end
