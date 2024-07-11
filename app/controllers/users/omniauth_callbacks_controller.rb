class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [:github, :google_oauth2, :gitlab]
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
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
    else
      session["devise.#{kind.downcase}_data"] = request.env['omniauth.auth']
      redirect_to new_user_registration_url
    end
  end

  def after_sign_in_path_for(resource)
    authenticated_root_path
  end

  def failure
    redirect_to unauthenticated_root_path, alert: "Authentication failed, please try again."
  end
end
