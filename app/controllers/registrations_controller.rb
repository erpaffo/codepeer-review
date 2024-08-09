class RegistrationsController < Devise::RegistrationsController
  def create
    super do |resource|
      if resource.persisted? && resource.email.present?
        puts "User created with email: #{resource.email}"
      else
        flash[:alert] = "There was an issue creating your account."
        redirect_to new_user_registration_path
      end
    end
  end

  protected

  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :phone_number)
  end

  def account_update_params
    params.require(:user).permit(:email, :password, :password_confirmation, :current_password, :phone_number)
  end
end
