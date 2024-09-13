require 'rails_helper'

RSpec.describe Snippet, type: :model do
  let(:user) { create(:user) }

  context 'when saving a draft' do
    it 'creates a snippet marked as draft' do
      snippet = Snippet.new(title: 'Test Snippet', content: 'Sample content', user: user, draft: true)
      expect(snippet.save).to be_truthy
      expect(snippet.draft).to be true
    end

    it 'validates presence of title for draft' do
      snippet = Snippet.new(content: 'Sample content', user: user, draft: true)
      expect(snippet.valid?).to be_falsey
      expect(snippet.errors[:title]).to include("can't be blank")
    end
  end
end
