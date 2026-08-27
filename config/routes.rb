Rails.application.routes.draw do
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
  resource :review_completion, only: :create, module: :reviews

  get "up" => "rails/health#show", as: :rails_health_check

  root "reviews#show"
end
