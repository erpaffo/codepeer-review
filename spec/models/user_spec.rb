require 'rails_helper'

describe User, '#meets_criteria?' do
  let(:user) { create(:user) }

  context 'when badge criteria are based on projects' do
    let(:badge_with_projects_criteria) { create(:badge, criteria: { action: 'create_project', count: 1 }) }

    before do
      create_list(:project, 1, user: user)
    end

    it 'returns true if the user has enough projects' do
      expect(user.send(:meets_criteria?, badge_with_projects_criteria)).to be(true)
    end
  end

  context 'when badge criteria are based on feedbacks' do
    let(:badge_with_feedbacks_criteria) { create(:badge, criteria: { action: 'leave_feedback', count: 3 }) }

    before do
      create_list(:feedback, 3, user: user)
    end

    it 'returns true if the user has enough feedbacks' do
      expect(user.send(:meets_criteria?, badge_with_feedbacks_criteria)).to be(true)
    end
  end
end
