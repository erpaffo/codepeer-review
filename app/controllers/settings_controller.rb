class SettingsController < ApplicationController
  def index
  end

private

  def set_user
    @user = current_user
  end

end
