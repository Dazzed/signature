Rails.application.routes.draw do
  root "deal#show"
  get '/deal/payment' => 'deal#payment', as: :deal_payment
  post '/deal/payment_update' => 'deal#payment_update', as: :deal_payment_update
  get '/deal/thank_you' => 'deal#thank_you', as: :deal_thank_you
  get "/deal/show/:client_deal_id" => 'deal#show', as: :deal_show

  get '/document/new', to: 'document#new', as: 'new_document'
  get '/documents', to: 'document#index', as: 'documents'
  post '/documents', to: 'document#create', as: 'create_document'
  get '/document/initiate_signing', to: 'document#initiate_signature'
  get '/document/signature_success' => 'document#signature_success', as: :document_signature_success

  post '/callbacks', to: 'callback#hello_sign_callback', as: 'hellosign_callback'

end
