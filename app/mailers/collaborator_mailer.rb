class CollaboratorMailer < ApplicationMailer
  def invite_email(invitation)
    @invitation = invitation
    @project = @invitation.project
    @user = @invitation.user

    mail(to: @invitation.email, subject: "You've been invited to collaborate on #{@project.title}")
  end
end
