require "application_system_test_case"

class ProfilesTest < ApplicationSystemTestCase
  setup do
    @user = users(:confirmed_user)
    @other_user = users(:second_confirmed_user)
    @admin = users(:admin_user)
    @second_admin = users(:second_admin_user)
  end

  # 1. Viewing own profile

  test "user sees their name, nickname, and edit link on own profile" do
    sign_in_as(@user)
    visit profile_path(@user)

    assert_text @user.name
    assert_text @user.nickname
    assert_link "Edit"
  end

  # 2. Viewing another standard user's profile

  test "standard user can view another standard user's profile without edit link" do
    sign_in_as(@user)
    visit profile_path(@other_user)

    assert_text @other_user.name
    assert_text @other_user.nickname
    assert_no_link "Edit"
  end

  # 3. Standard user blocked from viewing admin profile

  test "standard user is redirected when trying to view admin profile" do
    sign_in_as(@user)
    visit profile_path(@admin)

    assert_text "You are not authorized to view this profile."
    assert_text "Welcome, #{@user.name}!"
  end

  # 4. Admin viewing standard user's profile

  test "admin can view a standard user's profile" do
    sign_in_as(@admin)
    visit profile_path(@user)

    assert_text @user.name
    assert_text @user.nickname
  end

  # 5. Admin viewing another admin's profile

  test "admin can view another admin's profile" do
    sign_in_as(@admin)
    visit profile_path(@second_admin)

    assert_text @second_admin.name
    assert_text @second_admin.nickname
  end

  # 6. Editing own profile successfully

  test "user can edit their name and nickname" do
    sign_in_as(@user)
    visit edit_profile_path(@user)

    fill_in "Name", with: "Jane Updated"
    fill_in "Nickname", with: "janeupdated"
    click_on "Save profile"

    assert_text "Profile updated successfully."
    assert_text "Jane Updated"
    assert_text "janeupdated"
  end

  # 7. Editing profile with validation error

  test "editing profile with blank name shows validation errors" do
    sign_in_as(@user)
    visit edit_profile_path(@user)

    fill_in "Name", with: ""
    click_on "Save profile"

    assert_text "can't be blank"
  end

  test "editing profile with nickname exceeding 50 characters shows validation errors" do
    sign_in_as(@user)
    visit edit_profile_path(@user)

    fill_in "Nickname", with: "a" * 51
    click_on "Save profile"

    assert_text "too long"
  end

  # 8. "Back to profile" link works on edit page

  test "back to profile link on edit page navigates to show page" do
    sign_in_as(@user)
    visit edit_profile_path(@user)

    assert_link "Back to profile"
    click_on "Back to profile"

    assert_text @user.name
    assert_text @user.nickname
    assert_link "Edit"
  end

  # 9. "Edit" link from show page navigates to edit form

  test "edit link on show page navigates to edit form" do
    sign_in_as(@user)
    visit profile_path(@user)

    click_on "Edit"

    assert_text "Edit user"
    assert_field "Name", with: @user.name
    assert_field "Nickname", with: @user.nickname
    assert_field "Email", with: @user.email
    assert_button "Save profile"
  end

  # 10. Upload avatar

  test "user can upload an avatar image" do
    sign_in_as(@user)
    visit edit_profile_path(@user)

    attach_file file_fixture("avatar.png"), make_visible: true
    click_on "Save profile"

    assert_text "Profile updated successfully."
    assert_selector "img[src*='avatar']"
  end
end
