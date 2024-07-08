class UserMailer < ApplicationMailer
  def two_factor_auth_code(user)
    @user = user
    mail(to: @user.email, subject: 'Your Two-Factor Authentication Code')
  end
end
