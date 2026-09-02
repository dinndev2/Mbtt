class Api::V1::BundlesController < ApplicationController
  # One call that hands the frontend everything it needs to render the browse
  # screen: the category list to filter by, and every place with its own
  # categories, modes, images and costed ways in already nested.
  #
  #   GET /api/v1/bundles?island=masbate&pax=4
  #
  # `pax` matters because a boat hire is one price for the whole party -- the
  # per-person estimate for Sombrero Island roughly quarters between 1 and 10
  # travellers, so it cannot be precomputed.
  MAX_PAX = 20

  def index
    render json: {
      categories: CategorySerializer.many(categories),
      places: PlaceSerializer.many(places, pax: pax),
      islands: IslandSerializer.many(islands),
      advisories: AdvisorySerializer.many(advisories),
      meta: {
        pax: pax,
        island: params[:island].presence,
        currency: "PHP",
        # Every figure here is desk research, not survey. The frontend should
        # keep saying so; see each estimate's `confidence` and `oldest_source`.
        data_quality: "researched"
      }
    }
  end

  private

  def pax
    @pax ||= params[:pax].to_i.clamp(1, MAX_PAX)
  end

  def islands
    Island.all
  end

  # Operational notes. The whole set for the island goes over in one go, unsorted
  # by season on purpose -- the client owns the clock and may be days offline,
  # so it decides what is in season, not the server. See Advisory.
  def advisories
    scope = Advisory.all
    scope = scope.relevant_to_island(params[:island]) if params[:island].present?
    scope.by_urgency
  end

  def categories
    Category.order(:name)
  end

  # `includes` is what keeps the nesting from turning into an N+1. The fare
  # estimate walks access legs, their stops and modes, and the place's fees,
  # so all of that has to be preloaded too.
  def places
    scope = Place.includes(
      :categories, :vihicles, :stop, :place_images, :place_fees,
      place_access_legs: { fare_leg: [ :vihicle, :from_stop, :to_stop, :routes ] }
    ).order(:name)

    # The frontend sends "masbate"; the column holds "Masbate".
    scope = scope.on_island(params[:island]) if params[:island].present?
    scope
  end
end
