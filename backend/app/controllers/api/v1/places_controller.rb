class Api::V1::PlacesController < ApplicationsController
  before_action :check_if_authenticated_and_admin_response

  def index
    places = Place.all
    render json: {
      places: PlaceSerializer.many(places)
    }, status: :ok
  end

  def update
    place = Place.find(params[:id])
      
    if place
      if place.assign_attributes(place_params)
      end
    end
  end
  
  
  private

  def check_if_authenticated_and_admin_response
    if !check_if_authenticated_and_admin
      render json: { authenticated: false, error: "Un Authorized" }, status: :forbidden
    end  
  end

  def place_params
    params.expect(place: [:name, :description, :id, :images, :access_notes, :fare_estimates])
  end
end 