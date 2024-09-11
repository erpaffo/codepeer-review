class ChatChannel < ApplicationCable::Channel
  def subscribed
    # Esempio: sottoscrivi all'intero canale di chat o a una chat specifica
    stream_from "chat_channel"
  end

  def unsubscribed
    # Cleanup quando l'utente si disconnette
  end
end
