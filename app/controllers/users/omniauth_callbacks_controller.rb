class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    handle_auth "Google"
  end

  def github
    handle_auth "GitHub"
  end

  def gitlab
    handle_auth "GitLab"
  end

  def handle_auth(kind)
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      if @user.first_name.blank? || @user.last_name.blank? || @user.nickname.blank?
        session['devise.auth_data'] = request.env['omniauth.auth']
        redirect_to complete_profile_path
      else
        flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: kind
        sign_in_and_redirect @user, event: :authentication
      end
    else
      session['devise.auth_data'] = request.env['omniauth.auth']
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end
end
