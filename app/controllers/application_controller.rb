class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  allow_browser versions: :modern
  protect_from_forgery with: :exception

  def after_sign_in_path_for(resource)
    welcome_path
  end

  private

  def user_not_authorized
    flash[:alert] = "Keine Berechtigung."
    redirect_back(fallback_location: root_path)
  end

  protected
    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [ :user_name, :email, :password ])
      devise_parameter_sanitizer.permit(:account_update, keys: [ :user_name, :email, :password, :current_password ])
    end
end
