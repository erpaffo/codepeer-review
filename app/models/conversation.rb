class Conversation < ApplicationRecord
  belongs_to :sender, class_name: 'User'
  belongs_to :recipient, class_name: 'User'

  has_many :messages, dependent: :destroy

  validates :sender, presence: true
  validates :recipient, presence: true
  validate :sender_and_recipient_are_different

  def other_participant(user)
    return recipient if sender == user
    return sender if recipient == user
    nil
  end

  private

  def sender_and_recipient_are_different
    if sender_id == recipient_id
      errors.add(:recipient, "Il destinatario deve essere diverso dal mittente.")
    end
  end
end
