require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:confirmed_user)
  end

  test "authenticated user can access dashboard" do
    sign_in @user
    get dashboard_path
    assert_response :success
    assert_match "Welcome", response.body
  end

  test "unauthenticated user is redirected to sign-in" do
    get dashboard_path
    assert_redirected_to new_user_session_path
  end

  test "dashboard displays the user's name" do
    sign_in @user
    get dashboard_path
    assert_match "Welcome, Jane Doe!", response.body
  end

  test "admin sign-in redirects to admin root" do
    admin = users(:admin_user)
    post user_session_path, params: {
      user: { email: admin.email, password: "password123" }
    }
    assert_redirected_to admin_root_path
  end

  test "regular user sign-in redirects to dashboard" do
    post user_session_path, params: {
      user: { email: @user.email, password: "password123" }
    }
    assert_redirected_to dashboard_path
  end
end
