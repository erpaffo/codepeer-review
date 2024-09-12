class ConversationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @conversations = current_user.conversations.includes(:messages)
  end

  def new
    @conversation = Conversation.new
    @recipients = current_user.following
  end

  def show
    @conversation = Conversation.includes(messages: :user).find(params[:id])
    @messages = @conversation.messages
    @sender = User.find_by(id: @conversation.sender_id)
    @recipient = User.find_by(id: @conversation.recipient_id)
  end

  def create
    recipient = User.find_by(id: params[:recipient_id])

    if recipient.nil?
      redirect_to user_profile_path(current_user), alert: 'Utente destinatario non trovato.'
      return
    end

    if current_user.id == recipient.id
      redirect_to user_profile_path(recipient), alert: 'Non è possibile avviare una conversazione con se stessi.'
      return
    end

    @conversation = Conversation.where(sender_id: current_user.id, recipient_id: recipient.id)
                                .or(Conversation.where(sender_id: recipient.id, recipient_id: current_user.id))
                                .first_or_initialize

    @conversation.sender = current_user
    @conversation.recipient = recipient

    if @conversation.save
      redirect_to conversation_messages_path(@conversation)
    else
      redirect_to user_profile_from_community_path(recipient), alert: 'Non è stato possibile avviare una conversazione.'
    end
  end

  def destroy
    @conversation = Conversation.find(params[:id])
    if @conversation.destroy
      flash[:success] = "Conversazione eliminata con successo."
      redirect_to conversations_path
    else
      flash[:error] = "Impossibile eliminare la conversazione."
      render :index
    end
  end
end
