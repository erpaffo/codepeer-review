require 'capybara/rspec'
require 'capybara/rails'
require 'capybara-screenshot/rspec'
require 'launchy'

Capybara.configure do |config|
  config.default_max_wait_time = 5 # seconds
  config.default_driver = :selenium_chrome # Usa questo driver per il debug
  config.javascript_driver = :selenium_chrome # Usa questo driver per test JavaScript
end

Capybara::Screenshot.autosave_on_failure = true

# Configura per aprire automaticamente le pagine salvate
Capybara::Screenshot.register_driver(:selenium_chrome) do |driver, path|
  Launchy.open(path)
end
