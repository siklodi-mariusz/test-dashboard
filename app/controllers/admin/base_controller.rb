class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  layout "admin"

  private

  def require_admin!
    unless current_user.admin?
      redirect_to dashboard_path, alert: "You are not authorized to access this page."
    end
  end
end
