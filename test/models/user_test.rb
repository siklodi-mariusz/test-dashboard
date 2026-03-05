require "test_helper"

class UserTest < ActiveSupport::TestCase
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
end
