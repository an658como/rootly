class SlackRequestVerificationService
  def initialize(request)
    @request = request
  end

  def verify!
    # In development/testing, skip verification
    return true unless SlackConfigurationService.signature_verification_enabled?

    # Get Slack signing secret from configuration
    signing_secret = SlackConfigurationService.signing_secret

    # Get request timestamp and signature from headers
    timestamp = @request.headers["X-Slack-Request-Timestamp"]
    signature = @request.headers["X-Slack-Signature"]

    return false if timestamp.blank? || signature.blank?

    # Check if request is too old (replay attack protection)
    max_age = SlackConfigurationService.signature_max_age_seconds
    return false if (Time.current.to_i - timestamp.to_i).abs > max_age

    # Get raw request body
    body = @request.raw_post

    # Create the signature base string
    sig_basestring = "v0:#{timestamp}:#{body}"

    # Calculate expected signature
    expected_signature = "v0=" + OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new("sha256"),
      signing_secret,
      sig_basestring
    )

    # Compare signatures using secure comparison
    ActiveSupport::SecurityUtils.secure_compare(signature, expected_signature)
  rescue => e
    Rails.logger.error "Slack signature verification failed: #{e.message}"
    false
  end

  private

  attr_reader :request
end
