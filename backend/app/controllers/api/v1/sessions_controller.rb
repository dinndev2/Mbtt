class Api::V1::SessionsController < ApplicationsController
  def show
    if current_user
      render json: {
        id: current_user.id,
        email: current_user.email,
        name: current_user.name
      }, status: :ok
    else
      render json: { authenticated: false, error: "Un Authorized" }, status: :unauthorized
    end
  end

  def create
    user = User.find_by(email: params[:email])
    if user && user.authenticate(params[:password])
      reset_session
      session[:user_id] = user.id
      render json: {
        id: user.id,
        email: user.email,
        name: user.name
      }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def destroy
    reset_session
    head :no_content
  end
end