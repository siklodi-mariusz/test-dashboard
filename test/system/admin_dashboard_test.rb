require "application_system_test_case"

class AdminDashboardTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin_user)
    @regular_user = users(:confirmed_user)
    @unconfirmed_user = users(:unconfirmed_user)
  end

  test "admin sees greeting with their name on dashboard" do
    sign_in_as(@admin)
    visit admin_dashboard_path

    assert_text "Hello, #{@admin.name}!"
    assert_text "Here's an overview of everything you need to be aware of."
  end

  test "admin sees unconfirmed users stat card" do
    sign_in_as(@admin)
    visit admin_dashboard_path

    assert_text "Unconfirmed users"
  end

  test "admin sees confirmed users stat card" do
    sign_in_as(@admin)
    visit admin_dashboard_path

    assert_text "Confirmed users"
  end

  test "period picker is visible with all options" do
    sign_in_as(@admin)
    visit admin_dashboard_path

    assert_text "1h"
    assert_text "1d"
    assert_text "7d"
    assert_text "1m"
    assert_text "All"
  end

  test "default period 7d is active" do
    sign_in_as(@admin)
    visit admin_dashboard_path

    assert_selector "a.bg-white.shadow-sm", text: "7d"
  end

  test "clicking All period tab updates stat cards via turbo frame" do
    sign_in_as(@admin)
    visit admin_dashboard_path

    unconfirmed_count = User.where(confirmed_at: nil).count
    confirmed_count = User.where.not(confirmed_at: nil).count

    click_on "All"

    within "turbo-frame#dashboard_stats" do
      assert_text "Unconfirmed users"
      assert_text "Confirmed users"
      assert_text unconfirmed_count.to_s
      assert_text confirmed_count.to_s
    end
  end

  test "clicking a different period tab refreshes stat card content" do
    sign_in_as(@admin)
    visit admin_dashboard_path

    click_on "1d"

    within "turbo-frame#dashboard_stats" do
      assert_text "Unconfirmed users"
      assert_text "Confirmed users"
    end
  end

  test "period picker links are clickable" do
    sign_in_as(@admin)
    visit admin_dashboard_path

    %w[1h 1d 1m].each do |period|
      click_on period
      within "turbo-frame#dashboard_stats" do
        assert_text "Unconfirmed users"
      end
    end
  end

  test "sidebar has Dashboard link with active state on dashboard page" do
    sign_in_as(@admin)
    visit admin_dashboard_path

    within "nav" do
      assert_selector "a.text-indigo-600", text: "Dashboard"
    end
  end

  test "sidebar Users link is not active when on dashboard" do
    sign_in_as(@admin)
    visit admin_dashboard_path

    within "nav" do
      assert_selector "a.text-gray-700", text: "Users"
      assert_no_selector "a.text-indigo-600", text: "Users"
    end
  end

  test "admin root path shows the dashboard" do
    sign_in_as(@admin)
    visit admin_root_path

    assert_text "Hello, #{@admin.name}!"
    assert_text "Unconfirmed users"
    assert_text "Confirmed users"
  end

  test "all period shows correct total counts" do
    sign_in_as(@admin)
    visit admin_dashboard_path

    click_on "All"

    unconfirmed_count = User.where(confirmed_at: nil).count
    confirmed_count = User.where.not(confirmed_at: nil).count

    assert_text unconfirmed_count.to_s
    assert_text confirmed_count.to_s
  end
end
