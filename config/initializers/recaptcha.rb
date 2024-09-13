# config/initializers/recaptcha.rb

Recaptcha.configure do |config|
  if Rails.env.test?
    # Chiavi di test per l'ambiente di test
    config.site_key  = 'test'
    config.secret_key = 'test'
  else
    # Chiavi reali per sviluppo e produzione
    config.site_key  = ENV['RECAPTCHA_SITE_KEY']
    config.secret_key = ENV['RECAPTCHA_SECRET_KEY']
  end
end
