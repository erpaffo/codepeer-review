# config/routes.rb

Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  resources :projects

  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end
  root 'welcome#index'
end
