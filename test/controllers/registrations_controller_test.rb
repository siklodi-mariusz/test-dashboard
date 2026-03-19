require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "sign-up accepts name parameter" do
    assert_difference("User.count", 1) do
      post user_registration_path, params: {
        user: {
          name: "New User",
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_equal "New User", User.find_by(email: "newuser@example.com").name
  end

  test "sign-up without name fails" do
    assert_no_difference("User.count") do
      post user_registration_path, params: {
        user: {
          name: "",
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_response :unprocessable_content
  end

  test "account update accepts name parameter" do
    user = users(:confirmed_user)
    sign_in user
    put user_registration_path, params: {
      user: {
        name: "Updated Name",
        current_password: "password123"
      }
    }
    assert_equal "Updated Name", user.reload.name
  end

  test "non-whitelisted params are ignored on sign-up" do
    post user_registration_path, params: {
      user: {
        name: "New User",
        email: "sneaky@example.com",
        password: "password123",
        password_confirmation: "password123",
        role: "admin"
      }
    }
    user = User.find_by(email: "sneaky@example.com")
    assert user.present?
    assert_equal "New User", user.name
    assert user.user?, "Expected role to be user, but was #{user.role}"
  end

  # Invitation linking on self-registration

  test "self-registration with matching pending invitation accepts it and assigns its role" do
    invitation = invitations(:admin_invitation)

    post user_registration_path, params: {
      user: {
        name: "Admin Invitee",
        email: invitation.email,
        password: "password123",
        password_confirmation: "password123"
      }
    }

    invitation.reload
    created_user = User.find_by(email: invitation.email)

    assert_not_nil invitation.accepted_at, "Expected invitation to be marked as accepted"
    assert created_user.admin?, "Expected user role to match invitation role (admin)"
    assert_nil created_user.confirmed_at, "Expected Devise email confirmation to still be required"
  end
end
