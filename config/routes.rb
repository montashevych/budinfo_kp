Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "locale/:locale", to: "locales#update", as: :set_locale, constraints: { locale: /uk|ru/ }

  root "home#index"
  get "delivery", to: "pages#delivery"
  resources :contacts, only: %i[new create]
end
