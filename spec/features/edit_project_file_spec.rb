require 'rails_helper'

RSpec.feature "EditProjectFile", type: :feature do
  let(:user) { create(:user) }
  let!(:project) { create(:project, user: user) }
  let!(:project_file) { create(:project_file, project: project) }

  scenario "Utente modifica un file di progetto utilizzando Monaco Editor" do
    # Simula l'accesso dell'utente
    sign_in user

    # Naviga alla pagina "My Projects"
    visit projects_path
    expect(page).to have_content("My Projects")

    # Trova e clicca sul pulsante "Show" relativo al progetto
    within("table.project-table") do
      find("tr", text: project.title).click_link("Show")
    end

    # Verifica di essere nella pagina di dettaglio del progetto
    expect(page).to have_content(project.title)
    expect(page).to have_content("Files")

    # Seleziona il file da modificare
    click_link project_file.file_identifier
    click_link "Edit File"

    # Verifica che Monaco Editor sia caricato con il contenuto del file
    expect(page).to have_css('#code-editor', visible: true)

    # Usa JavaScript per modificare il contenuto del file in Monaco Editor
    new_content = "Modificato il contenuto del file"
    page.execute_script("monaco.editor.getModels()[0].setValue('#{new_content}')")

    # Salva il file cliccando su "Save File"
    click_button "Save File"

    # Torna alla pagina "Show" del progetto
    visit project_path(project)

    # Clicca di nuovo sul file per verificare che il contenuto sia stato modificato correttamente
    click_link project_file.file_identifier

    # Verifica che il contenuto del file sia stato aggiornato
    expect(page).to have_content(new_content)
  end
end
