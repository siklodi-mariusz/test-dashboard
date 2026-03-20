require "test_helper"

class InvitationMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: "example.com" }
  end

  setup do
    @invitation = invitations(:pending_invitation)
    @mail = InvitationMailer.invite(@invitation)
  end

  test "invite email headers are correct" do
    assert_equal [ @invitation.email ], @mail.to
    assert_equal [ "noreply@testdashboard.com" ], @mail.from
    assert_equal "You've been invited to Test Dashboard", @mail.subject
    assert_not_nil @mail.html_part
    assert_not_nil @mail.text_part
    assert_equal "text/html; charset=UTF-8", @mail.html_part.content_type
    assert_equal "text/plain; charset=UTF-8", @mail.text_part.content_type
  end

  test "invite email body contains inviter name, invitation URL, and 72-hour expiry" do
    html_body = @mail.html_part.body.decoded
    text_body = @mail.text_part.body.decoded
    expected_url = invitation_url(@invitation.token)

    [ html_body, text_body ].each do |body|
      assert_match @invitation.invited_by.name, body
      assert_match expected_url, body
      assert_match "72 hours", body
    end
  end
end
