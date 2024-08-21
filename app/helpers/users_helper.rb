module UsersHelper

  def followed_by_current_user?(user)
    current_user.following?(user)
  end

end
