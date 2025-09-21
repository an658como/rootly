class SlackIncidentService
  def create_incident(title:, description:, severity:, user_id:, user_name:, original_channel:)
    # Create the incident
    incident = Incident.new(
      title: title,
      description: description,
      severity: severity,
      status: "open",
      created_by: user_name,
      declared_by: user_name
    )

    if incident.save
      # Success - incident created
      channel_service = SlackChannelService.new
      channel_result = channel_service.create_incident_channel(incident, user_name, user_id)

      if channel_result[:success]
        # Update incident with channel info
        incident.update(
          slack_channel_id: channel_result[:channel_id],
          slack_channel_name: channel_result[:channel_name]
        )

        # Post incident summary to the channel
        message_service = SlackMessageFormatterService.new
        message_service.post_incident_summary_to_channel(incident, channel_result[:channel_id])
      end

      # Send a success message to the user via chat.postEphemeral
      send_success_message(incident, user_id, user_name, original_channel, channel_result)

      { success: true, incident: incident }
    else
      # Error - validation failed
      {
        success: false,
        errors: {
          "incident_title" => incident.errors[:title].first || "",
          "incident_description" => incident.errors[:description].first || "",
          "incident_severity" => incident.errors[:severity].first || ""
        }
      }
    end
  end

  def resolve_from_channel(channel_name:, user_name:)
    # Extract incident number from channel name
    incident_number = extract_incident_number_from_channel(channel_name)

    if incident_number.blank?
      Rails.logger.error "Could not extract incident number from channel: #{channel_name}"
      return {
        text: "❌ Could not determine incident number from channel name: #{channel_name}"
      }
    end

    Rails.logger.info "Extracted incident number: #{incident_number} from channel: #{channel_name}"

    # Find and resolve the incident
    incident = Incident.find_by(incident_number: incident_number)

    if incident.nil?
      Rails.logger.error "Incident not found: #{incident_number}. Available incidents: #{Incident.pluck(:incident_number).join(', ')}"
      return {
        text: "❌ Incident #{incident_number} not found. Available incidents: #{Incident.pluck(:incident_number).join(', ')}"
      }
    end

    if incident.resolved?
      return {
        text: "✅ Incident #{incident_number} is already resolved"
      }
    end

    # Resolve the incident
    incident.resolve!

    # Calculate resolution time
    resolution_time = time_duration_in_words(incident.created_at, incident.resolved_at)

    {
      text: "🎉 *Incident #{incident_number} Resolved*\n" \
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" \
            "📋 #{incident.title}\n" \
            "⏱️ Total time: #{resolution_time}\n" \
            "👤 Resolved by: @#{user_name}\n" \
            "📊 Impact: #{incident.severity.humanize} severity\n" \
            "🔄 Status: #{incident.status.humanize}\n" \
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" \
            "View in dashboard: #{dashboard_incident_url(incident)}"
    }
  end

  private

  def send_success_message(incident, user_id, user_name, original_channel, channel_result)
    begin
      slack_client = Slack::Web::Client.new(token: ENV["SLACK_BOT_TOKEN"])

      success_message = "🎉 *Incident #{incident.incident_number} created successfully!*\n" \
                       "📋 #{incident.title}\n" \
                       "📊 Severity: #{incident.severity.humanize}\n" \
                       "💬 Channel: ##{channel_result[:channel_name]}\n" \
                       "👤 You've been added to the incident channel\n" \
                       "🔗 View in dashboard: #{dashboard_incident_url(incident)}"

      slack_client.chat_postEphemeral(
        channel: original_channel,
        user: user_id,
        text: success_message
      )
    rescue => e
      Rails.logger.error "Failed to send success message: #{e.message}"
    end
  end

  def extract_incident_number_from_channel(channel_name)
    # Extract INC-YYYY-XXX from #incident-inc-yyyy-xxx
    match = channel_name.match(/incident-(.+)/)
    return nil unless match

    incident_slug = match[1]
    # Convert inc-2025-001 to INC-2025-001
    incident_slug.upcase.gsub("-", "-")
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
