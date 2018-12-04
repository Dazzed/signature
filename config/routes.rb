Rails.application.routes.draw do
  root "deals#index"
  resources :deals, only: :index
  resources :documents, only: [:new, :create, :index]

  namespace :deal do
    resources :payments, only: [:new, :create]
    resources :payment_thanks, only: :index
  end

  namespace :document do
    resources :signatures, only: [:new]
    resources :signature_thanks, only: :index
  end

  namespace :callbacks do
    resources :hellosign, only: :create
  end
end
