class Api::V1::BundlesController < ApplicationsController
  # One call that hands the frontend everything it needs to render the browse
  # screen: the category list to filter by, and every place with its own
  # categories, modes, images and costed ways in already nested.
  #
  #   GET /api/v1/bundles?from=ticao&pax=4
  #
  # `from` is where the traveller is standing, not where they are going. The
  # two used to be the same parameter, which was wrong in a way that quietly
  # broke the main journey: the island selector asks "leaving from", and the
  # controller took that answer and filtered places *to* that island, so
  # someone on Ticao could never be shown Buntod sandbar at all. Origin now
  # drives the crossing shown on each way in (see IslandConnection) and
  # `island` remains available as a genuine destination filter.
  #
  # `pax` matters because a boat hire is one price for the whole party -- the
  # per-person estimate for Sombrero Island roughly quarters between 1 and 10
  # travellers, so it cannot be precomputed.
  MAX_PAX = 20

  def index
    render json: {
      categories: CategorySerializer.many(categories),
      places: PlaceSerializer.many(
        places,
        pax: pax,
        from_island: from_island,
        connections: connections
      ),
      islands: IslandSerializer.many(islands),
      # The terminal directory, sent once and referenced by id from every leg.
      # This is what lets the UI preview a pier before someone travels to it.
      stops: StopSerializer.many(stops, with_images: true),
      advisories: AdvisorySerializer.many(advisories),
      meta: {
        pax: pax,
        # Where the traveller is. Every access chain in the data assumes an
        # origin it never states; this is what lets the API say so.
        from_island: from_island,
        island: params[:island].presence,
        currency: "PHP",
        # Every figure here is desk research, not survey. The frontend should
        # keep saying so; see each estimate's `confidence` and `oldest_source`.
        data_quality: "researched"
      }
    }
  end

  private

  def from_island
    @from_island ||= params[:from].presence || params[:island].presence
  end

  # The crossing graph, built once for the whole request. Every place gets
  # asked about it, so rebuilding it per place -- let alone per option -- would
  # be a query per option per place. It is four islands wide and a handful of
  # legs, so one load covers the bundle.
  def connections
    @connections ||= IslandConnection.new
  end

  def pax
    @pax ||= params[:pax].to_i.clamp(1, MAX_PAX)
  end

  def islands
    Island.all
  end

  def stops
    Stop.includes(:images).order(:name)
  end

  # Operational notes. The whole set for the island goes over in one go, unsorted
  # by season on purpose -- the client owns the clock and may be days offline,
  # so it decides what is in season, not the server. See Advisory.
  #
  # Scoped to where the traveller *is*: a no-sail warning or a "carry cash"
  # note is about the journey they are about to make, which starts at home.
  def advisories
    scope = Advisory.all
    scope = scope.relevant_to_island(from_island) if from_island.present?
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
      :categories, :vihicles, :stop, :images, :place_fees,
      place_access_legs: { fare_leg: [ :vihicle, :from_stop, :to_stop, :routes, :last_trips ] }
    ).order(:name)

    # Only when the caller actually asks to narrow the destinations. The
    # browse screen deliberately does not: which island a place is on is
    # something the UI tells you about, not something it hides you from.
    scope = scope.on_island(params[:island]) if params[:island].present?
    scope
  end
end
