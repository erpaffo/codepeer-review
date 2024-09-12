require 'rails_helper'

RSpec.describe Badge, type: :model do
  subject { build(:badge) }

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:icon) }
  end

  describe 'associations' do
    it { should have_many(:user_badges) }
    it { should have_many(:users).through(:user_badges) }
  end
end
