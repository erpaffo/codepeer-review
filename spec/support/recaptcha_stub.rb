# spec/support/recaptcha_stub.rb

RSpec.configure do |config|
  config.before(:each) do
    # Stub della verifica di reCAPTCHA
    allow_any_instance_of(Recaptcha::Adapters::ControllerMethods).to receive(:verify_recaptcha).and_return(true)
  end
end
