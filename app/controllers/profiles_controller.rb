class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: :show
  before_action :authorize_profile_view!, only: :show

  def show
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      redirect_to profile_path(@user), notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def authorize_profile_view!
    # Standard users cannot see admin profiles
    if current_user.user? && @user.admin?
      redirect_to dashboard_path, alert: "You are not authorized to view this profile."
    end
  end

  def profile_params
    params.require(:user).permit(:name, :nickname, :email, :avatar)
  end
end
