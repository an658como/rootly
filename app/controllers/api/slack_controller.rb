class Api::SlackController < Api::BaseController
  # Slack webhook endpoints
  
  # POST /api/slack/commands
  def commands
    # Verify the request is from Slack (we'll implement this later)
    # verify_slack_request!
    
    command = params[:command]
    text = params[:text]
    user_id = params[:user_id]
    user_name = params[:user_name]
    channel_id = params[:channel_id]
    channel_name = params[:channel_name]
    
    case command
    when '/rootly'
      handle_rootly_command(text, user_id, user_name, channel_id, channel_name)
    else
      render json: { text: "Unknown command: #{command}" }, status: :ok
    end
  end
  
  # POST /api/slack/interactive
  def interactive
    # Handle Slack interactive components (modals, buttons, etc.)
    payload = JSON.parse(params[:payload])
    
    case payload['type']
    when 'view_submission'
      handle_modal_submission(payload)
    when 'block_actions'
      handle_block_actions(payload)
    else
      render json: {}, status: :ok
    end
  end
  
  private
  
  def handle_rootly_command(text, user_id, user_name, channel_id, channel_name)
    parts = text.split(' ', 2)
    subcommand = parts[0]
    args = parts[1]
    
    case subcommand
    when 'declare'
      handle_declare_command(args, user_id, user_name, channel_id, channel_name)
    when 'resolve'
      handle_resolve_command(user_id, user_name, channel_id, channel_name)
    else
      render json: {
        text: "Available commands:\n• `/rootly declare <title>` - Declare a new incident\n• `/rootly resolve` - Resolve an incident (in incident channels only)"
      }, status: :ok
    end
  end
  
  def handle_declare_command(title, user_id, user_name, channel_id, channel_name)
    if title.blank?
      render json: {
        text: "Please provide an incident title: `/rootly declare Database is down`"
      }, status: :ok
      return
    end
    
    # Open a modal for incident creation
    modal_view = build_incident_modal(title, user_id)
    
    # For now, we'll return a simple response
    # In a real implementation, we'd use the Slack API to open the modal
    render json: {
      text: "🚨 Incident declaration initiated: \"#{title}\"\nModal would open here for additional details."
    }, status: :ok
  end
  
  def handle_resolve_command(user_id, user_name, channel_id, channel_name)
    # Check if this is an incident channel
    unless channel_name&.start_with?('incident-')
      render json: {
        text: "❌ `/rootly resolve` can only be used in incident channels (#incident-*)"
      }, status: :ok
      return
    end
    
    # Extract incident number from channel name
    incident_number = extract_incident_number_from_channel(channel_name)
    
    if incident_number.blank?
      render json: {
        text: "❌ Could not determine incident number from channel name"
      }, status: :ok
      return
    end
    
    # Find and resolve the incident
    incident = Incident.find_by(incident_number: incident_number)
    
    if incident.nil?
      render json: {
        text: "❌ Incident #{incident_number} not found"
      }, status: :ok
      return
    end
    
    if incident.resolved?
      render json: {
        text: "✅ Incident #{incident_number} is already resolved"
      }, status: :ok
      return
    end
    
    # Resolve the incident
    incident.resolve!
    
    # Calculate resolution time
    resolution_time = time_duration_in_words(incident.created_at, incident.resolved_at)
    
    render json: {
      text: "🎉 *Incident #{incident_number} Resolved*\n" \
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" \
            "📋 #{incident.title}\n" \
            "⏱️ Total time: #{resolution_time}\n" \
            "👤 Resolved by: @#{user_name}\n" \
            "📊 Impact: #{incident.severity.humanize} severity\n" \
            "🔄 Status: #{incident.status.humanize}\n" \
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" \
            "View in dashboard: #{dashboard_incident_url(incident)}"
    }, status: :ok
  end
  
  def handle_modal_submission(payload)
    # Handle incident creation from modal
    # This would process the modal form data and create the incident
    render json: {}, status: :ok
  end
  
  def handle_block_actions(payload)
    # Handle button clicks and other interactive elements
    render json: {}, status: :ok
  end
  
  def build_incident_modal(title, user_id)
    # This would build the Slack Block Kit modal JSON
    # For now, returning a placeholder
    {
      type: "modal",
      title: {
        type: "plain_text",
        text: "Declare Incident"
      },
      blocks: []
    }
  end
  
  def extract_incident_number_from_channel(channel_name)
    # Extract INC-YYYY-XXX from #incident-inc-yyyy-xxx
    match = channel_name.match(/incident-(.+)/)
    return nil unless match
    
    incident_slug = match[1]
    # Convert inc-2025-001 to INC-2025-001
    incident_slug.upcase.gsub('-', '-')
  end
  
  def time_duration_in_words(start_time, end_time)
    duration = end_time - start_time
    hours = (duration / 1.hour).to_i
    minutes = ((duration % 1.hour) / 1.minute).to_i
    
    if hours > 0
      "#{hours}h #{minutes}m"
    else
      "#{minutes}m"
    end
  end
  
  def dashboard_incident_url(incident)
    # This would generate the full URL to the incident in the dashboard
    "http://localhost:3000/incidents/#{incident.id}"
  end
end
