class Api::V1::PlacesController < ApplicationsController
  before_action :check_if_authenticated_and_admin_response

  def index
    places = Place.all
    render json: {
      places: PlaceSerializer.many(places)
    }, status: :ok
  end

  def create
    place = Place.new
    place.assign_attributes(place_params)
    if place.save
      render json: {
        place: PlaceSerializer.one(place)
      }, status: :ok
    else 
      render json: {
        error: place.errors.full_messages 
      }, status: :unprocessable_content
    end
  end

  def update
    place = Place.find(params[:id])
  
    if place
      place.assign_attributes(place_params)
      if place.save
        render json: {
          place: PlaceSerializer.one(place)
        }, status: :ok
      else 
        render json: {
          error: place.errors.full_messages 
        }, status: :unprocessable_content
      end
    end
  end
 
  def destroy
    place = Place.find(params[:id])
    place.destroy!
    head :no_content
  end
  
  private

  def check_if_authenticated_and_admin_response
    if !check_if_authenticated_and_admin
      render json: { authenticated: false, error: "Un Authorized" }, status: :forbidden
    end  
  end

  def place_params
    params.expect(place: [:name, :description, :id, :images, :access_notes, :fare_estimates, :latitude, :longitude, :municipality, :island, :travel_time_note, :source, :access_note])
  end
end 