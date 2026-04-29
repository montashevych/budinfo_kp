Rails.application.routes.draw do
  # Chrome DevTools probes this path; a route avoids noisy ActionController::RoutingError in development.
  if Rails.env.development?
    get "/.well-known/appspecific/com.chrome.devtools.json", to: proc { [204, {}, []] }
  end

  get "up" => "rails/health#show", as: :rails_health_check

  get "locale/:locale", to: "locales#update", as: :set_locale, constraints: { locale: /uk|ru/ }

  resource :session, only: %i[new create destroy]
  resources :passwords, param: :token
  resource :registration, only: %i[new create]

  resources :categories, only: %i[index show], param: :slug
  resources :products, only: %i[index show], param: :slug
  resources :promotions, only: :show, param: :slug

  resource :cart, only: :show do
    post :add, on: :member
    patch :update_line, on: :member
    delete :remove_line, on: :member
  end

  resource :checkout, only: %i[new create]
  get "/o/:public_token", to: "order_confirmations#show", as: :order_confirmation

  namespace :admin do
    resources :categories
    resources :products
    resources :home_promotions
    resources :users
    resources :orders
    resources :order_items
    root to: "categories#index"
  end

  root "home#index"
  get "delivery", to: "pages#delivery"
  resources :contacts, only: %i[new create]

  get "/sitemap.xml", to: "sitemaps#show", as: :sitemap, defaults: { format: :xml }
  get "/robots.txt", to: "robots#show", as: :robots, defaults: { format: :text }

  # Routed by config.exceptions_app when consider_all_requests_local is false (e.g. production).
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
end
