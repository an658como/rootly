require 'test_helper'

class ServiceResponseTest < ActiveSupport::TestCase
  test "creates successful response" do
    response = ServiceResponse.success({ user: "test" }, message: "Success!")
    
    assert response.success?
    refute response.failure?
    assert_equal({ user: "test" }, response.data)
    assert_equal "Success!", response.message
  end

  test "creates failure response" do
    response = ServiceResponse.failure({ field: "error" }, message: "Failed!")
    
    refute response.success?
    assert response.failure?
    assert_equal({ field: "error" }, response.errors)
    assert_equal "Failed!", response.message
  end

  test "converts to slack response format for success with message" do
    response = ServiceResponse.success({ data: "some data" }, message: "Success message")
    slack_response = response.to_slack_response
    
    assert_equal({ text: "Success message" }, slack_response)
  end

  test "converts to slack response format for success with text in data" do
    response = ServiceResponse.success({ text: "Hello from data" })
    slack_response = response.to_slack_response
    
    assert_equal({ text: "Hello from data" }, slack_response)
  end

  test "converts to slack response format for failure with errors" do
    response = ServiceResponse.failure({ "field1" => "error1" })
    slack_response = response.to_slack_response
    
    assert_equal "errors", slack_response[:response_action]
    assert_equal({ "field1" => "error1" }, slack_response[:errors])
  end

  test "converts to slack response format for failure with message" do
    response = ServiceResponse.failure(message: "Something went wrong")
    slack_response = response.to_slack_response
    
    assert_equal({ text: "Something went wrong" }, slack_response)
  end

  test "converts to json response format" do
    response = ServiceResponse.success({ incident: "test" }, message: "Created")
    json_response = response.to_json_response
    
    expected = {
      success: true,
      data: { incident: "test" },
      message: "Created"
    }
    
    assert_equal expected, json_response
  end
end
