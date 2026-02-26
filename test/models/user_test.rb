require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Name validations

  test "valid user passes validation" do
    user = User.new(name: "Jane Doe", email: "newuser@example.com", password: "password123", password_confirmation: "password123")
    assert user.valid?
  end

  test "name cannot be blank" do
    user = User.new(name: "", email: "test@example.com", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "name cannot be nil" do
    user = User.new(name: nil, email: "test@example.com", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "name cannot exceed 100 characters" do
    user = User.new(name: "a" * 101, email: "test@example.com", password: "password123")
    assert_not user.valid?
    assert user.errors[:name].any?
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
    assert user.errors[:email].any?
  end

  test "email must be unique" do
    user = User.new(name: "Test", email: users(:confirmed_user).email, password: "password123")
    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test "email uniqueness is case-insensitive" do
    user = User.new(name: "Test", email: "JANE@EXAMPLE.COM", password: "password123")
    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test "invalid email format" do
    user = User.new(name: "Test", email: "not-an-email", password: "password123")
    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test "email without domain" do
    user = User.new(name: "Test", email: "user@", password: "password123")
    assert_not user.valid?
    assert user.errors[:email].any?
  end

  # Password validations

  test "password minimum 6 characters" do
    user = User.new(name: "Test", email: "test@example.com", password: "12345")
    assert_not user.valid?
    assert user.errors[:password].any?
  end

  test "password with exactly 6 characters is valid" do
    user = User.new(name: "Test", email: "newuser4@example.com", password: "123456")
    assert user.valid?
  end

  test "password cannot be blank" do
    user = User.new(name: "Test", email: "test@example.com", password: "")
    assert_not user.valid?
    assert user.errors[:password].any?
  end
end
