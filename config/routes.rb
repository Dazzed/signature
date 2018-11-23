Rails.application.routes.draw do
  root "home#initDealData"
  get '/getForm', to: 'home#getFormForTemplate', as: 'home_get_form'
  post '/sendEmails', to: 'home#emailDocumentForSignature', as: 'home_send_emails'
  get '/initiateSigning', to: 'home#initiateSignature'
  get '/view_stripe' => 'home#view_stripe', as: :view_stripe
  post '/stripe_update' => 'home#stripe_update', as: :stripe_update
  get '/thank_you' => 'home#thank_you', as: :thank_you
  get '/success' => 'home#success', as: :home_success

  post '/callbacks', to: 'callback#helloSignCallback', as: 'hellosign_callback'

  get "/init_alternate/:deal_id" => 'home#initDealData', as: :init_alternate
end
