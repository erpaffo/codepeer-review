class CollaboratorMailer < ApplicationMailer
  def invite_email(invitation)
    @project = invitation.project
    @user = invitation.user
    @invitation = invitation

    if @user.nil?
      Rails.logger.error "CollaboratorMailer#invite_email: User is nil for project #{@project.id}"
      return
    end

    mail(to: @user.email, subject: "You've been invited to collaborate on #{@project.title}")
  end
end
