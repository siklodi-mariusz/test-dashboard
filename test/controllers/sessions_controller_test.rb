require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "unconfirmed user cannot sign in" do
    post user_session_path, params: {
      user: {
        email: users(:unconfirmed_user).email,
        password: "password123"
      }
    }
    assert_redirected_to new_user_session_path
    follow_redirect!
    assert_match(/confirm/, response.body)
  end
end
