Rails.application.routes.draw do
  root "home#init"
  get '/getForm', to: 'home#getForm', as: 'home_get_form'
  post '/sendEmails', to: 'home#sendEmails', as: 'home_send_emails'
  get '/initiateSigning', to: 'home#initiateSigning'
  get '/view_stripe' => 'home#view_stripe', as: :view_stripe
  post '/stripe_update' => 'home#stripe_update', as: :stripe_update
  get '/thank_you' => 'home#thank_you', as: :thank_you
  get '/success' => 'home#success', as: :home_success
  # resources :home, only: [:new, :create] do    
  #   collection do      
  #     post 'callbacks'    
  #   end  
  # end

  post '/callbacks', to: 'home#callbacks', as: 'home_callbacks'
end
