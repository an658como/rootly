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
    when "/rootly"
      handle_rootly_command(text, user_id, user_name, channel_id, channel_name)
    else
      render json: { text: "Unknown command: #{command}" }, status: :ok
    end
  end

  # POST /api/slack/interactive
  def interactive
    # Handle Slack interactive components (modals, buttons, etc.)
    payload = JSON.parse(params[:payload])

    case payload["type"]
    when "view_submission"
      handle_modal_submission(payload)
    when "block_actions"
      handle_block_actions(payload)
    else
      render json: {}, status: :ok
    end
  end

  private

  def handle_rootly_command(text, user_id, user_name, channel_id, channel_name)
    parts = text.split(" ", 2)
    subcommand = parts[0]
    args = parts[1]

    case subcommand
    when "declare"
      handle_declare_command(args, user_id, user_name, channel_id, channel_name)
    when "resolve"
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

    # Build and return the modal view
    modal_view = build_incident_modal(title, user_id, user_name)

    # For testing purposes, we'll return the modal JSON
    # In a real Slack app, you'd use the Slack API to open the modal with the trigger_id
    render json: {
      text: "🚨 Incident declaration for: *#{title}*",
      response_type: "ephemeral",
      attachments: [
        {
          color: "warning",
          text: "Modal would open here with the following form:",
          fields: [
            { title: "Title", value: title, short: true },
            { title: "Severity", value: "Medium (default)", short: true },
            { title: "Description", value: "Optional field", short: false }
          ]
        }
      ]
    }, status: :ok
  end

  def handle_resolve_command(user_id, user_name, channel_id, channel_name)
    # Check if this is an incident channel
    unless channel_name&.start_with?("incident-")
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
      success_message = build_incident_created_message(incident, user_name)

      # TODO: Create Slack channel for the incident
      # TODO: Post incident summary to the channel

      render json: {
        response_action: "clear",
        text: success_message
      }, status: :ok
    else
      # Error - validation failed
      error_message = "❌ Failed to create incident: #{incident.errors.full_messages.join(', ')}"

      render json: {
        response_action: "errors",
        errors: {
          "incident_title" => incident.errors[:title].first || "",
          "incident_description" => incident.errors[:description].first || "",
          "incident_severity" => incident.errors[:severity].first || ""
        }
      }, status: :ok
    end
  end

  def handle_block_actions(payload)
    # Handle button clicks and other interactive elements
    render json: {}, status: :ok
  end

  def build_incident_modal(title, user_id, user_name)
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
        original_channel: params[:channel_id]
      })
    }
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

  def build_incident_created_message(incident, user_name)
    "🎉 *Incident #{incident.incident_number} Created Successfully*\n" \
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" \
    "📋 #{incident.title}\n" \
    "📊 Severity: #{incident.severity.humanize}\n" \
    "👤 Declared by: @#{user_name}\n" \
    "🔄 Status: #{incident.status.humanize}\n" \
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" \
    "📱 View in dashboard: #{dashboard_incident_url(incident)}\n" \
    "💬 Dedicated channel: #incident-#{incident.incident_number.downcase} (coming soon)"
  end
end
