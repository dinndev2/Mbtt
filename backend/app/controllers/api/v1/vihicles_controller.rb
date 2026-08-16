class Api::V1::VihiclesController < ApplicationController
  def vihicles 
    vihicles = Vihicle.all

    render json: vihicles
  end
end
