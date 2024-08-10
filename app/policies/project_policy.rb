class ProjectPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.present?
  end

  def update?
    user.present? && (user == record.user || record.collaborators.exists?(user: user, permissions: 'full'))
  end

  def destroy?
    user.present? && (user == record.user || record.collaborators.exists?(user: user, permissions: 'full'))
  end
end
