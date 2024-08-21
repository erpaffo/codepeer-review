# app/controllers/community_activity_controller.rb
class CommunityActivityController < ApplicationController
  before_action :authenticate_user!

  def index
    @snippets = Snippet.where.not(user_id: current_user.id)
  end

  def feedback
    @snippet = Snippet.find(params[:id])
  end

  def create_feedback
    @snippet = Snippet.find(params[:id])
    @feedback = @snippet.feedbacks.new(feedback_params)
    @feedback.user = current_user

    if @feedback.save
      redirect_to community_activity_path(@snippet), notice: 'Feedback sent successfully'
    else
      render :feedback
    end
  end

  def destroy_feedback
      @snippet = Snippet.find(params[:id])
      @feedback = @snippet.feedbacks.find(params[:feedback_id])
      @feedback.destroy
      redirect_to @snippet, notice: 'Feedback was successfully deleted.'
    end
    
  def show
    @snippet = Snippet.find(params[:id])
  end


  private

  def feedback_params
    params.permit(:content)
  end
end
