Rails.application.routes.draw do
  root "home#init_deal_data"
  get '/get_form', to: 'home#get_form_for_template', as: 'home_get_form'
  post '/send_emails', to: 'home#email_document_for_signature', as: 'home_send_emails'
  get '/initiate_signing', to: 'home#initiate_signature'
  get '/view_stripe' => 'home#view_stripe', as: :view_stripe
  post '/stripe_update' => 'home#stripe_update', as: :stripe_update
  get '/thank_you' => 'home#thank_you', as: :thank_you
  get '/success' => 'home#success', as: :home_success

  post '/callbacks', to: 'callback#hello_sign_callback', as: 'hellosign_callback'

  get "/init_alternate/:client_deal_id" => 'home#init_deal_data', as: :init_alternate
end
