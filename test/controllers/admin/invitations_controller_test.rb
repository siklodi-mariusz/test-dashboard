require "test_helper"

class Admin::InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @regular_user = users(:confirmed_user)
    @pending_invitation = invitations(:pending_invitation)
  end

  # Authorization

  test "unauthenticated user is redirected to sign-in" do
    get new_admin_invitation_path
    assert_redirected_to new_user_session_path
  end

  test "non-admin user is redirected to dashboard" do
    sign_in @regular_user
    get new_admin_invitation_path
    assert_redirected_to dashboard_path
    assert_equal "You are not authorized to access this page.", flash[:alert]
  end

  test "non-admin user cannot create invitation" do
    sign_in @regular_user
    assert_no_difference("Invitation.count") do
      post admin_invitations_path, params: { invitation: { email: "test@example.com", role: "user" } }
    end
    assert_redirected_to dashboard_path
  end

  # New

  test "admin can access new as html" do
    sign_in @admin
    get new_admin_invitation_path
    assert_response :success
  end

  test "admin can access new as turbo_stream" do
    sign_in @admin
    get new_admin_invitation_path, as: :turbo_stream
    assert_response :success
    assert_match "modal", response.body
  end

  # Create

  test "admin can create invitation" do
    sign_in @admin
    assert_difference("Invitation.count") do
      post admin_invitations_path, params: { invitation: { email: "newinvite@example.com", role: "user" } }
    end
    assert_redirected_to admin_users_path
    assert_match "newinvite@example.com", flash[:notice]
    assert_equal @admin, Invitation.find_by(email: "newinvite@example.com").invited_by
  end

  test "create sends invitation email" do
    sign_in @admin
    assert_emails 1 do
      post admin_invitations_path, params: { invitation: { email: "mailer@example.com", role: "user" } }
    end
  end

  test "create with invalid email re-renders new" do
    sign_in @admin
    assert_no_difference("Invitation.count") do
      post admin_invitations_path, params: { invitation: { email: "", role: "user" } }
    end
    assert_response :unprocessable_entity
  end

  test "create with duplicate email re-renders new" do
    sign_in @admin
    assert_no_difference("Invitation.count") do
      post admin_invitations_path, params: { invitation: { email: @pending_invitation.email, role: "user" } }
    end
    assert_response :unprocessable_entity
  end

  test "create with existing user email re-renders new" do
    sign_in @admin
    assert_no_difference("Invitation.count") do
      post admin_invitations_path, params: { invitation: { email: @regular_user.email, role: "user" } }
    end
    assert_response :unprocessable_entity
  end

  # Edit

  test "admin can access edit as html" do
    sign_in @admin
    get edit_admin_invitation_path(@pending_invitation)
    assert_response :success
  end

  test "admin can access edit as turbo_stream" do
    sign_in @admin
    get edit_admin_invitation_path(@pending_invitation), as: :turbo_stream
    assert_response :success
    assert_match "modal", response.body
  end

  # Update

  test "admin can update invitation email" do
    sign_in @admin
    patch admin_invitation_path(@pending_invitation), params: { invitation: { email: "updated@example.com" } }
    assert_redirected_to admin_users_path
    assert_equal "updated@example.com", @pending_invitation.reload.email
  end

  test "admin can update invitation role" do
    sign_in @admin
    patch admin_invitation_path(@pending_invitation), params: { invitation: { role: "admin" } }
    assert_redirected_to admin_users_path
    assert @pending_invitation.reload.admin?
  end

  test "update with invalid data re-renders edit" do
    sign_in @admin
    patch admin_invitation_path(@pending_invitation), params: { invitation: { email: "" } }
    assert_response :unprocessable_entity
  end
end
