json.data do
  json.array! @places do |place|
    json.partial! 'api/v1/bundles/place', place: place
  end
end

# json.meta do
#   json.total @products.total_count
#   json.page params[:page].to_i
# end