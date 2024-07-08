Rails.application.routes.draw do

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'registrations'
  }

  devise_scope :user do
    get 'users/auth/failure', to: 'users/omniauth_callbacks#failure'
  end

  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
    get 'complete_profile', to: 'users#complete_profile', as: :complete_profile
    patch 'update_profile', to: 'users#update_profile'
    get 'profile', to: 'users#show', as: :profile
    get 'profile/edit', to: 'users#edit', as: :edit_profile
    patch 'profile', to: 'users#update'

    # Password Change Routes
    get 'password/edit', to: 'passwords#edit', as: :edit_password
    patch 'password', to: 'passwords#update', as: :password

    # 2FA Routes
    get 'two_factor_auth/setup', to: 'two_factor_auth#setup', as: :setup_two_factor_auth
    post 'two_factor_auth/choose', to: 'two_factor_auth#choose', as: :choose_two_factor_auth
    get 'two_factor_auth/sms', to: 'two_factor_auth#sms', as: :sms_two_factor_auth
    get 'two_factor_auth/email', to: 'two_factor_auth#email', as: :email_two_factor_auth
    get 'two_factor_auth/qr_code', to: 'two_factor_auth#qr_code', as: :qr_code_two_factor_auth
    get 'two_factor_auth/verify_otp', to: 'two_factor_auth#verify_otp', as: :verify_otp_two_factor_auth
    post 'two_factor_auth/verify', to: 'two_factor_auth#verify', as: :verify_two_factor_auth
    post 'two_factor_auth/send_backup_email', to: 'two_factor_auth#send_backup_email', as: :send_backup_email_two_factor_auth
    get 'two_factor_auth/new_phone_number', to: 'two_factor_auth#new_phone_number', as: :new_phone_number
    patch 'two_factor_auth/save_phone_number', to: 'two_factor_auth#save_phone_number', as: :save_phone_number

    patch 'enable_two_factor_auth', to: 'users#enable_two_factor_auth', as: :enable_two_factor_auth
    patch 'disable_two_factor_auth', to: 'users#disable_two_factor_auth', as: :disable_two_factor_auth

    # Project Routes
    resources :projects do
      member do
        get 'show_file/:file_id', to: 'projects#show_file', as: 'show_file'
        get 'edit_file/:file_id', to: 'projects#edit_file', as: 'edit_file'
        patch 'update_file/:file_id', to: 'projects#update_file', as: 'update_file'
      end
    end
  end

  unauthenticated do
    root 'welcome#index', as: :unauthenticated_root
  end
end
