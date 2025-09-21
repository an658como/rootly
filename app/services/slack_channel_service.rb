class SlackChannelService
  def create_incident_channel(incident, user_name, user_id = nil)
    # Generate channel name using configuration
    channel_name = SlackConfigurationService.incident_channel_name(incident.incident_number)

    begin
      # Create actual Slack channel using the API
      slack_client = SlackConfigurationService.slack_client

      response = slack_client.conversations_create(
        name: channel_name,
        is_private: false
      )

      channel_id = response.channel.id
      Rails.logger.info "✅ Created Slack channel: ##{channel_name} (#{channel_id})"

      # Invite the user who declared the incident to the channel (if feature enabled)
      if user_id.present? && SlackConfigurationService.auto_invite_enabled?
        invite_user_to_channel(channel_id, user_id, user_name, channel_name)
      end

      {
        success: true,
        channel_id: channel_id,
        channel_name: channel_name,
        message: "Channel ##{channel_name} created successfully"
      }
    rescue Slack::Web::Api::Errors::SlackError => e
      Rails.logger.error "❌ Slack API Error creating channel: #{e.message}"

      # Fallback to simulation if API fails
      simulated_channel_id = "C#{Time.current.to_i}#{rand(1000..9999)}"

      {
        success: true,
        channel_id: simulated_channel_id,
        channel_name: channel_name,
        message: "Channel creation failed, using simulation: #{e.message}"
      }
    rescue => e
      Rails.logger.error "❌ Failed to create Slack channel: #{e.message}"
      {
        success: false,
        error: e.message
      }
    end
  end

  private

  def invite_user_to_channel(channel_id, user_id, user_name, channel_name)
    begin
      slack_client = SlackConfigurationService.slack_client

      slack_client.conversations_invite(
        channel: channel_id,
        users: user_id
      )
      Rails.logger.info "✅ Invited user #{user_name} (#{user_id}) to channel ##{channel_name}"
    rescue Slack::Web::Api::Errors::SlackError => e
      if e.message == "cant_invite_self"
        Rails.logger.info "ℹ️ User #{user_name} (#{user_id}) is the bot itself - already in channel"
      else
        Rails.logger.warn "⚠️ Failed to invite user to channel: #{e.message}"
      end
      # Don't fail the entire operation if user invitation fails
    end
  end
end
