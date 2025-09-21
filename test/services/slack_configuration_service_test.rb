require "test_helper"

class SlackConfigurationServiceTest < ActiveSupport::TestCase
  test "returns bot token from environment" do
    ENV.stub(:fetch, "test-token") do
      assert_equal "test-token", SlackConfigurationService.bot_token
    end
  end

  test "raises error when bot token missing" do
    ENV.stub(:fetch, ->(*args) { raise KeyError if args.first == "SLACK_BOT_TOKEN" }) do
      assert_raises(RuntimeError, "Missing SLACK_BOT_TOKEN environment variable") do
        SlackConfigurationService.bot_token
      end
    end
  end

  test "generates correct dashboard incident URL" do
    incident = Incident.new(id: 123)

    ENV.stub(:fetch, "https://example.com") do
      url = SlackConfigurationService.dashboard_incident_url(incident)
      assert_equal "https://example.com/incidents/123", url
    end
  end

  test "generates correct incident channel name" do
    channel_name = SlackConfigurationService.incident_channel_name("INC-2025-001")
    assert_equal "incident-inc-2025-001", channel_name
  end

  test "signature verification enabled in production" do
    Rails.env.stub(:development?, false) do
      Rails.env.stub(:test?, false) do
        assert SlackConfigurationService.signature_verification_enabled?
      end
    end
  end

  test "signature verification disabled in development" do
    Rails.env.stub(:development?, true) do
      refute SlackConfigurationService.signature_verification_enabled?
    end
  end

  test "returns correct timeout values" do
    ENV.stub(:fetch, "45") do
      assert_equal 45, SlackConfigurationService.request_timeout
    end
  end

  test "returns default timeout when not set" do
    ENV.stub(:fetch, ->(key, default) { default }) do
      assert_equal 30, SlackConfigurationService.request_timeout
    end
  end

  test "feature flags work correctly" do
    ENV.stub(:fetch, "false") do
      refute SlackConfigurationService.auto_invite_enabled?
    end

    ENV.stub(:fetch, "true") do
      assert SlackConfigurationService.auto_invite_enabled?
    end
  end
end
