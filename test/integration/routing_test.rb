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

  # Admin routes

  test "GET /admin routes to admin users index" do
    sign_in users(:admin_user)
    get admin_root_path
    assert_response :success
  end

  test "GET /admin/users routes to admin users index" do
    sign_in users(:admin_user)
    get admin_users_path
    assert_response :success
  end

  test "GET /admin/users/:id routes to admin users show" do
    sign_in users(:admin_user)
    get admin_user_path(users(:confirmed_user))
    assert_response :success
  end

  test "GET /admin/users/:id/edit routes to admin users edit" do
    sign_in users(:admin_user)
    get edit_admin_user_path(users(:confirmed_user))
    assert_response :success
  end

  test "PATCH /admin/users/:id routes to admin users update" do
    sign_in users(:admin_user)
    patch admin_user_path(users(:confirmed_user)), params: { user: { name: "Routed" } }
    assert_redirected_to admin_user_path(users(:confirmed_user))
  end

  test "DELETE /admin/users/:id routes to admin users destroy" do
    sign_in users(:admin_user)
    delete admin_user_path(users(:unconfirmed_user))
    assert_redirected_to admin_users_path
  end

  test "admin create route does not exist" do
    assert_not Rails.application.routes.recognize_path("/admin/users", method: :post)
  rescue ActionController::RoutingError
    pass
  end
end
