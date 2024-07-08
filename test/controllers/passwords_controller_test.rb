require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get passwords_edit_url
    assert_response :success
  end

  test "should get update" do
    get passwords_update_url
    assert_response :success
  end
end
