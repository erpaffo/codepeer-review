require 'rails_helper'

RSpec.feature 'Snippet Drafts', type: :feature do
  let!(:user) { FactoryBot.create(:user) }

  scenario 'User successfully logs in, creates a draft snippet, and views the snippets page' do
    # Step 1: Simula il login
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'

    # Verifica che l'utente sia reindirizzato alla dashboard dopo il login
    expect(page).to have_current_path(authenticated_root_path)

    # Step 2: Naviga verso "My Snippets"
    click_link 'My Snippets'

    # Verifica che la pagina "My Snippets" sia stata caricata correttamente
    expect(page).to have_current_path(my_snippets_path)

    # Step 3: Crea un nuovo Snippet come Draft
    click_link 'New Snippet'

    # Verifica che il modulo di creazione snippet sia visibile
    expect(page).to have_selector('form')

    # Compila il modulo per il nuovo snippet
    fill_in 'Title', with: 'Draft Snippet'
    fill_in 'Content', with: 'This is a draft snippet'
    fill_in 'Comment', with: 'My first draft'
    click_button 'Save as Draft'

    # Verifica che lo snippet sia stato salvato come bozza
    expect(Snippet.last.draft).to be true

    # Step 4: Visualizza la lista delle bozze
    click_link 'View Drafts'

    # Verifica che il draft creato sia visibile
    expect(page).to have_content('Draft Snippet')

    # Step 5: Cambia lo stato da draft a pubblico
    click_link 'Draft Snippet'
    click_button 'Make Public'

    # Verifica che lo snippet non sia più un draft
    expect(Snippet.last.draft).to be false

    # Step 6: Ritorna alla pagina "My Snippets"
    click_link 'Back to My Snippets'

    # Verifica che la pagina "My Snippets" sia stata caricata correttamente
    expect(page).to have_current_path(my_snippets_path)

    # Verifica che lo snippet pubblico sia visibile nella lista
    expect(page).to have_content('Draft Snippet')
  end
end
