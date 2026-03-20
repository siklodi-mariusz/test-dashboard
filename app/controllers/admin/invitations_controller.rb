class Admin::InvitationsController < Admin::BaseController
  before_action :set_invitation, only: [ :edit, :update ]

  def new
    @invitation = Invitation.new
    render_modal
  end

  def create
    @invitation = Invitation.new(invitation_params)
    @invitation.invited_by = current_user

    if @invitation.save
      InvitationMailer.invite(@invitation).deliver_later
      redirect_to admin_users_path, notice: "Invitation sent to #{@invitation.email}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    render_modal
  end

  def update
    if @invitation.update(invitation_params)
      redirect_to admin_users_path, notice: "Invitation updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def render_modal
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("modal", partial: "admin/invitations/modal", locals: { invitation: @invitation })
      end
      format.html
    end
  end

  def set_invitation
    @invitation = Invitation.find(params[:id])
  end

  def invitation_params
    params.expect(invitation: [ :email, :role ])
  end
end
