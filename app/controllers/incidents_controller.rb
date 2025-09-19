class IncidentsController < ApplicationController
  # Skip CSRF for JSON API requests, keep it for HTML forms
  skip_before_action :verify_authenticity_token, if: :json_request?
  before_action :set_incident, only: [ :show, :edit, :update, :destroy ]

  def index
    @incidents = Incident.recent.includes(:created_at)
    @unresolved_count = Incident.unresolved.count
    @total_count = Incident.count
  end

  def show
  end

  def new
    @incident = Incident.new
  end

  def create
    @incident = Incident.new(incident_params)

    if @incident.save
      redirect_to @incident, notice: "Incident #{@incident.incident_number} was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @incident.update(incident_params)
      redirect_to @incident, notice: "Incident #{@incident.incident_number} was successfully updated."
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
    @incident.acknowledge!(params[:user])
    redirect_to @incident, notice: "Incident acknowledged."
  end

  def resolve
    @incident = Incident.find(params[:id])
    @incident.resolve!(params[:user])
    redirect_to @incident, notice: "Incident resolved."
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
end
