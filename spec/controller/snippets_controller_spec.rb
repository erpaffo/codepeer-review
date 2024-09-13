require 'rails_helper'

RSpec.describe SnippetsController, type: :controller do
  let(:user) { create(:user) }
  let(:snippet) { create(:snippet, user: user) }

  before do
    sign_in user
  end

  # 1. Nuovo snippet
  describe "GET #new" do
    it "restituisce un nuovo snippet" do
      get :new
      expect(assigns(:snippet)).to be_a_new(Snippet)
    end
  end

  # 2. Creazione snippet
  describe "POST #create" do
    context "con parametri validi" do
      it "crea uno snippet e reindirizza a my_snippets_path" do
        expect {
          post :create, params: { snippet: { title: 'New Snippet', content: 'Some code', comment: 'This is a test comment' } }
        }.to change(Snippet, :count).by(1)
        expect(response).to redirect_to(my_snippets_path)
        expect(flash[:notice]).to eq('Snippet was successfully created.')
      end
    end

    context "con parametri non validi" do
      it "non crea uno snippet e renderizza la pagina new" do
        post :create, params: { snippet: { title: '', content: '', comment: '' } }
        expect(response).to render_template(:new)
      end
    end
  end

  # 3. Modifica snippet
  describe "GET #edit" do
    it "mostra la pagina di modifica per uno snippet" do
      get :edit, params: { id: snippet.id }
      expect(assigns(:snippet)).to eq(snippet)
    end
  end

  # 4. Aggiornamento snippet
  describe "PATCH #update" do
    context "con parametri validi" do
      it "aggiorna lo snippet e reindirizza alla pagina dello snippet" do
        patch :update, params: { id: snippet.id, snippet: { title: 'Updated Title', content: 'Updated code' } }
        expect(response).to redirect_to(snippet_path(snippet))
        expect(flash[:notice]).to eq('Snippet was successfully updated.')
        expect(snippet.reload.title).to eq('Updated Title')
      end
    end

    context "con parametri non validi" do
      it "non aggiorna lo snippet e renderizza la pagina edit" do
        patch :update, params: { id: snippet.id, snippet: { title: '', content: '' } }
        expect(response).to render_template(:edit)
      end
    end
  end

  # 5. Eliminazione snippet
  describe "DELETE #destroy" do
    it "elimina lo snippet e reindirizza a my_snippets_path" do
      snippet_to_delete = create(:snippet, user: user)
      expect {
        delete :destroy, params: { id: snippet_to_delete.id }
      }.to change(Snippet, :count).by(-1)
      expect(response).to redirect_to(my_snippets_path)
      expect(flash[:notice]).to eq('Snippet was successfully deleted.')
    end
  end

  # 6. Toggle favorite
  describe "POST #toggle_favorite" do
    it "aggiorna lo stato di favorite dello snippet" do
      post :toggle_favorite, params: { id: snippet.id }
      expect(response).to redirect_to(my_snippets_path)
      expect(flash[:notice]).to eq('Snippet favorite status updated.')
      expect(snippet.reload.favorite).to be_truthy
    end
  end

  # 7. Make public
  describe "POST #make_public" do
    it "rende pubblico uno snippet bozza e reindirizza alla pagina dello snippet" do
      draft_snippet = create(:snippet, user: user, draft: true)
      post :make_public, params: { id: draft_snippet.id }
      expect(response).to redirect_to(snippet_path(draft_snippet))
      expect(flash[:notice]).to eq('Snippet has been made public.')
      expect(draft_snippet.reload.draft).to be_falsey
    end
  end

  # . Drafts: Mostra solo le bozze dell'utente
  describe "GET #drafts" do
    it "mostra solo le bozze dell'utente" do
      draft_snippet = create(:snippet, user: user, draft: true)
      get :drafts
      expect(assigns(:drafts)).to include(draft_snippet)
    end
  end
end
