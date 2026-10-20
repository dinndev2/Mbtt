class ApplicationsController < ActionController::API
  include ActionController::Cookies

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
