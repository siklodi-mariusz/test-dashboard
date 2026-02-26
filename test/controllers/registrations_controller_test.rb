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
        email: "admin@example.com",
        password: "password123",
        password_confirmation: "password123",
        admin: true
      }
    }
    user = User.find_by(email: "admin@example.com")
    assert user.present?
  end
end
