require 'stripe'
Stripe.api_key = Rails.application.credentials[Rails.env.to_sym][:STRIPE_SK]
