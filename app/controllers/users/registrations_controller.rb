class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super do |user|
      link_pending_invitation(user) if user.persisted?
    end
  end

  private

  def link_pending_invitation(user)
    invitation = Invitation.where(email: user.email, accepted_at: nil).first
    return unless invitation

    invitation.update!(accepted_at: Time.current)
    user.update!(role: invitation.role)
  end

  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def account_update_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :current_password)
  end
end
