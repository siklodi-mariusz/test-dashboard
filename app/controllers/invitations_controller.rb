class InvitationsController < ApplicationController
  before_action :set_invitation

  def show
    if @invitation.nil? || @invitation.accepted?
      render :invalid
    elsif @invitation.expired?
      render :expired
    else
      @user = User.new(email: @invitation.email)
    end
  end

  def update
    if @invitation.nil? || @invitation.accepted?
      render :invalid and return
    elsif @invitation.expired?
      render :expired and return
    end

    @user = User.new(user_params)
    @user.email = @invitation.email
    @user.role = @invitation.role
    @user.confirmed_at = Time.current

    if @user.save
      @invitation.update!(accepted_at: Time.current)
      sign_in(@user)
      redirect_to after_sign_in_path_for(@user)
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_invitation
    @invitation = Invitation.find_by(token: params[:token])
  end

  def user_params
    params.expect(user: [:name, :password, :password_confirmation])
  end
end
