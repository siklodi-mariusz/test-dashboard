require "application_system_test_case"

class AuthenticationErrorsTest < ApplicationSystemTestCase
  test "sign-in with unconfirmed account" do
    user = users(:unconfirmed_user)

    visit new_user_session_path
    assert_text "Sign in to your account"
    fill_in "Email", with: user.email
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
    user = users(:confirmed_user)

    visit new_user_session_path
    assert_text "Sign in to your account"
    fill_in "Email", with: user.email
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

  # Regression test: proves the Turbo form resubmission race condition is real.
  # Amplifies the natural race window by delaying Turbo's render via turbo:before-render,
  # then bypasses wait_for_turbo by calling Capybara directly. Values set on the old
  # (pre-swap) page are lost when Turbo replaces the body with the 422 response.
  test "regression: values set before Turbo render are lost after body swap" do
    visit new_user_registration_path

    # Delay Turbo's rendering by 1s to make the race window deterministic
    page.execute_script(<<~JS)
      document.addEventListener('turbo:before-render', (event) => {
        event.preventDefault();
        setTimeout(() => event.detail.resume(), 1000);
      }, { once: true });
    JS

    # Bypass wait_for_turbo by calling Capybara's find directly
    find(:link_or_button, "Sign up").click

    # fill_in executes on the OLD page — the render is delayed by 1s,
    # so the form still exists with empty fields from the initial visit.
    fill_in "Name", with: "Jane"

    # Wait for the delayed render to complete (validation errors from empty submission appear)
    assert_text "Name can't be blank", wait: 5

    # The value we just set is GONE — Turbo swapped the body with the server's
    # 422 response, which contains the re-rendered form with the originally
    # submitted (empty) values. This is the exact race condition that caused
    # the flaky test.
    assert_equal "", find_field("Name").value,
      "Values set before Turbo render should be lost after body swap"
  end
end
