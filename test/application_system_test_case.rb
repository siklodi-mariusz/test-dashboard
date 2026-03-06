require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  private

  def click_on(...)
    super.tap { wait_for_turbo }
  end

  def click_button(...)
    super.tap { wait_for_turbo }
  end

  # Waits for Turbo Drive to finish processing (navigation, form submission, body swap).
  # Ensures the browser has completed rendering and all post-render callbacks have run.
  def wait_for_turbo(timeout: Capybara.default_max_wait_time)
    return if alert_open?
    has_no_css?(".turbo-progress-bar", visible: true, wait: timeout)
    page.evaluate_async_script("requestAnimationFrame(() => setTimeout(arguments[arguments.length - 1], 0))")
  rescue Selenium::WebDriver::Error::JavascriptError,
         Selenium::WebDriver::Error::NoSuchWindowError
    # Page may have navigated away or opened a new window
  end

  def alert_open?
    page.driver.browser.switch_to.alert
    true
  rescue Selenium::WebDriver::Error::NoSuchAlertError
    false
  end

  def sign_in_as(user)
    visit new_user_session_path
    assert_text "Sign in to your account"
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_on "Sign in"
  end
end
