require 'rails_helper'

RSpec.feature "UserSignInWithGoogleAndCompleteProfile", type: :feature do
  scenario "Utente accede tramite Google OAuth, completa il profilo e viene reindirizzato alla dashboard" do
    # Visita la landing page
    visit unauthenticated_root_path
    expect(page).to have_content("Sign In")

    # Clicca su "Sign In" e poi "Sign In with Google"
    click_link "Sign In"
    click_button "Sign in with Google"

    # OmniAuth utilizza il mock configurato in omniauth.rb
    expect(page).to have_current_path(complete_profile_path)
    expect(page).to have_content("Complete Your Profile")

    # Compila il form di completamento del profilo con il nome corretto per i campi
    fill_in "user_first_name", with: "Test"
    fill_in "user_last_name", with: "User"
    fill_in "user_nickname", with: "TestUser"
    fill_in "user_phone_number", with: "1234567890"

    # Clicca su "Update Profile"
    click_button "Update Profile"

    # Verifica che l'utente venga reindirizzato alla dashboard dopo aver completato il profilo
    expect(page).to have_current_path(authenticated_root_path)
    expect(page).to have_content("Welcome, TestUser")
    expect(page).to have_link("My Projects")
  end
end
