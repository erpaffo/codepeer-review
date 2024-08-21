# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#meets_criteria?' do
    let(:user) { create(:user) }
    let(:badge_with_projects_criteria) { create(:badge, criteria_type: 'projects_count', criteria_value: 5) }
    let(:badge_with_feedbacks_criteria) { create(:badge, criteria_type: 'feedbacks_count', criteria_value: 10) }

    context 'when badge criteria are based on projects' do
      it 'returns true if the user has enough projects' do
        create_list(:project, 5, user: user)
        expect(user.meets_criteria?(badge_with_projects_criteria)).to be true
      end

      it 'returns false if the user does not have enough projects' do
        create_list(:project, 3, user: user)
        expect(user.meets_criteria?(badge_with_projects_criteria)).to be false
      end
    end

    context 'when badge criteria are based on feedbacks' do
      it 'returns true if the user has enough feedbacks' do
        create_list(:feedback, 10, user: user)
        expect(user.meets_criteria?(badge_with_feedbacks_criteria)).to be true
      end

      it 'returns false if the user does not have enough feedbacks' do
        create_list(:feedback, 7, user: user)
        expect(user.meets_criteria?(badge_with_feedbacks_criteria)).to be false
      end
    end
  end
end

