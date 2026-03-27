require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  # Validations

  test "valid invitation passes validation" do
    invitation = Invitation.new(email: "new@example.com", invited_by: users(:admin_user))
    assert invitation.valid?
  end

  test "email must be present" do
    invitation = Invitation.new(email: "", invited_by: users(:admin_user))
    assert_not invitation.valid?
    assert_includes invitation.errors[:email], "can't be blank"
  end

  test "email must have valid format" do
    %w[not-an-email user@].each do |bad_email|
      invitation = Invitation.new(email: bad_email, invited_by: users(:admin_user))
      assert_not invitation.valid?
      assert_includes invitation.errors[:email], "is invalid"
    end
  end

  test "email must be unique" do
    invitation = Invitation.new(email: invitations(:pending_invitation).email, invited_by: users(:admin_user))
    assert_not invitation.valid?
    assert_includes invitation.errors[:email], "has already been taken"
  end

  test "email cannot belong to an existing user" do
    invitation = Invitation.new(email: users(:confirmed_user).email, invited_by: users(:admin_user))
    assert_not invitation.valid?
    assert_includes invitation.errors[:email], "is already registered"
  end

  # Callbacks

  test "token is generated before create" do
    invitation = Invitation.create!(email: "token@example.com", invited_by: users(:admin_user))
    assert_not_nil invitation.token
    assert_equal 43, invitation.token.length # urlsafe_base64(32) produces 43 chars
  end

  test "expires_at is set to 72 hours from now before create" do
    freeze_time do
      invitation = Invitation.create!(email: "expiry@example.com", invited_by: users(:admin_user))
      assert_equal 72.hours.from_now, invitation.expires_at
    end
  end

  # Role enum

  test "default role is user" do
    invitation = Invitation.new(email: "role@example.com", invited_by: users(:admin_user))
    assert_equal "user", invitation.role
    assert invitation.user?
  end

  test "admin role can be set" do
    invitation = invitations(:admin_invitation)
    assert invitation.admin?
    assert_not invitation.user?
  end

  # Scopes

  test "unaccepted scope returns invitations without accepted_at" do
    results = Invitation.unaccepted
    assert_includes results, invitations(:pending_invitation)
    assert_includes results, invitations(:expired_invitation)
    assert_not_includes results, invitations(:accepted_invitation)
  end

  test "pending scope returns unaccepted invitations that have not expired" do
    results = Invitation.pending
    assert_includes results, invitations(:pending_invitation)
    assert_not_includes results, invitations(:expired_invitation)
    assert_not_includes results, invitations(:accepted_invitation)
  end

  test "expired scope returns unaccepted invitations past expiry" do
    results = Invitation.expired
    assert_includes results, invitations(:expired_invitation)
    assert_not_includes results, invitations(:pending_invitation)
    assert_not_includes results, invitations(:accepted_invitation)
  end

  # Instance methods

  test "pending? returns true for unaccepted unexpired invitation" do
    assert invitations(:pending_invitation).pending?
  end

  test "pending? returns false for expired invitation" do
    assert_not invitations(:expired_invitation).pending?
  end

  test "expired? returns true for unaccepted past-expiry invitation" do
    assert invitations(:expired_invitation).expired?
  end

  test "expired? returns false for pending invitation" do
    assert_not invitations(:pending_invitation).expired?
  end

  test "accepted? returns true when accepted_at is set" do
    assert invitations(:accepted_invitation).accepted?
  end

  test "accepted? returns false when accepted_at is nil" do
    assert_not invitations(:pending_invitation).accepted?
  end
end
