require 'rails_helper'

RSpec.describe RegistrationsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "POST #create" do
    context "con parametri validi" do
      it "crea un nuovo utente e invia un'email di conferma" do
        expect {
          post :create, params: { user: { email: 'test@example.com', password: 'Password1!', password_confirmation: 'Password1!' } }
        }.to change(User, :count).by(1)

        user = User.find_by(email: 'test@example.com')
        expect(user).not_to be_nil
        expect(user.confirmed?).to be_falsey  # L'utente non è ancora confermato
        expect(ActionMailer::Base.deliveries.last.to).to eq([user.email])
      end
    end

    context "con parametri non validi" do
      it "non crea un nuovo utente" do
        expect {
          post :create, params: { user: { email: '', password: 'Password1!', password_confirmation: 'Password1!' } }
        }.not_to change(User, :count)
      end
    end
  end
end
