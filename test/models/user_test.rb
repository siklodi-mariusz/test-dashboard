require "test_helper"

class UserTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  # Name validations

  test "valid user passes validation" do
    user = User.new(name: "Jane Doe", email: "newuser@example.com", password: "password123", password_confirmation: "password123")
    assert user.valid?
  end

  test "name must be present" do
    [ "", nil ].each do |blank_name|
      user = User.new(name: blank_name, email: "test@example.com", password: "password123")
      assert_not user.valid?
      assert_includes user.errors[:name], "can't be blank"
    end
  end

  test "name cannot exceed 100 characters" do
    user = User.new(name: "a" * 101, email: "test@example.com", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:name], "is too long (maximum is 100 characters)"
  end

  test "name with exactly 100 characters is valid" do
    user = User.new(name: "a" * 100, email: "newuser2@example.com", password: "password123")
    assert user.valid?
  end

  test "name with leading and trailing spaces is valid" do
    user = User.new(name: "  Jane  ", email: "newuser3@example.com", password: "password123")
    assert user.valid?
  end

  # Email validations

  test "valid email" do
    user = User.new(name: "Test", email: "user@example.com", password: "password123")
    assert user.valid?
  end

  test "email cannot be blank" do
    user = User.new(name: "Test", email: "", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "email must be unique (case-insensitive)" do
    user = User.new(name: "Test", email: users(:confirmed_user).email.upcase, password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "invalid email formats are rejected" do
    %w[not-an-email user@].each do |bad_email|
      user = User.new(name: "Test", email: bad_email, password: "password123")
      assert_not user.valid?
      assert_includes user.errors[:email], "is invalid"
    end
  end

  # Password validations

  test "password minimum 6 characters" do
    user = User.new(name: "Test", email: "test@example.com", password: "12345")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 6 characters)"
  end

  test "password with exactly 6 characters is valid" do
    user = User.new(name: "Test", email: "newuser4@example.com", password: "123456")
    assert user.valid?
  end

  test "password cannot be blank" do
    user = User.new(name: "Test", email: "test@example.com", password: "")
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  # Role enum

  test "user? returns true for user role" do
    user = users(:confirmed_user)
    assert user.user?
    assert_not user.admin?
  end

  test "admin? returns true for admin role" do
    admin = users(:admin_user)
    assert admin.admin?
    assert_not admin.user?
  end

  test "default role is user" do
    user = User.new(name: "Test", email: "default@example.com", password: "password123")
    assert_equal "user", user.role
    assert user.user?
  end

  # Admin broadcast on create

  test "broadcasts to admin_notifications exactly twice on create" do
    assert_broadcasts("admin_notifications", 2) do
      User.create!(name: "Broadcast Test", email: "broadcast@example.com", password: "password123")
    end
  end

  test "broadcast appends toast with user name and email" do
    assert_broadcasts("admin_notifications", 2) do
      User.create!(name: "Toast User", email: "toast@example.com", password: "password123")
    end

    messages = broadcasts("admin_notifications").map { |m| ActiveSupport::JSON.decode(m) }
    toast = messages.find { |m| m.include?("admin_toast_container") }
    assert toast, "Expected a broadcast targeting admin_toast_container"
    assert_includes toast, "Toast User"
    assert_includes toast, "toast@example.com"
    assert_includes toast, 'action="append"'
  end

  test "broadcast prepends table row with user details" do
    assert_broadcasts("admin_notifications", 2) do
      User.create!(name: "Row User", email: "row@example.com", password: "password123")
    end

    messages = broadcasts("admin_notifications").map { |m| ActiveSupport::JSON.decode(m) }
    row = messages.find { |m| m.include?("admin_users_table_body") }
    assert row, "Expected a broadcast targeting admin_users_table_body"
    assert_includes row, "Row User"
    assert_includes row, "row@example.com"
    assert_includes row, 'action="prepend"'
  end

  test "creating multiple users sends exactly 2 broadcasts each" do
    assert_broadcasts("admin_notifications", 4) do
      User.create!(name: "First", email: "first@example.com", password: "password123")
      User.create!(name: "Second", email: "second@example.com", password: "password123")
    end
  end

  # Last admin protection

  test "last admin cannot be demoted to user" do
    admin = users(:admin_user)
    assert_equal 1, User.where(role: :admin).count, "Precondition: only one admin exists"

    admin.role = :user
    assert_not admin.valid?
    assert_includes admin.errors[:role], "cannot be changed. At least one admin must exist."
  end

  test "admin can be demoted when another admin exists" do
    admin = users(:admin_user)
    other_user = users(:confirmed_user)
    other_user.update_columns(role: 1)

    assert_operator User.where(role: :admin).count, :>=, 2, "Precondition: at least two admins exist"

    admin.role = :user
    assert admin.valid?, "Admin should be demotable when another admin exists"
  end
end
