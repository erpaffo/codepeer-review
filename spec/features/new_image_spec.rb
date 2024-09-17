require 'rails_helper'

RSpec.feature 'Profile Image Update', type: :feature do
  let!(:user) { FactoryBot.create(:user) }
  let(:new_profile_image) { Rails.root.join('spec', 'fixtures', 'files', 'new_profile_image.jpg') }

  scenario 'User successfully logs in, navigates to My Profile, and updates the profile image' do
    # Visita la pagina di login e accedi
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'

    # Verifica che l'utente sia stato reindirizzato alla dashboard
    expect(page).to have_current_path(authenticated_root_path)

    # Naviga al profilo dell'utente
    click_link 'Profile'

    # Verifica di essere nella pagina del profilo
    expect(page).to have_content("Edit Profile")

    # Clicca su "Edit Profile"
    click_link 'Edit Profile'

    # Verifica di essere nella pagina di modifica del profilo
    expect(page).to have_current_path(edit_profile_path)

    # Seleziona la nuova immagine del profilo
    attach_file('user_profile_image', new_profile_image)

    # Clicca sul pulsante per aggiornare il profilo
    click_button 'Update Profile'

    click_link 'Profile'
    
    # Verifica che la nuova immagine del profilo sia visibile
    expect(page).to have_css("img[src*='new_profile_image.jpg']")
  end
end
