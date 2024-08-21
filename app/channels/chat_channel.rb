# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    # stream_from permette di abbonarsi ad un particolare stream
    stream_from "chat_#{params['chat_room_id']}_channel"
  end

  def unsubscribed
    # Qualsiasi pulizia necessaria quando il canale viene disabbonato
  end

  def speak(data)
    Message.create!(
      content: data['message'],
      user: current_user,
      chat_room_id: params['chat_room_id']
    )
  end
end
