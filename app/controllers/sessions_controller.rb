class SessionsController < ApplicationController
  before_action :authenticate_user!

  def index
    @sessions = current_user.user_sessions
  end

  def destroy
    @session = current_user.user_sessions.find(params[:id])
    @session.destroy
    redirect_to sessions_path, notice: 'Session terminated successfully.'
  end
end
