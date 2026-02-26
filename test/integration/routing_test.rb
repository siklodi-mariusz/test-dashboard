require "test_helper"

class RoutingTest < ActionDispatch::IntegrationTest
  test "root redirects to sign-in when unauthenticated" do
    get root_path
    assert_redirected_to "/users/sign_in"
  end

  test "root redirects to dashboard when authenticated" do
    sign_in users(:confirmed_user)
    get root_path
    assert_response :success
    assert_match "Welcome", response.body
  end
end
