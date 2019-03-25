require "hello_sign"
HelloSign.configure do |config|
  config.api_key = Rails.application.credentials[:HELLO_SIGN_API_KEY]
  # You can use email_address and password instead of api_key. But api_key is recommended
  # If api_key, email_address and password are all present, api_key will be used
  # config.email_address = 'email_address'
  # config.password = 'password'
end
