Rails.application.routes.draw do
  get 'badges/index'
  get 'notifications/index'
  unauthenticated do
    root 'welcome#index', as: :unauthenticated_root
  end

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'registrations',
    sessions: 'sessions'
  }

  devise_scope :user do
    get 'users/auth/failure', to: 'users/omniauth_callbacks#failure'
    delete 'logout', to: 'devise/sessions#destroy', as: :logout
  end

  authenticated :user do
    root 'dashboard#index', as: :authenticated_root

    get 'complete_profile', to: 'users#complete_profile', as: :complete_profile
    patch 'users/:id/update_profile', to: 'users#update_profile', as: :update_profile


    get 'profile', to: 'users#show', as: :profile
    get 'profile/edit', to: 'users#edit', as: :edit_profile
    patch 'profile', to: 'users#update'

    resources :community_activity, only: [:index, :show] do
      member do
        get 'feedback'
        post 'create_feedback'
      end
    end

    resources :follows, only: [:create, :destroy]

    get 'user_profile/:id', to: 'users#profile', as: :user_profile

    get '/users/:id/followers', to: 'users#show_followers', as: :user_followers
    get 'users/:id/following', to: 'users#show_following', as: :user_following

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
      collection do
        get 'my_projects'
        get 'favorite_projects', to: 'projects#favorite_projects'
      end

      member do
        get 'show_file/:file_id', to: 'projects#show_file', as: 'show_file'
        get 'edit_file/:file_id', to: 'projects#edit_file', as: 'edit_file'
        patch 'update_file/:file_id', to: 'projects#update_file', as: 'update_file'
        get 'new_file', to: 'projects#new_file', as: 'new_file'
        post 'create_file', to: 'projects#create_file', as: 'create_file'
        post 'invite_collaborator', to: 'projects#invite_collaborator', as: 'invite_collaborator'
        delete 'remove_collaborator', to: 'projects#remove_collaborator'
        get 'commit_logs', to: 'projects#commit_logs', as: 'commit_logs'
        post 'toggle_favorite', to: 'projects#toggle_favorite'
        get 'stats'
        patch 'update_permissions'
        get 'upload'
        get 'google_drive_auth'
        post 'google_drive_auth'
        post 'upload_to_google_drive'
        post 'upload_to_github'
        post 'upload_to_gitlab'
      end
    end

    post 'run_code', to: 'projects#run_code'

    resources :snippets do
      resources :history_records, only: [:index] do
        member do
          get 'previous', to: 'history_records#show_previous', as: :previous
        end
      end

      member do
        get 'share', to: 'shares#new', as: :new_share
        post 'share', to: 'shares#create'
        post 'toggle_favorite'
        get 'feedback'
        post 'create_feedback'
        delete 'feedback/:feedback_id', to: 'community_activity#destroy_feedback', as: 'destroy_feedback'
        post 'make_public'
      end

      collection do
        get 'drafts'
      end
    end

    resources :users, only: [:show] do
      member do
        get 'snippets', to: 'users#user_snippets', as: :user_snippets
        get 'projects', to: 'users#user_projects', as: :user_projects
        get 'leave_feedback'
        post 'create_feedback'
      end
    end

    # Follow/Unfollow Routes
    post 'users/:id/follow', to: 'follows#create', as: :follow_user
    delete 'users/:id/unfollow', to: 'follows#destroy', as: :unfollow_user

    # User's Snippets Routes
    get 'my_snippets', to: 'users#my_snippets', as: :my_snippets
    get 'favorite_snippets', to: 'users#favorite_snippets', as: :favorite_snippets
    # config/routes.rb
    get 'snippets/:id/from_profile', to: 'snippets#show_from_profile', as: :snippet_from_profile

    # Search Route
    get 'search', to: 'search#index'
    post 'search', to: 'search#results'

    get 'users/:id/profile_with_details', to: 'users#profile_with_details', as: :user_profile_with_details
    get 'user_profile/:id', to: 'users#profile_from_community', as: :user_profile_from_community
    get 'project_public/:id', to: 'projects#public_view', as: :project_public
    get 'download_project/:id', to: 'projects#download_project', as: :download_project
    get 'download_file/:id', to: 'projects#download_file', as: :download_file
    get 'accept_invitation/:token', to: 'collaborator_invitations#accept', as: :accept_invitation
    get '/oauth2callback', to: 'projects#google_drive_auth'
  end

end
