class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications
  end

  def mark_as_read
    @notification = Notification.find(params[:id])
    @notification.update(read: true)

    respond_to do |format|
      format.html { redirect_to notifications_path }
      format.json { render json: { success: true } } # Risposta JSON per AJAX
    end
  end

  def destroy
    @notification = Notification.find(params[:id])
    @notification.destroy

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: 'Notification was successfully deleted.' }
      format.js { render inline: "location.reload();" } # Reload per aggiornare la vista
      format.json { render json: { success: true } } # Risposta JSON per AJAX
    end
  end
end
