class ApplicationsController < ActionController::API
  include ActionController::Cookies
  # Lets serializers build absolute URLs for uploaded photos from this request's host.
  include ActiveStorage::SetCurrent

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def authenticated?
    current_user.present?
  end

  def check_if_authenticated_and_admin
    authenticated? && current_user.admin?
  end
end
