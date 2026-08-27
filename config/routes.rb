Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  # Today's review is the front door.
  resource :review, only: :show
  resources :books, only: %i[ index show ]
  resource :search, only: :show

  get "up" => "rails/health#show", as: :rails_health_check

  root "reviews#show"
end
