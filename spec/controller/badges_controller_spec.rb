require 'rails_helper'

RSpec.describe BadgesController, type: :controller do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'returns a successful response' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'populates an array of badges for the current user' do
      badge = create(:badge)
      user.badges << badge
      get :index
      expect(assigns(:badges)).to eq(user.badges)
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end
  end
end
