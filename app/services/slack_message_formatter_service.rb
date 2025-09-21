class SlackMessageFormatterService
  def post_incident_summary_to_channel(incident, channel_id)
    # Build the incident summary message for the channel
    summary_blocks = build_incident_summary_blocks(incident)

    begin
      # Post actual message to Slack channel
      slack_client = SlackConfigurationService.slack_client

      response = slack_client.chat_postMessage(
        channel: channel_id,
        blocks: summary_blocks,
        text: "Incident #{incident.incident_number}: #{incident.title}"
      )

      Rails.logger.info "✅ Posted incident summary to channel #{channel_id}"
      true
    rescue Slack::Web::Api::Errors::SlackError => e
      Rails.logger.error "❌ Slack API Error posting message: #{e.message}"
      false
    rescue => e
      Rails.logger.error "❌ Failed to post incident summary: #{e.message}"
      false
    end
  end

  def build_incident_created_message(incident, user_name)
    channel_info = if incident.slack_channel_name.present?
      "💬 Dedicated channel: ##{incident.slack_channel_name}"
    else
      "💬 Dedicated channel: ##{SlackConfigurationService.incident_channel_name(incident.incident_number)} (creating...)"
    end

    "🎉 *Incident #{incident.incident_number} Created Successfully*\n" \
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" \
    "📋 #{incident.title}\n" \
    "📊 Severity: #{incident.severity.humanize}\n" \
    "👤 Declared by: @#{user_name}\n" \
    "🔄 Status: #{incident.status.humanize}\n" \
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" \
    "📱 View in dashboard: #{SlackConfigurationService.dashboard_incident_url(incident)}\n" \
    "#{channel_info}"
  end

  private

  def build_incident_summary_blocks(incident)
    [
      {
        type: "header",
        text: {
          type: "plain_text",
          text: "🚨 #{incident.incident_number}: #{incident.title}",
          emoji: true
        }
      },
      {
        type: "section",
        fields: [
          {
            type: "mrkdwn",
            text: "*Severity:*\n#{severity_emoji(incident.severity)} #{incident.severity.humanize}"
          },
          {
            type: "mrkdwn",
            text: "*Status:*\n🔄 #{incident.status.humanize}"
          },
          {
            type: "mrkdwn",
            text: "*Declared by:*\n👤 @#{incident.declared_by}"
          },
          {
            type: "mrkdwn",
            text: "*Created:*\n📅 #{incident.created_at.strftime('%B %d, %Y at %I:%M %p %Z')}"
          }
        ]
      },
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: "*Description:*\n#{incident.description.presence || '_No description provided_'}"
        }
      },
      {
        type: "divider"
      },
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: "📱 *<#{SlackConfigurationService.dashboard_incident_url(incident)}|View in Dashboard>*"
        }
      },
      {
        type: "context",
        elements: [
          {
            type: "mrkdwn",
            text: "Use `/rootly resolve` in this channel when the incident is resolved"
          }
        ]
      }
    ]
  end

  def severity_emoji(severity)
    case severity.to_s
    when "low" then "🟢"
    when "medium" then "🟡"
    when "high" then "🟠"
    when "critical" then "🔴"
    else "⚪"
    end
  end
end
