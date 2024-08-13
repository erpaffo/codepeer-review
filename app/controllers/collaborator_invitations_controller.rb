class CollaboratorInvitationsController < ApplicationController
  def accept
    @invitation = CollaboratorInvitation.find_by(token: params[:token])

    if @invitation && !@invitation.accepted?
      @invitation.update(user: current_user, accepted: true)

      unless Collaborator.exists?(user: current_user, project: @invitation.project)
        Collaborator.create(user: current_user, project: @invitation.project)
      end

      redirect_to @invitation.project, notice: 'Invitation accepted. You are now a collaborator.'
    else
      redirect_to root_path, alert: 'Invalid or expired invitation token.'
    end
  end
end
