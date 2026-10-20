class Api::V1::PlacesController < ApplicationsController
  before_action :check_if_authenticated_and_admin_response

  def index
    places = Place.all
    render json: {
      places: PlaceSerializer.many(places)
    }, status: :ok
  end
  
  
  private
  def check_if_authenticated_and_admin_response
    if !check_if_authenticated_and_admin
      render json: { authenticated: false, error: "Un Authorized" }, status: :forbidden
    end 
  end
end 