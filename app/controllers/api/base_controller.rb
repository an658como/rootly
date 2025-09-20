class Api::BaseController < ApplicationController
  # Skip CSRF protection for API requests
  skip_before_action :verify_authenticity_token
  
  # Ensure all responses are JSON
  before_action :set_default_response_format
  
  protected
  
  def set_default_response_format
    request.format = :json
  end
  
  def render_json_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end
  
  def render_json_success(data = {}, message = nil)
    response = data.is_a?(Hash) ? data : { data: data }
    response[:message] = message if message
    render json: response
  end
end
