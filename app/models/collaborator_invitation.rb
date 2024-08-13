class CollaboratorInvitation < ApplicationRecord
  belongs_to :project
  belongs_to :user, optional: true

  before_create :generate_token

  private

  def generate_token
    self.token = SecureRandom.hex(10)
  end
end
