require 'rails_helper'

RSpec.feature 'Profile Image Update', type: :feature do
  let!(:user) { FactoryBot.create(:user) }
  let(:new_profile_image) { Rails.root.join('spec', 'fixtures', 'files', 'new_profile_image.jpg') }

  scenario 'User successfully logs in, navigates to My Profile, and updates the profile image' do
    visit new_user_session_path
    puts "Visited login page"

    sleep 2

    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'
    puts "Clicked login button"

    sleep 2

    # Attendi che la pagina della dashboard sia visibile
    expect(page).to have_current_path(authenticated_root_path)
    puts "On dashboard page"

    sleep 2

    # Clicca sul link "Profile"
    expect(page).to have_link('Profile')
    click_link 'Profile'
    puts "Clicked Profile link"

    sleep 2

    # Clicca sul link "Edit Profile"
    expect(page).to have_link('Edit Profile')
    click_link 'Edit Profile'
    puts "Clicked Edit Profile Link"

    sleep 2

    # Attendi che la pagina di modifica del profilo sia visibile
    expect(page).to have_current_path(edit_profile_path)
    puts "On Edit Profile page"

    sleep 2

    # Seleziona la nuova immagine del profilo
    new_profile_image = Rails.root.join('spec', 'fixtures', 'files', 'new_profile_image.jpg')
    attach_file('profile_image', new_profile_image, make_visible: true)
    puts "Selected new profile image"

    sleep 2

    # Clicca sul pulsante per aggiornare il profilo
    click_button 'Update Profile'
    puts "Clicked Update Profile button"

    sleep 2


    save_and_open_page
  end
end
