Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "locale/:locale", to: "locales#update", as: :set_locale, constraints: { locale: /uk|ru/ }

  resource :session, only: %i[new create destroy]
  resources :passwords, param: :token
  resource :registration, only: %i[new create]

  resources :categories, only: %i[index show], param: :slug
  resources :products, only: %i[index show], param: :slug

  namespace :admin do
    resources :categories
    resources :products
    resources :users
    # Phase D: orders & order_items dashboards here
    root to: "categories#index"
  end

  root "home#index"
  get "delivery", to: "pages#delivery"
  resources :contacts, only: %i[new create]
end
