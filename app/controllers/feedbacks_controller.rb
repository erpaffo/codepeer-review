# app/controllers/feedbacks_controller.rb
class FeedbacksController < ApplicationController
  before_action :set_user

  def create
    @feedback = @user.feedbacks.build(feedback_params)
    if @feedback.save
      redirect_to user_path(@user), notice: 'Feedback inviato con successo!'
    else
      redirect_to user_path(@user), alert: 'Errore nell\'invio del feedback.'
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def feedback_params
    params.require(:feedback).permit(:content)
  end
end
