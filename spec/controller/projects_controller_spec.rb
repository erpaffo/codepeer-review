require 'rails_helper'

RSpec.describe ProjectsController, type: :controller do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:file) { fixture_file_upload('spec/fixtures/files/test_file.txt', 'text/plain') }
  let(:collaborator) { create(:user) }

  before do
    sign_in user
  end

  # 1. Creazione del progetto
  describe "POST #create" do
    context "con parametri validi" do
      it "crea un nuovo progetto e reindirizza alla pagina di caricamento file" do
        expect {
          post :create, params: { project: { title: 'Nuovo Progetto', description: 'Descrizione del progetto', visibility: 'public' } }
        }.to change(Project, :count).by(1)
        expect(response).to redirect_to(upload_files_project_path(Project.last))
      end
    end

    context "con parametri non validi" do
      it "non crea un nuovo progetto e rende la pagina new" do
        expect {
          post :create, params: { project: { title: '', description: '', visibility: 'private' } }
        }.not_to change(Project, :count)
        expect(response).to render_template(:new)
      end
    end
  end

  # 2. Upload dei file
  describe "POST #upload_file" do
    it "carica il file e restituisce il messaggio di successo" do
      post :upload_file, params: { id: project.id, file: file }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["message"]).to eq("File uploaded successfully")
    end
  end

  # 3. Visualizzazione del progetto
  describe "GET #show" do
    before do
      sign_in user
    end

    it "mostra il progetto pubblico" do
      project.update(visibility: 'public')
      get :show, params: { id: project.id }
      expect(response).to render_template(:show)
    end

  end

  # 4. Modifica del progetto
  describe "PATCH #update" do
    context "come proprietario" do
      it "aggiorna il progetto e reindirizza alla pagina del progetto" do
        patch :update, params: { id: project.id, project: { title: 'Updated Title' } }
        expect(response).to redirect_to(project_path(project))
        expect(project.reload.title).to eq('Updated Title')
      end
    end

    context "come non proprietario" do
      it "non permette di aggiornare il progetto e reindirizza" do
        another_user = create(:user)
        project.update(user: another_user)
        patch :update, params: { id: project.id, project: { title: 'Updated Title' } }
        expect(response).to redirect_to(projects_path)
        expect(flash[:alert]).to eq('You are not authorized to update this project.')
      end
    end
  end

  # 5. Eliminazione progetto
  describe "DELETE #destroy" do
    it "elimina il progetto e reindirizza alla pagina dei progetti" do
      project_to_delete = create(:project, user: user)

      expect {
        delete :destroy, params: { id: project_to_delete.id }
      }.to change(Project, :count).by(-1)

      expect(response).to redirect_to(projects_url)
    end

    it "non permette di eliminare un progetto non proprio" do
      another_user = create(:user)
      project.update(user: another_user)

      expect {
        delete :destroy, params: { id: project.id }
      }.not_to change(Project, :count)

      expect(response).to redirect_to(projects_path)
      expect(flash[:alert]).to eq('You are not authorized to delete this project.')
    end
  end

  # 6. Aggiungi/rimuovi collaboratore
  describe "DELETE #remove_collaborator" do
    it "rimuove il collaboratore dal progetto" do
      project.collaborators.create(user: collaborator)
      delete :remove_collaborator, params: { id: project.id, collaborator_id: collaborator.id }
      expect(response).to redirect_to(edit_project_path(project))
      expect(flash[:notice]).to eq("Collaborator removed successfully.")
    end
  end

  # 7. Statistiche del progetto
  describe "GET #stats" do
    it "mostra le statistiche di visualizzazione e i preferiti" do
      get :stats, params: { id: project.id }
      expect(assigns(:unique_views)).to eq(project.unique_view_count)
      expect(assigns(:favorite_count)).to eq(project.favorite_count)
    end
  end

  # 8. Gestione dei preferiti
  describe "POST #toggle_favorite" do
    it "aggiunge il progetto ai preferiti" do
      post :toggle_favorite, params: { id: project.id }
      expect(response).to redirect_to(projects_path)
      expect(flash[:notice]).to eq('Project was added to your favorites.')
      expect(user.favorite_projects).to include(project)
    end

    it "rimuove il progetto dai preferiti" do
      user.favorites.create(project: project)
      post :toggle_favorite, params: { id: project.id }
      expect(response).to redirect_to(projects_path)
      expect(flash[:notice]).to eq('Project was removed from your favorites.')
      expect(user.favorite_projects).not_to include(project)
    end
  end
end
