require "test_helper"
require "capybara-playwright-driver"

# Register the Playwright-backed Capybara driver.
# We must NOT use the name :playwright because Rails 6.1+ reserves that name
# for its own built-in driver integration.
Capybara.register_driver(:playwright_chromium) do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: :chromium,
    headless: true,
    viewport: { width: 1400, height: 1400 }
  )
end

Capybara.default_max_wait_time = 15

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :playwright_chromium

  private

  def click_on(...)
    register_turbo_navigation_wait
    super.tap { await_turbo_navigation }
  end

  def click_button(...)
    register_turbo_navigation_wait
    super.tap { await_turbo_navigation }
  end

  # Registers a Promise BEFORE the click that resolves when Turbo finishes
  # navigating (turbo:load or turbo:frame-load), with a fallback timeout
  # for clicks that don't trigger navigation.
  def register_turbo_navigation_wait
    page.driver.with_playwright_page do |pw_page|
      pw_page.evaluate(<<~JS)
        (() => {
          window.__turboNavComplete = new Promise(resolve => {
            const finish = () => {
              document.removeEventListener('turbo:load', onNav);
              document.removeEventListener('turbo:frame-load', onNav);
              clearTimeout(timer);
              requestAnimationFrame(() => setTimeout(resolve, 0));
            };
            const onNav = () => finish();
            document.addEventListener('turbo:load', onNav, { once: true });
            document.addEventListener('turbo:frame-load', onNav, { once: true });
            const timer = setTimeout(finish, 300);
          });
        })()
      JS
    end
  rescue Playwright::Error
    # Page not available (e.g. during initial load)
  end

  # Awaits the navigation Promise set up by register_turbo_navigation_wait.
  def await_turbo_navigation
    page.driver.with_playwright_page do |pw_page|
      pw_page.evaluate("() => window.__turboNavComplete")
    end
  rescue Playwright::Error
    # Page may have navigated away or opened a new window
  end

  def sign_in_as(user)
    visit new_user_session_path
    assert_text "Sign in to your account"
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_on "Sign in"
  end
end
