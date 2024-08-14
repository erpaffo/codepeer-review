require 'cucumber/rails'

Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.default_driver = :selenium
Capybara.javascript_driver = :selenium


World(Warden::Test::Helpers)

After do
  Warden.test_reset!
end

Before do
  Warden.test_mode!
end

DatabaseCleaner.strategy = :truncation
