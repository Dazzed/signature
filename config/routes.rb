Rails.application.routes.draw do
  root "home#init"
  get '/getForm', to: 'home#getForm', as: 'home_get_form'
  post '/sendEmails', to: 'home#sendEmails', as: 'home_send_emails'
  get '/initiateSigning', to: 'home#initiateSigning'
end
