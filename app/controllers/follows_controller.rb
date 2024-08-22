# app/controllers/follows_controller.rb
class FollowsController < ApplicationController
  before_action :authenticate_user!

  def create
    @user = User.find(params[:id])

    if current_user.following?(@user)
      flash[:notice] = "You are already following this user."
    else
      current_user.follow(@user)
      Notification.create(
        user_id: @user.id,
        message: "#{current_user.nickname.present? ? current_user.nickname : current_user.email} has started following you!",
        notifier_id: current_user.id, 
        read: false
      )
      flash[:notice] = "You are now following this user."
    end

    respond_to do |format|
      format.html { redirect_to user_profile_with_details_path(@user) }
      format.js   # Questo richiede un template create.js.erb
    end
  end

  def destroy
    @user = User.find(params[:id])

    if current_user.following?(@user)
      current_user.unfollow(@user)
      flash[:notice] = "You have unfollowed this user."
    else
      flash[:notice] = "You are not following this user."
    end

    respond_to do |format|
      format.html { redirect_to user_profile_from_community_path(@user) }
      format.js   # Assicurati di avere un template destroy.js.erb se necessario
    end
  end
end
