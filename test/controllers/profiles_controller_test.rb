require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:confirmed_user)
    @second_user = users(:second_confirmed_user)
    @admin = users(:admin_user)
  end

  # Authentication

  test "unauthenticated user is redirected to sign-in for show" do
    get profile_path(@user)
    assert_redirected_to new_user_session_path
  end

  test "unauthenticated user is redirected to sign-in for edit" do
    get edit_profile_path(@user)
    assert_redirected_to new_user_session_path
  end

  test "unauthenticated user is redirected to sign-in for update" do
    patch profile_path(@user), params: { user: { name: "Hacked" } }
    assert_redirected_to new_user_session_path
    assert_equal "Jane Doe", @user.reload.name
  end

  # Show

  test "authenticated user can view own profile" do
    sign_in @user
    get profile_path(@user)
    assert_response :success
  end

  test "authenticated user can view another standard user's profile" do
    sign_in @user
    get profile_path(@second_user)
    assert_response :success
  end

  test "standard user cannot view admin profile" do
    sign_in @user
    get profile_path(@admin)
    assert_redirected_to dashboard_path
    assert_equal "You are not authorized to view this profile.", flash[:alert]
  end

  test "admin can view standard user's profile" do
    sign_in @admin
    get profile_path(@user)
    assert_response :success
  end

  test "admin can view own profile" do
    sign_in @admin
    get profile_path(@admin)
    assert_response :success
  end

  # Edit

  test "authenticated user can access edit form for own profile" do
    sign_in @user
    get edit_profile_path(@user)
    assert_response :success
  end

  # Update

  test "authenticated user can update their name" do
    sign_in @user
    patch profile_path(@user), params: { user: { name: "Updated Jane" } }
    assert_redirected_to profile_path(@user)
    assert_equal "Updated Jane", @user.reload.name
    assert_equal "Profile updated successfully.", flash[:notice]
  end

  test "authenticated user can update their nickname" do
    sign_in @user
    patch profile_path(@user), params: { user: { nickname: "newjane" } }
    assert_redirected_to profile_path(@user)
    assert_equal "newjane", @user.reload.nickname
  end

  test "authenticated user can update their email" do
    sign_in @user
    patch profile_path(@user), params: { user: { email: "newemail@example.com" } }
    assert_redirected_to profile_path(@user)
  end

  test "update with invalid data renders edit with unprocessable_entity" do
    sign_in @user
    patch profile_path(@user), params: { user: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "update with nickname exceeding 50 characters renders edit with unprocessable_entity" do
    sign_in @user
    patch profile_path(@user), params: { user: { nickname: "a" * 51 } }
    assert_response :unprocessable_entity
  end
end
