require "test_helper"

class SlackIncidentServiceTest < ActiveSupport::TestCase
  def setup
    @mock_channel_service = Minitest::Mock.new
    @mock_message_service = Minitest::Mock.new
    @service = SlackIncidentService.new(
      channel_service: @mock_channel_service,
      message_service: @mock_message_service
    )
  end

  test "successfully creates incident with channel and message posting" do
    # Mock channel creation
    @mock_channel_service.expect(
      :create_incident_channel,
      { success: true, channel_id: "C123", channel_name: "incident-inc-2025-001" },
      [ Incident, "testuser", "U123" ]
    )

    # Mock message posting (if enabled)
    if SlackConfigurationService.incident_summary_enabled?
      @mock_message_service.expect(
        :post_incident_summary_to_channel,
        true,
        [ Incident, "C123" ]
      )
    end

    result = @service.create_incident(
      title: "Test Incident",
      description: "Test Description",
      severity: "medium",
      user_id: "U123",
      user_name: "testuser",
      original_channel: "C456"
    )

    assert result.success?
    assert_instance_of Incident, result.data[:incident]
    assert_equal "Test Incident", result.data[:incident].title

    @mock_channel_service.verify
    @mock_message_service.verify if SlackConfigurationService.incident_summary_enabled?
  end

  test "handles incident validation errors" do
    result = @service.create_incident(
      title: "", # Invalid title
      description: "Test Description",
      severity: "medium",
      user_id: "U123",
      user_name: "testuser",
      original_channel: "C456"
    )

    assert result.failure?
    assert_includes result.errors["incident_title"], "can't be blank"
  end

  test "resolves incident successfully" do
    incident = incidents(:one) # Assuming you have fixtures
    incident.update!(incident_number: "INC-2025-001", status: "open")

    result = @service.resolve_from_channel(
      channel_name: "incident-inc-2025-001",
      user_name: "testuser"
    )

    assert result.success?
    assert_equal "resolved", incident.reload.status
  end

  test "handles non-existent incident for resolution" do
    result = @service.resolve_from_channel(
      channel_name: "incident-inc-2025-999",
      user_name: "testuser"
    )

    assert result.failure?
    assert_includes result.message, "not found"
  end

  private

  def teardown
    @mock_channel_service = nil
    @mock_message_service = nil
  end
end
