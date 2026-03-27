class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    mail(to: invitation.email, subject: "You've been invited to Test Dashboard")
  end
end
