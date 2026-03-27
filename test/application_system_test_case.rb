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
  include Warden::Test::Helpers

  driven_by :playwright_chromium

  teardown do
    Warden.test_reset!
  end

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
  # navigating or rendering. Uses turbo:before-fetch-request to detect whether
  # a request actually started:
  #   - No request: resolves after a short 50ms idle check.
  #   - Request in progress: waits for turbo:load (page navigation),
  #     turbo:frame-load (frame update), or turbo:render (422 form errors),
  #     with a safety-net timeout tied to Capybara.default_max_wait_time.
  def register_turbo_navigation_wait
    max_wait_ms = (Capybara.default_max_wait_time * 1000).to_i
    page.driver.with_playwright_page do |pw_page|
      pw_page.evaluate(<<~JS, arg: max_wait_ms)
        (maxWaitMs) => {
          let navigating = false;

          window.__turboNavComplete = new Promise(resolve => {
            const finish = () => {
              document.removeEventListener('turbo:load', onNav);
              document.removeEventListener('turbo:frame-load', onNav);
              document.removeEventListener('turbo:render', onNav);
              document.removeEventListener('turbo:before-fetch-request', onFetchStart);
              clearTimeout(shortTimer);
              clearTimeout(longTimer);
              requestAnimationFrame(() => setTimeout(resolve, 0));
            };

            const onNav = () => finish();
            const onFetchStart = () => {
              navigating = true;
              clearTimeout(shortTimer);
            };

            document.addEventListener('turbo:before-fetch-request', onFetchStart, { once: true });
            document.addEventListener('turbo:load', onNav, { once: true });
            document.addEventListener('turbo:frame-load', onNav, { once: true });
            document.addEventListener('turbo:render', onNav, { once: true });

            const shortTimer = setTimeout(() => { if (!navigating) finish(); }, 50);
            const longTimer = setTimeout(finish, maxWaitMs);
          });
        }
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
    login_as(user, scope: :user)
  end
end
