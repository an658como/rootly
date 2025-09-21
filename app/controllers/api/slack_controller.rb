class Api::SlackController < Api::BaseController
  # Slack webhook endpoints - Refactored version using service objects

  # POST /api/slack/commands
  def commands
    # Verify the request is from Slack
    return render json: { error: "Unauthorized" }, status: :unauthorized unless verify_slack_request!

    # Use SlackCommandHandlerService to handle the command
    command_handler = SlackCommandHandlerService.new(params)
    response = command_handler.handle

    # Convert ServiceResponse to Slack-compatible format
    slack_response =  response.to_slack_response
    render json: slack_response, status: :ok
  end

  # POST /api/slack/interactive
  def interactive
    # Verify the request is from Slack
    return render json: { error: "Unauthorized" }, status: :unauthorized unless verify_slack_request!

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

  # POST /api/slack/events
  def events
    # Handle Slack Event Subscriptions

    # Slack sends a challenge parameter for URL verification
    if params[:challenge].present?
      Rails.logger.info "🔐 Slack URL verification challenge received"
      render json: { challenge: params[:challenge] }, status: :ok
      return
    end

    # Verify the request is from Slack (skip for challenge verification)
    return render json: { error: "Unauthorized" }, status: :unauthorized unless verify_slack_request!

    # Handle different event types
    event_data = params[:event]

    if event_data.present?
      case event_data[:type]
      when "message"
        handle_message_event(event_data)
      when "channel_created"
        handle_channel_created_event(event_data)
      else
        Rails.logger.info "📨 Unhandled Slack event: #{event_data[:type]}"
      end
    end

    # Always respond with 200 OK to acknowledge receipt
    render json: { status: "ok" }, status: :ok
  end

  private

  def handle_modal_submission(payload)
    # Use SlackModalService to handle modal submission
    modal_service = SlackModalService.new
    response = modal_service.handle_modal_submission(payload)

    # Convert ServiceResponse to Slack-compatible format
    slack_response = response.to_slack_response
    render json: slack_response, status: :ok
  end

  def handle_block_actions(payload)
    # Handle button clicks and other interactive elements
    render json: {}, status: :ok
  end

  def handle_message_event(event_data)
    # Handle message events (optional - for future features)
    Rails.logger.info "📨 Message event: #{event_data[:text]}"
  end

  def handle_channel_created_event(event_data)
    # Handle channel creation events (optional - for future features)
    Rails.logger.info "📨 Channel created: #{event_data[:channel][:name]}"
  end

  def verify_slack_request!
    # Use SlackRequestVerificationService to verify the request
    verification_service = SlackRequestVerificationService.new(request)
    verification_service.verify!
  end
end