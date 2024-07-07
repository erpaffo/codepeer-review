require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get complete_profile" do
    get users_complete_profile_url
    assert_response :success
  end
end
