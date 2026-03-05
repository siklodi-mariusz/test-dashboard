require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @regular_user = users(:confirmed_user)
    @unconfirmed_user = users(:unconfirmed_user)
  end

  # Authorization

  test "unauthenticated user is redirected to sign-in" do
    get admin_users_path
    assert_redirected_to new_user_session_path
  end

  test "non-admin user is redirected to dashboard with alert" do
    sign_in @regular_user
    get admin_users_path
    assert_redirected_to dashboard_path
    assert_equal "You are not authorized to access this page.", flash[:alert]
  end

  test "non-admin user cannot access show" do
    sign_in @regular_user
    get admin_user_path(@regular_user)
    assert_redirected_to dashboard_path
  end

  test "non-admin user cannot access edit" do
    sign_in @regular_user
    get edit_admin_user_path(@regular_user)
    assert_redirected_to dashboard_path
  end

  test "non-admin user cannot update" do
    sign_in @regular_user
    patch admin_user_path(@regular_user), params: { user: { name: "Hacked" } }
    assert_redirected_to dashboard_path
    assert_equal "Jane Doe", @regular_user.reload.name
  end

  test "non-admin user cannot destroy" do
    sign_in @regular_user
    assert_no_difference("User.count") do
      delete admin_user_path(@unconfirmed_user)
    end
    assert_redirected_to dashboard_path
  end

  # Index

  test "admin can access users index" do
    sign_in @admin
    get admin_users_path
    assert_response :success
    assert_match @regular_user.name, response.body
    assert_match @admin.name, response.body
  end

  # Live updates

  test "admin layout subscribes to admin_notifications with turbo-permanent to prevent duplicate subscriptions" do
    sign_in @admin
    get admin_users_path
    assert_select "[data-turbo-permanent]" do
      assert_select "turbo-cable-stream-source[signed-stream-name]"
    end
  end

  test "users index table body has id for turbo stream targeting" do
    sign_in @admin
    get admin_users_path
    assert_select "tbody#admin_users_table_body"
  end

  test "admin layout includes toast container" do
    sign_in @admin
    get admin_users_path
    assert_select "#admin_toast_container"
  end

  # Show

  test "admin can view user details" do
    sign_in @admin
    get admin_user_path(@regular_user)
    assert_response :success
    assert_match @regular_user.name, response.body
    assert_match @regular_user.email, response.body
  end

  # Edit

  test "admin can access edit form" do
    sign_in @admin
    get edit_admin_user_path(@regular_user)
    assert_response :success
    assert_match "Edit User", response.body
  end

  # Update

  test "admin can update user name" do
    sign_in @admin
    patch admin_user_path(@regular_user), params: { user: { name: "Updated Jane" } }
    assert_redirected_to admin_user_path(@regular_user)
    assert_equal "Updated Jane", @regular_user.reload.name
  end

  test "admin can update user email" do
    sign_in @admin
    patch admin_user_path(@regular_user), params: { user: { email: "newemail@example.com" } }
    assert_redirected_to admin_user_path(@regular_user)
    # Devise confirmable stores the new email in unconfirmed_email until confirmed
    updated_user = @regular_user.reload
    if updated_user.respond_to?(:unconfirmed_email) && updated_user.unconfirmed_email.present?
      assert_equal "newemail@example.com", updated_user.unconfirmed_email
    else
      assert_equal "newemail@example.com", updated_user.email
    end
  end

  test "admin can update user role" do
    sign_in @admin
    patch admin_user_path(@regular_user), params: { user: { role: "admin" } }
    assert_redirected_to admin_user_path(@regular_user)
    assert @regular_user.reload.admin?
  end

  test "update with invalid data re-renders edit with 422" do
    sign_in @admin
    patch admin_user_path(@regular_user), params: { user: { name: "" } }
    assert_response :unprocessable_entity
    assert_match "Edit User", response.body
  end

  test "update prevents demoting the last admin" do
    sign_in @admin
    assert_equal 1, User.where(role: :admin).count

    patch admin_user_path(@admin), params: { user: { role: "user" } }
    assert_response :unprocessable_entity
    assert @admin.reload.admin?, "Last admin should not be demoted"
  end

  # Destroy

  test "admin can delete another user" do
    sign_in @admin
    assert_difference("User.count", -1) do
      delete admin_user_path(@regular_user)
    end
    assert_redirected_to admin_users_path
    assert_equal "User was successfully deleted.", flash[:notice]
  end

  test "admin cannot delete themselves" do
    sign_in @admin
    assert_no_difference("User.count") do
      delete admin_user_path(@admin)
    end
    assert_redirected_to admin_users_path
    assert_equal "You cannot delete your own account.", flash[:alert]
  end
end
