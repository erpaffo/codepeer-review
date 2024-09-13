require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "POST #create" do
    context "con reCAPTCHA valido" do
      before do
        allow(controller).to receive(:verify_recaptcha).and_return(true)
      end

      it "autentica l'utente e reindirizza alla pagina principale" do
        user = create(:user, password: 'Password1!')
        post :create, params: { user: { email: user.email, password: 'Password1!' } }
        expect(response).to redirect_to(complete_profile_path)
      end
    end

    context "con reCAPTCHA non valido" do
      before do
        allow(controller).to receive(:verify_recaptcha).and_return(false)
      end

      it "mostra un messaggio di errore e non autentica l'utente" do
        post :create, params: { user: { email: 'test@example.com', password: 'Password1!' } }
        expect(flash[:alert]).to eq('CAPTCHA non valido. Riprova.')
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
