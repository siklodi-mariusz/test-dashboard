require "application_system_test_case"

class AdminTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin_user)
    @regular_user = users(:confirmed_user)
    @unconfirmed_user = users(:unconfirmed_user)
  end

  test "admin signs in and sees admin panel" do
    sign_in_as(@admin)

    assert_text "Admin Panel"
    assert_text @admin.name
    assert_text "Users"
  end

  test "admin can view users list" do
    sign_in_as(@admin)
    click_on "Users"

    assert_text @regular_user.name
    assert_text @regular_user.email
    assert_text @admin.name
    assert_text @admin.email
  end

  test "admin can view user details" do
    sign_in_as(@admin)
    click_on "Users"

    click_on @regular_user.name
    assert_text @regular_user.name
    assert_text @regular_user.email
    assert_text "user"
  end

  test "admin can edit a user" do
    sign_in_as(@admin)
    click_on "Users"

    click_on @regular_user.name
    click_on "Edit"

    fill_in "Name", with: "Updated Name"
    click_on "Update user"

    assert_text "User was successfully updated."
    assert_text "Updated Name"
  end

  test "admin can change user role" do
    sign_in_as(@admin)
    click_on "Users"

    click_on @regular_user.name
    click_on "Edit"

    select "admin", from: "Role"
    click_on "Update user"

    assert_text "User was successfully updated."
    assert_text "admin"
  end

  test "admin can delete a user with confirmation" do
    sign_in_as(@admin)
    click_on "Users"

    click_on @unconfirmed_user.name

    accept_confirm "Are you sure you want to delete this user?" do
      click_on "Delete"
    end

    assert_text "User was successfully deleted."
    assert_no_text @unconfirmed_user.name
  end

  test "admin cannot delete themselves" do
    sign_in_as(@admin)
    click_on "Users"

    click_on @admin.name

    # The delete button should not be visible for the current user
    assert_no_button "Delete"
    assert_no_selector "input[value='Delete']"
  end

  test "admin cannot delete themselves from index" do
    sign_in_as(@admin)
    click_on "Users"

    within("#admin_users_table_body") do
      # On the index page, the Delete button is not rendered for the current user
      within("tr", text: @admin.name) do
        assert_no_button "Delete"
      end

      # But other users have a Delete button
      within("tr", text: @regular_user.name) do
        assert_selector "button", text: "Delete"
      end
    end
  end

  test "regular user cannot access admin panel" do
    visit new_user_session_path
    assert_text "Sign in to your account"
    fill_in "Email", with: @regular_user.email
    fill_in "Password", with: "password123"
    click_on "Sign in"

    visit admin_root_path

    assert_text "Welcome, #{@regular_user.name}!"
    assert_text "You are not authorized to access this page."
    assert_no_text "Admin Panel"
  end

  test "admin sign-in redirects to admin panel" do
    visit new_user_session_path
    assert_text "Sign in to your account"
    fill_in "Email", with: @admin.email
    fill_in "Password", with: "password123"
    click_on "Sign in"

    assert_text "Admin Panel"
    assert_text "Users"
  end

  test "admin can navigate back to dashboard" do
    sign_in_as(@admin)

    click_on "Back to Dashboard"
    assert_text "Welcome, #{@admin.name}!"
  end

  test "edit form shows validation errors on invalid input" do
    sign_in_as(@admin)
    click_on "Users"

    click_on @regular_user.name
    click_on "Edit"

    fill_in "Name", with: ""
    click_on "Update user"

    assert_text "can't be blank"
  end

  test "last admin demotion is prevented via edit form" do
    sign_in_as(@admin)
    User.where(role: :admin).where.not(id: @admin.id).update_all(role: :user)
    assert_equal 1, User.where(role: :admin).count
    click_on "Users"

    click_on @admin.name
    click_on "Edit"

    select "user", from: "Role"
    click_on "Update user"

    assert_text "cannot be changed"
  end

  private

end
