class SlackModalService
  def open_incident_modal(trigger_id:, title:, user_id:, user_name:, channel_id:)
    # Build the modal view
    modal_view = build_incident_modal(title, user_id, user_name, channel_id)

    # Open the modal using Slack API
    begin
      slack_client = Slack::Web::Client.new(token: ENV["SLACK_BOT_TOKEN"])

      response = slack_client.views_open(
        trigger_id: trigger_id,
        view: modal_view
      )

      # Return empty response (modal opened successfully)
      {}

    rescue Slack::Web::Api::Errors::SlackError => e
      Rails.logger.error "Failed to open Slack modal: #{e.message}"

      # Fallback: show the modal preview
      {
        text: "🚨 Incident declaration for: *#{title}*",
        response_type: "ephemeral",
        attachments: [
          {
            color: "warning",
            text: "Modal would open here (Slack API error: #{e.message}):",
            fields: [
              { title: "Title", value: title, short: true },
              { title: "Severity", value: "Medium (default)", short: true },
              { title: "Description", value: "Optional field", short: false }
            ]
          }
        ]
      }
    rescue => e
      Rails.logger.error "Unexpected error opening modal: #{e.message}"

      {
        text: "❌ Error opening modal: #{e.message}"
      }
    end
  end

  def handle_modal_submission(payload)
    return unless payload["view"]["callback_id"] == "incident_declaration"

    # Extract form data from the modal
    view_state = payload["view"]["state"]["values"]
    private_metadata = JSON.parse(payload["view"]["private_metadata"])

    title = view_state["incident_title"]["title_input"]["value"]
    description = view_state["incident_description"]["description_input"]["value"]
    severity = view_state["incident_severity"]["severity_select"]["selected_option"]["value"]

    user_id = private_metadata["user_id"]
    user_name = private_metadata["user_name"]
    original_channel = private_metadata["original_channel"]

    # Use SlackIncidentService to create the incident
    incident_service = SlackIncidentService.new
    result = incident_service.create_incident(
      title: title,
      description: description,
      severity: severity,
      user_id: user_id,
      user_name: user_name,
      original_channel: original_channel
    )

    if result[:success]
      # For modal submissions, just clear the modal
      {
        response_action: "clear"
      }
    else
      # Error - validation failed
      {
        response_action: "errors",
        errors: result[:errors]
      }
    end
  end

  private

  def build_incident_modal(title, user_id, user_name, channel_id)
    {
      type: "modal",
      callback_id: "incident_declaration",
      title: {
        type: "plain_text",
        text: "🚨 Declare Incident",
        emoji: true
      },
      submit: {
        type: "plain_text",
        text: "Create Incident",
        emoji: true
      },
      close: {
        type: "plain_text",
        text: "Cancel",
        emoji: true
      },
      blocks: [
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: "*Create a new incident to coordinate response efforts.*"
          }
        },
        {
          type: "divider"
        },
        {
          type: "input",
          block_id: "incident_title",
          element: {
            type: "plain_text_input",
            action_id: "title_input",
            initial_value: title,
            placeholder: {
              type: "plain_text",
              text: "Brief description of the incident"
            },
            max_length: 150
          },
          label: {
            type: "plain_text",
            text: "Incident Title *",
            emoji: true
          }
        },
        {
          type: "input",
          block_id: "incident_description",
          element: {
            type: "plain_text_input",
            action_id: "description_input",
            multiline: true,
            placeholder: {
              type: "plain_text",
              text: "Provide additional details about the incident, impact, and any initial findings..."
            },
            max_length: 1000
          },
          label: {
            type: "plain_text",
            text: "Description",
            emoji: true
          },
          optional: true
        },
        {
          type: "input",
          block_id: "incident_severity",
          element: {
            type: "static_select",
            action_id: "severity_select",
            initial_option: {
              text: {
                type: "plain_text",
                text: "🟡 Medium",
                emoji: true
              },
              value: "medium"
            },
            options: [
              {
                text: {
                  type: "plain_text",
                  text: "🟢 Low",
                  emoji: true
                },
                value: "low"
              },
              {
                text: {
                  type: "plain_text",
                  text: "🟡 Medium",
                  emoji: true
                },
                value: "medium"
              },
              {
                text: {
                  type: "plain_text",
                  text: "🟠 High",
                  emoji: true
                },
                value: "high"
              },
              {
                text: {
                  type: "plain_text",
                  text: "🔴 Critical",
                  emoji: true
                },
                value: "critical"
              }
            ]
          },
          label: {
            type: "plain_text",
            text: "Severity Level",
            emoji: true
          }
        },
        {
          type: "context",
          elements: [
            {
              type: "mrkdwn",
              text: "👤 Declared by: @#{user_name} | 📅 #{Time.current.strftime('%B %d, %Y at %I:%M %p %Z')}"
            }
          ]
        }
      ],
      private_metadata: JSON.generate({
        user_id: user_id,
        user_name: user_name,
        original_channel: channel_id
      })
    }
  end
end
