class Incident < ApplicationRecord
  # Broadcasting for real-time updates using Turbo Streams
  after_create_commit :broadcast_incident_created
  after_update_commit :broadcast_incident_updated
  after_destroy_commit :broadcast_incident_destroyed

  # Enums for status and severity
  enum :status, {
    open: 0,
    investigating: 1,
    resolved: 2
  }

  enum :severity, {
    low: 0,
    medium: 1,
    high: 2,
    critical: 3
  }

  # Validations
  validates :title, presence: true, length: { minimum: 3, maximum: 255 }
  validates :status, presence: true
  validates :severity, presence: true
  validates :created_by, presence: true
  validates :incident_number, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_incident_number, on: :create
  before_save :set_resolved_at

  # Scopes
  scope :unresolved, -> { where.not(status: :resolved) }
  scope :by_severity, -> { order(:severity, :created_at) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def resolved?
    status == "resolved"
  end

  def acknowledged?
    acknowledged_at.present?
  end

  def acknowledge!(user = nil)
    attrs = { acknowledged_at: Time.current }
    attrs[:assigned_to] = user if user.present?
    update!(attrs) unless acknowledged?
  end

  def resolve!(user = nil)
    attrs = { status: :resolved, resolved_at: Time.current }
    attrs[:assigned_to] = user if user.present?
    update!(attrs)
  end

  def duration
    return nil unless resolved?
    resolved_at - created_at
  end

  def severity_color
    case severity.to_sym
    when :low then "green"
    when :medium then "yellow"
    when :high then "orange"
    when :critical then "red"
    end
  end

  def status_color
    case status.to_sym
    when :open then "red"
    when :investigating then "yellow"
    when :resolved then "green"
    end
  end

  private

  def broadcast_incident_created
    # Broadcast new incident card
    broadcast_prepend_to "incidents", partial: "incidents/incident_card", locals: { incident: self }
    # Broadcast updated stats
    broadcast_stats_update
  end

  def broadcast_incident_updated
    # Broadcast updated incident card
    broadcast_replace_to "incidents", target: "incident_#{id}", partial: "incidents/incident_card", locals: { incident: self }
    # Broadcast updated stats
    broadcast_stats_update
  end

  def broadcast_incident_destroyed
    # Remove incident card
    broadcast_remove_to "incidents"
    # Broadcast updated stats
    broadcast_stats_update
  end

  def broadcast_stats_update
    # Calculate current stats
    total_count = Incident.count
    unresolved_count = Incident.unresolved.count

    # Broadcast updated stats using Turbo Streams
    broadcast_replace_to "incidents",
      target: "dashboard-stats",
      partial: "incidents/dashboard_stats",
      locals: { total_count: total_count, unresolved_count: unresolved_count }

    # Also log for debugging
    Rails.logger.info "📊 Broadcasting stats update: Total=#{total_count}, Unresolved=#{unresolved_count}"
  end

  def generate_incident_number
    return if incident_number.present?

    # Generate format: INC-YYYY-XXX (e.g., INC-2024-001)
    year = Date.current.year
    last_incident = Incident.where("incident_number LIKE ?", "INC-#{year}-%").order(:incident_number).last

    if last_incident
      last_number = last_incident.incident_number.split("-").last.to_i
      next_number = last_number + 1
    else
      next_number = 1
    end

    self.incident_number = "INC-#{year}-#{next_number.to_s.rjust(3, '0')}"
  end

  def set_resolved_at
    if status_changed? && resolved?
      self.resolved_at ||= Time.current
    elsif status_changed? && !resolved?
      self.resolved_at = nil
    end
  end
end
