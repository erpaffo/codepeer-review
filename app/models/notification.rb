# app/models/notification.rb
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifier, class_name: 'User', foreign_key: 'notifier_id'

  validates :message, presence: true

  # Metodo per ottenere l'utente che ha generato la notifica
  def notifier
    User.find(self.user_id) # Usa user_id per ottenere l'utente
  end
end
