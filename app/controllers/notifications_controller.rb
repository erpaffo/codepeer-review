# app/controllers/notifications_controller.rb
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
      format.js   # Per rispondere con un template JS se necessario
    end
  end

  def destroy
    @notification = Notification.find(params[:id])
    @notification.destroy

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: 'Notification was successfully deleted.' }
      format.js   # Per rispondere con un template JS se necessario
    end
  end
end
