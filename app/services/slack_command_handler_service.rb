class SlackCommandHandlerService
  def initialize(params, modal_service: nil, incident_service: nil)
    @command = params[:command]
    @text = params[:text]
    @user_id = params[:user_id]
    @user_name = params[:user_name]
    @channel_id = params[:channel_id]
    @channel_name = params[:channel_name]
    @trigger_id = params[:trigger_id]
    @modal_service = modal_service || SlackModalService.new
    @incident_service = incident_service || SlackIncidentService.new
  end

  def handle
    case @command
    when "/rootly"
      handle_rootly_command
    else
      ServiceResponse.failure(message: "Unknown command: #{@command}")
    end
  end

  private

  def handle_rootly_command
    parts = @text.split(" ", 2)
    subcommand = parts[0]
    args = parts[1]

    case subcommand
    when "declare"
      handle_declare_command(args)
    when "resolve"
      handle_resolve_command
    else
      ServiceResponse.failure(
        message: "Available commands:\n• `/rootly declare <title>` - Declare a new incident\n• `/rootly resolve` - Resolve an incident (in incident channels only)"
      )
    end
  end

  def handle_declare_command(title)
    if title.blank?
      return ServiceResponse.failure(
        message: "Please provide an incident title: `/rootly declare Database is down`"
      )
    end

    if @trigger_id.blank?
      return ServiceResponse.failure(
        message: "❌ Missing trigger_id - cannot open modal. This might be a testing limitation."
      )
    end

    # Use SlackModalService to handle modal opening
    @modal_service.open_incident_modal(
      trigger_id: @trigger_id,
      title: title,
      user_id: @user_id,
      user_name: @user_name,
      channel_id: @channel_id
    )
  end

  def handle_resolve_command
    # Check if this is an incident channel
    unless @channel_name&.start_with?("incident-")
      return ServiceResponse.failure(
        message: "❌ `/rootly resolve` can only be used in incident channels (#incident-*)"
      )
    end

    # Use SlackIncidentService to handle resolution
    @incident_service.resolve_from_channel(
      channel_name: @channel_name,
      user_name: @user_name
    )
  end
end
