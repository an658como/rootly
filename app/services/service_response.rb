class ServiceResponse
  attr_reader :success, :data, :errors, :message

  def initialize(success:, data: {}, errors: {}, message: nil)
    @success = success
    @data = data
    @errors = errors
    @message = message
  end

  def self.success(data = {}, message: nil)
    new(success: true, data: data, message: message)
  end

  def self.failure(errors = {}, message: nil)
    new(success: false, errors: errors, message: message)
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  # For backwards compatibility with existing code that expects hashes
  def to_slack_response
    if success?
      # For Slack responses, prefer message over raw data
      if message.present?
        { text: message }
      elsif data.is_a?(Hash) && data.key?(:text)
        data
      elsif data.is_a?(Hash)
        # If data looks like a Slack response format, use it
        data.key?(:response_action) || data.key?(:blocks) ? data : { text: "Success" }
      else
        { text: message || "Success" }
      end
    else
      if errors.is_a?(Hash) && errors.any?
        { response_action: "errors", errors: errors }
      else
        { text: message || errors.to_s }
      end
    end
  end

  # For JSON APIs
  def to_json_response
    {
      success: success?,
      data: data,
      errors: errors,
      message: message
    }.compact
  end
end
