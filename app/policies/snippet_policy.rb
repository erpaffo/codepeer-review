class SnippetPolicy < ApplicationPolicy
  def update?
    user.moderator? || user.admin?
  end

  def destroy?
    user.moderator? || user.admin?
  end
end
