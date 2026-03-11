class InvoicePolicy < ApplicationPolicy
  def index?   = true
  def show?    = owner?
  def new?     = true
  def create?  = true
  def edit?    = owner?
  def update?  = owner?
  def destroy? = owner?

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end

  def download_pdf?
    owner?
  end

  private

  def owner?
    record.user == user
  end
end
