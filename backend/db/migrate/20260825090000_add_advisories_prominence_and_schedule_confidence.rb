class AddAdvisoriesProminenceAndScheduleConfidence < ActiveRecord::Migration[8.0]
  def change
    # An operational note that fits nowhere else in the model: the sandbar is
    # only there at low tide, the last pumpboat goes at one, there is no ATM on
    # Burias, the boat back from Bugui Point is tomorrow morning.
    #
    # The whole point of this table is the line it refuses to cross. "Today's
    # 10:30 crossing still has space" is a claim about right now: it needs a
    # live feed, cannot be cached honestly, and strands someone when it goes
    # stale. "The last pumpboat goes about 13:00" answers the same question,
    # ships in the bundle, and stays true. Only the second kind has a row here.
    #
    # (The data file is data/advisories.csv. It is not called `signals`
    # because Ruby already has a core Signal module, and `S_` is the id prefix
    # for stops.)
    create_table :advisories do |t|
      t.string :external_id, null: false        # matches data/advisories.csv advisory_id

      # What the note is about. `scope_ref` holds the natural key of the thing
      # -- a place's external_id, a route's gtfs_id, an island or municipality
      # name -- and is empty for province-wide notes. Deliberately a string
      # rather than a polymorphic association: the CSV is the source of truth
      # and a note may name something that has no row yet.
      t.string :scope, null: false
      t.string :scope_ref

      t.string :kind, null: false
      # info | plan | warn -- warn is the set that can cost someone the day.
      t.string :severity, null: false, default: "info"

      t.string :headline, null: false
      t.text :detail

      # MM-DD, inclusive, wrapping across the new year (11-01 to 04-30 is the
      # dry season). Both empty means the note applies all year.
      t.string :season_from
      t.string :season_to

      t.string :confidence, null: false, default: "unknown"
      t.date :valid_as_of
      t.string :source_url

      t.timestamps
    end
    add_index :advisories, :external_id, unique: true
    add_index :advisories, [ :scope, :scope_ref ]
    add_index :advisories, :severity

    # How well known a place is -- measured as published coverage, because
    # nothing in this project counts visits. The column names say so: this
    # supports "best known on Ticao", never "most visited".
    change_table :places, bulk: true do |t|
      t.integer :prominence_rank             # 1..N province-wide, 1 = most covered
      t.string  :prominence_tier             # anchor | established | documented | sparse | unverified
      t.integer :source_count                # distinct independent published sources found
      t.string  :prominence_basis            # published_coverage (a later crowd basis sits beside it)
      t.date    :prominence_as_of
    end
    add_index :places, :prominence_rank

    # A fare already said how much to trust it. A departure time did not, and
    # that was the bigger lie -- GTFS renders 10:00:00 identically whether it
    # came from the operator or from a guess about how often a habal-habal
    # turns up. Same vocabulary as FareLeg::CONFIDENCES.
    change_table :routes, bulk: true do |t|
      t.string :schedule_confidence, null: false, default: "unknown"
      t.date   :schedule_as_of
      t.string :schedule_source
      t.text   :schedule_note
      # routes.txt carries mbtt_leg_id: which priced hop this timetable belongs
      # to. It is how a fare estimate's legs learn whether their times are real.
      t.references :fare_leg, foreign_key: true
    end
  end
end
