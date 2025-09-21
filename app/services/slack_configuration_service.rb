class SlackConfigurationService
  class << self
    def bot_token
      ENV.fetch("SLACK_BOT_TOKEN") do
        raise "Missing SLACK_BOT_TOKEN environment variable"
      end
    end

    def signing_secret
      ENV.fetch("SLACK_SIGNING_SECRET") do
        raise "Missing SLACK_SIGNING_SECRET environment variable"
      end
    end

    def dashboard_base_url
      ENV.fetch("DASHBOARD_BASE_URL", "http://localhost:3000")
    end

    def dashboard_incident_url(incident)
      "#{dashboard_base_url}/incidents/#{incident.id}"
    end

    # Slack API configuration
    def request_timeout
      ENV.fetch("SLACK_REQUEST_TIMEOUT", "30").to_i
    end

    def max_retries
      ENV.fetch("SLACK_MAX_RETRIES", "3").to_i
    end

    # Channel naming configuration
    def incident_channel_prefix
      ENV.fetch("INCIDENT_CHANNEL_PREFIX", "incident")
    end

    def incident_channel_name(incident_number)
      "#{incident_channel_prefix}-#{incident_number.downcase}"
    end

    # Security configuration
    def signature_verification_enabled?
      !Rails.env.development? && !Rails.env.test?
    end

    def signature_max_age_seconds
      ENV.fetch("SLACK_SIGNATURE_MAX_AGE", "300").to_i # 5 minutes
    end

    # Feature flags
    def auto_invite_enabled?
      ENV.fetch("SLACK_AUTO_INVITE", "true") == "true"
    end

    def incident_summary_enabled?
      ENV.fetch("SLACK_INCIDENT_SUMMARY", "true") == "true"
    end

    # Slack client factory
    def slack_client
      require "slack-ruby-client"
      Slack::Web::Client.new(
        token: bot_token,
        timeout: request_timeout
      )
    end
  end
end
