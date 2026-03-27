require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @pending_invitation = invitations(:pending_invitation)
    @expired_invitation = invitations(:expired_invitation)
    @accepted_invitation = invitations(:accepted_invitation)
    @admin_invitation = invitations(:admin_invitation)
  end

  # Show - valid pending token

  test "show with valid pending token renders account setup form" do
    get invitation_path(@pending_invitation.token)
    assert_response :success
    assert_match "You've been invited!", response.body
    assert_match @pending_invitation.invited_by.name, response.body
    assert_match "Set up your account below", response.body
    assert_match "Create My Account", response.body
    assert_match @pending_invitation.email, response.body
  end

  # Show - expired token

  test "show with expired token renders expired page" do
    get invitation_path(@expired_invitation.token)
    assert_response :success
    assert_match "Invitation Expired", response.body
    assert_match "This invitation link has expired", response.body
    assert_match "please contact your admin to request a new invitation", response.body.downcase
    assert_match @expired_invitation.email, response.body
  end

  # Show - already accepted token

  test "show with already accepted token renders invalid page" do
    get invitation_path(@accepted_invitation.token)
    assert_response :success
    assert_match "Invalid Invitation", response.body
    assert_match "This invitation link is not valid", response.body
    assert_match "It may have already been used", response.body
  end

  # Show - non-existent / missing token

  test "show with non-existent token renders invalid page" do
    get invitation_path("nonexistent-token-abc123")
    assert_response :success
    assert_match "Invalid Invitation", response.body
    assert_match "This invitation link is not valid", response.body
  end

  # Update - valid submission creates user, marks invitation, signs in, redirects (user role)

  test "update with valid params creates user with invitation email and role, marks invitation accepted, and redirects to dashboard" do
    assert_difference("User.count") do
      patch invitation_path(@pending_invitation.token), params: {
        user: { name: "New User", password: "password123", password_confirmation: "password123" }
      }
    end

    user = User.find_by(email: @pending_invitation.email)
    assert user.present?
    assert_equal "New User", user.name
    assert_equal @pending_invitation.email, user.email
    assert user.user?, "Expected user role, got #{user.role}"
    assert user.confirmed_at.present?, "Expected confirmed_at to be set"
    assert @pending_invitation.reload.accepted?, "Expected invitation to be marked as accepted"
    assert_redirected_to dashboard_path
  end

  # Update - valid submission with admin role redirects to admin_root

  test "update with admin invitation creates admin user and redirects to admin root" do
    patch invitation_path(@admin_invitation.token), params: {
      user: { name: "Admin Invitee", password: "password123", password_confirmation: "password123" }
    }

    user = User.find_by(email: @admin_invitation.email)
    assert user.admin?, "Expected admin role, got #{user.role}"
    assert_redirected_to admin_root_path
  end

  # Update - missing name

  test "update with missing name re-renders show with name error" do
    assert_no_difference("User.count") do
      patch invitation_path(@pending_invitation.token), params: {
        user: { name: "", password: "password123", password_confirmation: "password123" }
      }
    end
    assert_response :unprocessable_entity
    assert_match "Name can&#39;t be blank", response.body
  end

  # Update - password too short

  test "update with password too short re-renders show with password length error" do
    assert_no_difference("User.count") do
      patch invitation_path(@pending_invitation.token), params: {
        user: { name: "New User", password: "short", password_confirmation: "short" }
      }
    end
    assert_response :unprocessable_entity
    assert_match "Password is too short", response.body
  end

  # Update - password mismatch

  test "update with password mismatch re-renders show with confirmation error" do
    assert_no_difference("User.count") do
      patch invitation_path(@pending_invitation.token), params: {
        user: { name: "New User", password: "password123", password_confirmation: "differentpass" }
      }
    end
    assert_response :unprocessable_entity
    assert_match "Password confirmation doesn&#39;t match Password", response.body
  end

  # Update - expired token

  test "update with expired token renders expired page" do
    assert_no_difference("User.count") do
      patch invitation_path(@expired_invitation.token), params: {
        user: { name: "New User", password: "password123", password_confirmation: "password123" }
      }
    end
    assert_response :success
    assert_match "Invitation Expired", response.body
    assert_match "This invitation link has expired", response.body
  end

  # Update - already accepted token

  test "update with already accepted token renders invalid page" do
    assert_no_difference("User.count") do
      patch invitation_path(@accepted_invitation.token), params: {
        user: { name: "New User", password: "password123", password_confirmation: "password123" }
      }
    end
    assert_response :success
    assert_match "Invalid Invitation", response.body
    assert_match "This invitation link is not valid", response.body
  end

  # Update - non-existent token

  test "update with non-existent token renders invalid page" do
    assert_no_difference("User.count") do
      patch invitation_path("nonexistent-token-abc123"), params: {
        user: { name: "New User", password: "password123", password_confirmation: "password123" }
      }
    end
    assert_response :success
    assert_match "Invalid Invitation", response.body
    assert_match "This invitation link is not valid", response.body
  end

  # Update - email and role params in user params are ignored

  test "update ignores email and role in user params and uses invitation values" do
    patch invitation_path(@pending_invitation.token), params: {
      user: { name: "New User", email: "attacker@evil.com", role: "admin", password: "password123", password_confirmation: "password123" }
    }

    user = User.find_by(email: @pending_invitation.email)
    assert user.present?, "User should be created with invitation email"
    assert user.user?, "User should have invitation role (user), got #{user.role}"
    assert_nil User.find_by(email: "attacker@evil.com"), "Attacker email should not exist"
  end
end
