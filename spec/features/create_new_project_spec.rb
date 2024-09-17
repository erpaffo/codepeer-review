require 'rails_helper'

RSpec.feature "CreateNewProject", type: :feature do
  # Utilizza la factory per creare un utente
  let(:user) { create(:user) }

  scenario "Utente crea un nuovo progetto" do
    # Simula l'accesso dell'utente
    sign_in user

    # Visita la dashboard dopo che l'utente è loggato
    visit authenticated_root_path
    expect(page).to have_link("My Projects")

    # Naviga nella sezione "My Projects"
    click_link "My Projects"

    # Clicca su "New Project"
    click_link "New Project"

    # Compila il form del progetto
    fill_in "project_title", with: "Progetto Esempio"
    fill_in "project_description", with: "Questo è un progetto di esempio"

    # Clicca sul pulsante "Create Project"
    click_button "Create Project"

    # Verifica che l'utente sia stato reindirizzato alla pagina di upload
    expect(page).to have_content("Upload Files for Progetto Esempio")

    click_link "Back to Project"

    # Verifica che il file sia visibile nel progetto
    visit project_path(Project.last)

    # Controlla se il progetto è stato aggiunto nella lista dei progetti
    visit projects_path
    expect(page).to have_content("Progetto Esempio")
  end
end
