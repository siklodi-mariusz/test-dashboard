Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :admin do
    resources :users, only: [:index, :show, :edit, :update, :destroy]
    root "users#index"
  end

  authenticated :user do
    root "dashboard#show", as: :authenticated_root
  end

  root to: redirect("/users/sign_in")

  get "dashboard", to: "dashboard#show"
end
