class SessionsController < Devise::SessionsController
  def create
    super
  end

  protected

  def auth_options
    { scope: resource_name, recall: "page#home" }
  end
end
