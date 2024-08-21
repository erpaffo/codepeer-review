# app/controllers/badges_controller.rb
class BadgesController < ApplicationController
  before_action :authenticate_user!

  def index
    @badges = current_user.badges
  end
end
