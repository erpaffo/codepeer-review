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
    patch 'update_profile', to: 'users#update_profile', as: :update_profile

    get 'profile', to: 'users#show', as: :profile
    get 'profile/edit', to: 'users#edit', as: :edit_profile
    patch 'profile', to: 'users#update'

    resources :community_activity, only: [:index, :show] do
      member do
        get 'feedback'
        post 'create_feedback'
      end
    end

    # Password Change Routes
    get 'password/edit', to: 'passwords#edit', as: :edit_password
    patch 'password', to: 'passwords#update', as: :password

    # Settings
    get 'settings', to: 'users#settings', as: :settings

    # Two-Factor Authentication Routes
    scope 'two_factor_auth', controller: 'two_factor_auth' do
      get 'setup', as: :setup_two_factor_auth
      post 'choose', as: :choose_two_factor_auth
      get 'sms', as: :sms_two_factor_auth
      get 'email', as: :email_two_factor_auth
      get 'qr_code', as: :qr_code_two_factor_auth
      get 'verify_otp', as: :verify_otp_two_factor_auth
      post 'verify', as: :verify_two_factor_auth
      post 'send_backup_email', as: :send_backup_email_two_factor_auth
      get 'new_phone_number', as: :new_phone_number
      patch 'save_phone_number', as: :save_phone_number
    end

    patch 'enable_two_factor_auth', to: 'users#enable_two_factor_auth', as: :enable_two_factor_auth
    patch 'disable_two_factor_auth', to: 'users#disable_two_factor_auth', as: :disable_two_factor_auth

    # Project Routes
    resources :projects do
      member do
        get 'show_file/:file_id', to: 'projects#show_file', as: 'show_file'
        get 'edit_file/:file_id', to: 'projects#edit_file', as: 'edit_file'
        patch 'update_file/:file_id', to: 'projects#update_file', as: 'update_file'
        get 'new_file', to: 'projects#new_file', as: 'new_file'
        post 'create_file', to: 'projects#create_file', as: 'create_file'
      end
    end

    post 'run_code', to: 'projects#run_code'

    resources :snippets do
      member do
        get 'share', to: 'shares#new', as: :new_share
        post 'share', to: 'shares#create'
        post 'toggle_favorite'
        get 'feedback'
        post 'create_feedback'
        delete 'feedback/:feedback_id', to: 'community_activity#destroy_feedback', as: 'destroy_feedback'
      end
    end

    resources :users, only: [:show] do
      member do
        get 'leave_feedback'
        post 'create_feedback'
      end
    end

    resources :snippets, only: [:index, :show, :new, :create, :edit, :update, :destroy]

    # User's Snippets Routes
    get 'my_snippets', to: 'users#my_snippets', as: :my_snippets
    get 'favorite_snippets', to: 'users#favorite_snippets', as: :favorite_snippets

    # Logout Route
    delete 'logout', to: 'devise/sessions#destroy', as: :logout
  end

  unauthenticated do
    root 'welcome#index', as: :unauthenticated_root
  end
end
