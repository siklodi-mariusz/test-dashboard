require "application_system_test_case"

class AuthenticationErrorsTest < ApplicationSystemTestCase
  test "sign-in with unconfirmed account" do
    User.create!(
      name: "Unconfirmed User",
      email: "unconfirmed-sys@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    visit new_user_session_path
    fill_in "Email", with: "unconfirmed-sys@example.com"
    fill_in "Password", with: "password123"
    click_on "Sign in"

    assert_text "You have to confirm your email address before continuing"
    assert_current_path new_user_session_path
  end

  test "sign-up with invalid data" do
    visit new_user_registration_path

    # Submit empty form
    click_on "Sign up"

    assert_text "Name can't be blank"
    assert_text "Email can't be blank"
    assert_text "Password can't be blank"

    # Fill in with mismatched passwords
    fill_in "Name", with: "Jane"
    fill_in "Email", with: "jane-invalid@example.com"
    fill_in "Password", with: "pass123"
    fill_in "Password confirmation", with: "different"
    click_on "Sign up"

    assert_text "Password confirmation doesn't match Password"
  end

  test "sign-in with wrong credentials" do
    User.create!(
      name: "Wrong Creds User",
      email: "wrongcreds@example.com",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    visit new_user_session_path
    fill_in "Email", with: "wrongcreds@example.com"
    fill_in "Password", with: "wrongpassword"
    click_on "Sign in"

    assert_text "Invalid email or password"
    assert_current_path new_user_session_path
  end

  test "access dashboard without authentication" do
    visit dashboard_path
    assert_current_path new_user_session_path
    assert_text "You need to sign in or sign up before continuing"
  end
end
