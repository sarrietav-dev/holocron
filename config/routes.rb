Rails.application.routes.draw do
  resource :setup, only: %i[ show create ]
  resource :session
  resources :passwords, param: :token

  # Today's review is the front door.
  resource :review, only: :show
  resources :books, only: %i[ index show ]
  resource :search, only: :show
  resources :highlights, only: [] do
    resource :favorite, only: %i[ create destroy ], module: :highlights
    resource :discard, only: %i[ create destroy ], module: :highlights
    resource :note, only: :update, module: :highlights
    resources :tags, only: %i[ create destroy ], module: :highlights
  end
  resource :review_completion, only: :create, controller: "reviews/completions"
  resources :imports, only: :index
  namespace :imports do
    resource :clippings, only: :create
    resource :notebook, only: :create
  end
  resource :settings, only: %i[ show update ]
  scope "credentials/:provider", as: :credential, module: :credentials do
    resource :test, only: :create
  end
  namespace :obsidian do
    resource :sync, only: :create
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "reviews#show"
end
