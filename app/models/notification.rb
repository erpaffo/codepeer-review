# app/models/notification.rb
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifier, class_name: 'User', foreign_key: 'notifier_id'
  belongs_to :badge, optional: true
  scope :unread, -> { where(read_at: nil) }

  validates :message, presence: true

  # Metodo per ottenere l'utente che ha generato la notifica
  def notifier
    User.find(self.user_id) # Usa user_id per ottenere l'utente
  end
  # Metodo per creare una notifica quando un feedback viene lasciato su uno snippet
  def self.create_snippet_feedback_notification(snippet, notifier)
    message = "#{notifier.email} ha lasciato un feedback sul tuo snippet #{snippet.title}."
    Notification.create(user: snippet.user, notifier: notifier, message: message)
  end

  # Metodo per creare una notifica quando un feedback viene lasciato su un profilo
  def self.create_profile_feedback_notification(profile_user, notifier)
    message = "#{notifier.email} ha lasciato un feedback sul tuo profilo."
    Notification.create(user: profile_user, notifier: notifier, message: message)
  end
  # Metodo per creare una notifica quando un badge viene assegnato
  def self.create_badge_notification(user, badge, notifier)
    message = "Congratulazioni! Hai ottenuto il badge '#{badge.name}' per aver completato una specifica azione."
    Notification.create(user: user, notifier: notifier, badge: badge, message: message)
  end
  
  # Metodo per creare una notifica quando una snapshot viene completata
  def self.create_snapshot_completed_notification(snapshot)
    message = "Your session snapshot '#{snapshot.name}' has been created successfully with #{snapshot.file_count} files."
    Notification.create(user: snapshot.user, notifier: snapshot.user, message: message)
  end
  
  # Metodo per creare una notifica quando una snapshot viene ripristinata
  def self.create_snapshot_restored_notification(snapshot)
    message = "Your session snapshot '#{snapshot.name}' has been restored successfully."
    Notification.create(user: snapshot.user, notifier: snapshot.user, message: message)
  end
end
