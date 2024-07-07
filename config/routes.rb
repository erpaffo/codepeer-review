Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
    get 'complete_profile', to: 'users#complete_profile', as: :complete_profile
    patch 'update_profile', to: 'users#update_profile'
    get 'profile/edit', to: 'users#edit', as: :edit_profile
    patch 'profile', to: 'users#update'
    get 'two_factor_auth/new', to: 'two_factor_auth#new', as: :new_two_factor_auth
    post 'two_factor_auth', to: 'two_factor_auth#create', as: :two_factor_auth
    patch 'enable_two_factor_auth', to: 'users#enable_two_factor_auth', as: :enable_two_factor_auth
    patch 'disable_two_factor_auth', to: 'users#disable_two_factor_auth', as: :disable_two_factor_auth
  end

  unauthenticated do
    root 'welcome#index', as: :unauthenticated_root
  end
end
