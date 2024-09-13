require 'rails_helper'

RSpec.feature 'Snippet Drafts', type: :feature do
  let!(:user) { FactoryBot.create(:user) }

  scenario 'User successfully logs in, creates a draft snippet, and views the snippets page' do
    visit new_user_session_path
    puts "Visited login page"

    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'
    puts "Clicked login button"

    # Attesa per osservare il login
    sleep 2

    # Verifica che l'utente sia reindirizzato alla dashboard
    expect(page).to have_current_path(authenticated_root_path)
    puts "On dashboard page"

    # Attesa per osservare la dashboard
    sleep 2

    # Clicca sul link "My Snippets"
    click_link 'My Snippets'
    puts "Clicked My Snippets link"

    # Attesa per osservare la pagina degli snippet
    sleep 2

    # Verifica che siamo nella pagina degli snippet
    expect(page).to have_current_path(my_snippets_path)
    puts "On My Snippets page"

    # Clicca sul link "New Snippet"
    click_link 'New Snippet'
    puts "Clicked New Snippet link"

    # Attesa per osservare il modulo di creazione
    sleep 2

    # Compila il modulo per il nuovo snippet
    fill_in 'Title', with: 'Draft Snippet'
    fill_in 'Content', with: 'This is a draft snippet'
    fill_in 'Comment', with: 'My first draft'
    click_button 'Save as Draft'
    puts "Clicked Save as Draft button"

    # Attesa per osservare il salvataggio
    sleep 2

    # Verifica il messaggio di successo
    expect(Snippet.last.draft).to be true

    click_link 'View Drafts'
    puts "Clicked View Drafts link"

    sleep 2

    click_link 'Draft Snippet'
    puts "Clicked Draft Snippet link"

    sleep 2

    click_button 'Make Public'
    puts "Clicked Make Public Button"

    sleep 2

    click_link 'Back to My Snippets'
    puts "Clicked Back to My Snippets Link"

    sleep 2

    save_and_open_page
  end
end
