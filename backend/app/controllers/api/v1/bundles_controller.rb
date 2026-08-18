class Api::V1::BundlesController < ApplicationController
  def index
    categories = Category.all
    render json: {
      categories: categories
    }
  end
end
