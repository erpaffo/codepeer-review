class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :profile_from_community, :profile_with_details, :profile, :leave_feedback, :create_feedback, :edit, :update, :follow, :unfollow ,:update_role]
  before_action :ensure_admin, only: [:manage_permissions]

  include UsersHelper

  def complete_profile
    @user = current_user
  end

  def update_profile
    @user = current_user

    if @user.update(user_params)
      handle_profile_image_update
      redirect_to authenticated_root_path, notice: 'Profile updated successfully'
    else
      render :complete_profile
    end
  end

  def update_role
    if current_user.admin?
      if @user.update(user_params)
        redirect_to manage_permissions_users_path, notice: "User role updated successfully."
      else
        redirect_to manage_permissions_users_path, alert: "Failed to update user role."
      end
    else
      redirect_to root_path, alert: "Unauthorized access."
    end
  end

  def manage_permissions
    @users = User.all
  end

  def show
    @user = current_user
    @snippets = @user.snippets.includes(:feedbacks)
    @received_feedbacks = @user.received_feedbacks
    @feedbacks = @user.received_feedbacks

    # Contare i follower escludendo se stesso
    @followers_count = @user.followers.where.not(id: @user.id).count

    # Contare i following escludendo se stesso
    @following_count = @user.following.where.not(id: @user.id).count
  end

  def show_following
    @user = current_user
    @following_count = @user.following.where.not(nickname: [nil, '']).count
    @following = @user.following
  end

  def show_followers
    @user = User.find(params[:id])
    @followers_users = @user.followers
    @followers_count = @followers_users.count
  end

  def profile_from_community
    @user = User.find(params[:id])
    @is_following = current_user.following?(@user)
    @snippets = @is_following ? @user.snippets : []
    @projects = @is_following ? @user.projects : []

    respond_to do |format|
      format.html  # Renderizza `profile_with_details.html.erb` per richieste HTML
    end
  end

  def profile_with_details
    @user = User.find(params[:id])
    @is_following = current_user.following?(@user)
    @snippets = @is_following ? @user.snippets : []
    @projects = @is_following ? @user.projects : []

    respond_to do |format|
      format.html  # Renderizza `profile_with_details.html.erb` per richieste HTML
    end
  end

  def profile
    @user = User.find(params[:id])
    @projects = @user.projects.where(visibility: 'public')
  end

  def leave_feedback
    @feedback = Feedback.new
  end

  def create_feedback
    @feedback = @user.received_feedbacks.new(feedback_params)
    @feedback.user = current_user

    if @feedback.save
      redirect_to user_path(@user), notice: 'Feedback sent successfully'
    else
      render :leave_feedback
    end
  end

  def edit
  end

  def drafts
    @snippets = current_user.snippets.where(draft: true)
  end


  def update
    if params[:save_as_draft]
      @snippet.draft = true
    else
      @snippet.draft = false
    end

    if @snippet.update(snippet_params)
      if params[:save_as_draft]
        redirect_to my_snippets_drafts_path, notice: 'Snippet was successfully updated as a draft.'
      else
        redirect_to snippet_path(@snippet), notice: 'Snippet was successfully updated.'
      end
    else
      render :edit
    end
  end


  def update
    if @user.update(user_params)
      handle_profile_image_update
      @user.generate_otp_secret if @user.otp_enabled_changed? && @user.otp_enabled
      @user.send_two_factor_authentication_code if @user.otp_enabled
      redirect_to authenticated_root_path, notice: 'Profile updated successfully'
    else
      render :edit
    end
  end

  def enable_two_factor_auth
    current_user.update(otp_enabled: true)
    current_user.generate_otp_secret
    current_user.send_two_factor_authentication_code
    redirect_to authenticated_root_path, notice: 'Two-Factor Authentication enabled'
  end

  def disable_two_factor_auth
    if current_user.update(otp_enabled: false, otp_secret: nil, two_factor_method: nil)
      current_user.reload
      redirect_to settings_path, notice: 'Two-Factor Authentication disabled'
    else
      redirect_to settings_path, alert: 'Failed to disable Two-Factor Authentication'
    end
  end

  def my_profile
    @snippets = current_user.snippets
  end

  def my_snippets
    @languages = Snippet.languages
    @snippets = current_user.snippets

    if params[:order_by] == 'most_recent'
      @snippets = @snippets.order(created_at: :desc)
    elsif params[:order_by] == 'least_recent'
      @snippets = @snippets.order(created_at: :asc)
    elsif params[:order_by] == 'favorites'
      @snippets = @snippets.order(favorite: :desc, created_at: :desc)
    end

    if params[:language] == 'other'
      @snippets = @snippets.where.not(language: Snippet.languages)
    elsif params[:language].present?
      @snippets = @snippets.where(language: params[:language])
    end
  end

  def follow
    if current_user.following?(@user)
      flash[:notice] = "You are already following this user."
    else
      current_user.follow(@user)
      respond_to do |format|
        format.js { render 'follows/create' }
      end
    end
  end

  def unfollow
    if current_user.following?(@user)
      current_user.unfollow(@user)
      respond_to do |format|
        format.js { render 'follows/destroy' }
      end
    else
      flash[:notice] = "You are not following this user."
      respond_to do |format|
        format.js { render 'follows/destroy' }
      end
    end
  end

  def unfollow_admin
    current_user.unfollow(@user)
    respond_to do |format|
      format.js { render 'follows/create' }
    end
  end

  private

  def set_user
    @user = params[:id] ? User.find(params[:id]) : current_user
  rescue ActiveRecord::RecordNotFound
    redirect_to authenticated_root_path, alert: 'User not found.'
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :nickname, :phone_number, :otp_enabled, :profile_image, :remove_profile_image, :role)
  end

  def handle_profile_image_update
    if params[:user][:remove_profile_image] == '1'
      @user.profile_image.purge if @user.profile_image.attached?
    end

    if params[:user][:profile_image].present?
      @user.profile_image.attach(params[:user][:profile_image])
    end
  end

  def ensure_admin
    redirect_to authenticated_root_path, alert: 'Unauthorized access.' unless current_user.admin?
  end

  def feedback_params
    params.require(:feedback).permit(:content)
  end
end
