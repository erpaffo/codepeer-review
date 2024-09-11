class MessagesChannel < ApplicationCable::Channel
  def subscribed
    stream_from "messages_#{params[:conversation_id]}_channel"
  end

  def unsubscribed
    # Cleanup quando il canale viene chiuso
  end

  def send_message(data)
    conversation = Conversation.find(data['conversation_id'])
    message = conversation.messages.create(body: data['message'], user: current_user)

    if message.persisted?
      ActionCable.server.broadcast "messages_#{conversation.id}_channel", {
        user: message.user.nickname,
        body: message.body
      }
    end
  end
end
