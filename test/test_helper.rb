Rails.application.credentials[Rails.env.to_sym][:RAILS_ENV] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'database_cleaner'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...

  # Destroy all models because they do not get destroyed automatically
  DatabaseCleaner[:mongoid].strategy = :truncation

  # then, whenever you need to clean the DB
  DatabaseCleaner.clean
end
