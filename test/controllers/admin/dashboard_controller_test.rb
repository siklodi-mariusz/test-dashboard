require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @regular_user = users(:confirmed_user)
    @unconfirmed_user = users(:unconfirmed_user)
  end

  # Authorization

  test "unauthenticated user is redirected to sign-in" do
    get admin_dashboard_path
    assert_redirected_to new_user_session_path
  end

  test "unauthenticated user accessing admin root is redirected to sign-in" do
    get admin_root_path
    assert_redirected_to new_user_session_path
  end

  test "non-admin user is redirected to dashboard with alert" do
    sign_in @regular_user
    get admin_dashboard_path
    assert_redirected_to dashboard_path
    assert_equal "You are not authorized to access this page.", flash[:alert]
  end

  test "non-admin user accessing admin root is redirected with alert" do
    sign_in @regular_user
    get admin_root_path
    assert_redirected_to dashboard_path
    assert_equal "You are not authorized to access this page.", flash[:alert]
  end

  # Successful access

  test "admin can access the dashboard" do
    sign_in @admin
    get admin_dashboard_path
    assert_response :success
  end

  test "admin root renders the dashboard" do
    sign_in @admin
    get admin_root_path
    assert_response :success
    assert_match "Hello, #{@admin.name}!", response.body
  end

  # Period parameter handling

  test "default period is 7d" do
    sign_in @admin
    get admin_dashboard_path
    assert_response :success
    assert_select "a.bg-white.shadow-sm", text: "7d"
  end

  test "period 1h is accepted and active" do
    sign_in @admin
    get admin_dashboard_path(period: "1h")
    assert_response :success
    assert_select "a.bg-white.shadow-sm", text: "1h"
  end

  test "period 1d is accepted and active" do
    sign_in @admin
    get admin_dashboard_path(period: "1d")
    assert_response :success
    assert_select "a.bg-white.shadow-sm", text: "1d"
  end

  test "period 7d is accepted and active" do
    sign_in @admin
    get admin_dashboard_path(period: "7d")
    assert_response :success
    assert_select "a.bg-white.shadow-sm", text: "7d"
  end

  test "period 1m is accepted and active" do
    sign_in @admin
    get admin_dashboard_path(period: "1m")
    assert_response :success
    assert_select "a.bg-white.shadow-sm", text: "1m"
  end

  test "period all is accepted and active" do
    sign_in @admin
    get admin_dashboard_path(period: "all")
    assert_response :success
    assert_select "a.bg-white.shadow-sm", text: "All"
  end

  test "invalid period parameter falls back to 7d" do
    sign_in @admin
    get admin_dashboard_path(period: "invalid")
    assert_response :success
    assert_select "a.bg-white.shadow-sm", text: "7d"
  end

  test "empty period parameter falls back to 7d" do
    sign_in @admin
    get admin_dashboard_path(period: "")
    assert_response :success
    assert_select "a.bg-white.shadow-sm", text: "7d"
  end

  # Stat card content

  test "response contains unconfirmed users stat card" do
    sign_in @admin
    get admin_dashboard_path
    assert_response :success
    assert_match "Unconfirmed users", response.body
  end

  test "response contains confirmed users stat card" do
    sign_in @admin
    get admin_dashboard_path
    assert_response :success
    assert_match "Confirmed users", response.body
  end

  test "all period shows correct total counts" do
    sign_in @admin
    get admin_dashboard_path(period: "all")
    assert_response :success

    unconfirmed_count = User.where(confirmed_at: nil).count
    confirmed_count = User.where.not(confirmed_at: nil).count

    assert_select "turbo-frame#dashboard_stats" do
      assert_select "p", text: unconfirmed_count.to_s
      assert_select "p", text: confirmed_count.to_s
    end
  end

  test "all period does not show vs previous period indicators" do
    sign_in @admin
    get admin_dashboard_path(period: "all")
    assert_response :success
    assert_no_match "vs previous period", response.body
  end

  test "time-bounded period shows vs previous period when previous period has data" do
    # Create a user in the previous 7d period (8 days ago) so percentage_change is non-nil
    User.create!(name: "Old User", email: "old@example.com",
                 password: "password123", confirmed_at: Time.current,
                 created_at: 8.days.ago, updated_at: 8.days.ago)

    sign_in @admin
    get admin_dashboard_path(period: "7d")
    assert_response :success
    assert_match "vs previous period", response.body
  end

  test "time-bounded period hides vs previous period when previous period is empty" do
    sign_in @admin
    get admin_dashboard_path(period: "7d")
    assert_response :success
    assert_no_match "vs previous period", response.body
  end

  # Period picker rendering

  test "period picker renders all five period options" do
    sign_in @admin
    get admin_dashboard_path
    assert_response :success
    assert_select "a[href*='period=1h']"
    assert_select "a[href*='period=1d']"
    assert_select "a[href*='period=7d']"
    assert_select "a[href*='period=1m']"
    assert_select "a[href*='period=all']"
  end

  test "period picker links target dashboard_stats turbo frame" do
    sign_in @admin
    get admin_dashboard_path
    assert_response :success
    assert_select "a[data-turbo-frame='dashboard_stats']", count: 5
  end

  # Turbo Frame requests

  test "turbo frame request returns dashboard stats frame" do
    sign_in @admin
    get admin_dashboard_path(period: "7d"), headers: { "Turbo-Frame" => "dashboard_stats" }
    assert_response :success
    assert_select "turbo-frame#dashboard_stats"
  end

  test "turbo frame request with different periods returns success" do
    sign_in @admin

    %w[1h 1d 7d 1m all].each do |period|
      get admin_dashboard_path(period: period), headers: { "Turbo-Frame" => "dashboard_stats" }
      assert_response :success, "Expected success for period #{period}"
    end
  end

  # Dashboard stats turbo frame

  test "dashboard stats are wrapped in a turbo frame" do
    sign_in @admin
    get admin_dashboard_path
    assert_response :success
    assert_select "turbo-frame#dashboard_stats"
  end

  # Greeting

  test "dashboard displays admin greeting" do
    sign_in @admin
    get admin_dashboard_path
    assert_response :success
    assert_select "h1", text: /Hello, #{@admin.name}!/
  end

  # Sidebar

  test "sidebar shows Dashboard link" do
    sign_in @admin
    get admin_dashboard_path
    assert_response :success
    assert_select "nav a", text: "Dashboard"
  end

  test "sidebar shows Users link" do
    sign_in @admin
    get admin_dashboard_path
    assert_response :success
    assert_select "nav a", text: "Users"
  end
end
