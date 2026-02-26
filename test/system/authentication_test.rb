require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  setup do
    ActionMailer::Base.deliveries.clear
  end

  test "full sign-up, confirmation, and login flow" do
    # Visit root, should redirect to sign-in
    visit root_path
    assert_current_path new_user_session_path

    # Navigate to sign-up
    click_on "Sign up"
    assert_current_path new_user_registration_path

    # Fill in sign-up form
    fill_in "Name", with: "Alice Test"
    fill_in "Email", with: "alice@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    click_on "Sign up"

    # Assert confirmation flash
    assert_text "A message with a confirmation link has been sent to your email address"

    # Extract confirmation link from email
    confirmation_email = ActionMailer::Base.deliveries.last
    assert confirmation_email.present?, "Confirmation email should be sent"
    confirmation_url = extract_url_from_email(confirmation_email, "confirmation_token")
    visit confirmation_url

    # Assert confirmation success
    assert_text "Your email address has been successfully confirmed"

    # Sign in
    fill_in "Email", with: "alice@example.com"
    fill_in "Password", with: "password123"
    click_on "Sign in"

    # Assert dashboard (authenticated root is /)
    assert_text "Welcome, Alice Test!"

    # Log out
    click_on "Log out"
    assert_current_path new_user_session_path

    # Verify can't access dashboard after logout
    visit dashboard_path
    assert_current_path new_user_session_path
  end

  test "password reset flow" do
    create_confirmed_user(name: "Bob Reset", email: "bob-reset@example.com")
    ActionMailer::Base.deliveries.clear

    visit new_user_session_path
    click_on "Forgot your password?"

    fill_in "Email", with: "bob-reset@example.com"
    click_on "Send me reset password instructions"

    # Extract reset link from email
    assert_text "You will receive an email"
    reset_email = ActionMailer::Base.deliveries.last
    assert reset_email.present?, "Reset email should be sent (total deliveries: #{ActionMailer::Base.deliveries.count}, object_id: #{ActionMailer::Base.deliveries.object_id})"
    reset_url = extract_url_from_email(reset_email, "reset_password_token")
    visit reset_url

    fill_in "New password", with: "newpassword456"
    fill_in "Confirm new password", with: "newpassword456"
    click_on "Change my password"

    # Assert signed in and on dashboard
    assert_text "Welcome, Bob Reset!"
  end

  test "remember me keeps user authenticated" do
    create_confirmed_user(name: "Carol Remember", email: "carol-remember@example.com")

    visit new_user_session_path
    fill_in "Email", with: "carol-remember@example.com"
    fill_in "Password", with: "password123"
    check "Remember me"
    click_on "Sign in"

    assert_text "Welcome, Carol Remember!"

    # Simulate session expiry by clearing the session cookie but keeping remember_me
    expire_session_cookie

    visit dashboard_path
    assert_text "Welcome, Carol Remember!"
  end

  test "account deletion" do
    create_confirmed_user(name: "Dave Delete", email: "dave-delete@example.com")

    # Sign in
    visit new_user_session_path
    fill_in "Email", with: "dave-delete@example.com"
    fill_in "Password", with: "password123"
    click_on "Sign in"
    assert_text "Welcome, Dave Delete!"

    # Visit edit page and delete account
    visit edit_user_registration_path
    accept_confirm "Are you sure you want to delete your account?" do
      click_on "Delete my account"
    end

    # Assert deletion flash and redirect
    assert_text "successfully"

    # Try to sign in with deleted credentials
    visit new_user_session_path
    fill_in "Email", with: "dave-delete@example.com"
    fill_in "Password", with: "password123"
    click_on "Sign in"
    assert_text "Invalid email or password"
  end

  test "authenticated root redirects to dashboard" do
    create_confirmed_user(name: "Eve Root", email: "eve-root@example.com")

    visit new_user_session_path
    fill_in "Email", with: "eve-root@example.com"
    fill_in "Password", with: "password123"
    click_on "Sign in"

    assert_text "Welcome, Eve Root!"

    visit root_path
    assert_text "Welcome, Eve Root!"
  end

  private

  def create_confirmed_user(name: "Test User", email: "test@example.com")
    User.create!(
      name: name,
      email: email,
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )
  end

  def extract_url_from_email(email, token_param)
    body = email.body.to_s
    url = body[/href="([^"]*#{token_param}[^"]*)"/, 1]
    if url&.start_with?("http")
      uri = URI.parse(url)
      "#{uri.path}?#{uri.query}"
    else
      url
    end
  end

  def expire_session_cookie
    browser = Capybara.current_session.driver.browser
    session_cookie = browser.manage.all_cookies.find { |c| c[:name] == "_test_dashboard_session" }
    browser.manage.delete_cookie("_test_dashboard_session") if session_cookie
  end
end
