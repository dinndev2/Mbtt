# MBTT GTFS Feed

Hand-collected transit data for Masbate, in [GTFS Schedule](https://gtfs.org/documentation/schedule/reference/)
format. The files here are the source of truth; the Rails backend imports from
them (see [Importing](#importing)).

Each `.txt` file is a plain CSV with a header row already in place. Fill in rows
below the header — don't rename or reorder columns.

## Rules that apply to every file

- **UTF-8, comma-separated, no BOM.** Quote a value with `"` only if it contains
  a comma, quote, or newline (e.g. `"Poblacion, Mobo"`).
- **No blank lines**, and no trailing comma at the end of a row.
- **Every column stays present** even when the value is empty — an empty
  optional field is written as nothing between two commas (`,,`).
- **IDs are case-sensitive** and must match exactly across files. Stick to the
  naming convention below so cross-references stay readable.
- **Dates** are `YYYYMMDD` (`20260901`). **Times** are `HH:MM:SS` on a 24-hour
  clock (`05:30:00`). A time past midnight on the same service day keeps
  counting up: `24:15:00`, not `00:15:00`.
- **Coordinates** are decimal degrees, WGS 84, 5–6 decimal places
  (`12.37050,123.62280`). Masbate City sits near `12.37, 123.62` — a
  latitude/longitude that isn't in that neighbourhood is probably swapped.

### ID naming convention

| Kind | Pattern | Example |
| --- | --- | --- |
| Agency | `AG_<slug>` | `AG_MBTT` |
| Stop | `S_<slug>` | `S_MASBATE_PORT` |
| Route | `R_<mode>_<origin>_<dest>` | `R_JEEP_MASBATE_MOBO` |
| Trip | `<route_id>_<service>_<nn>` | `R_JEEP_MASBATE_MOBO_WD_01` |
| Service | `WD` / `WE` / `DAILY` | `DAILY` |
| Fare | `F_<mode>_<qualifier>` | `F_TRIKE_INCITY` |
| Shape | `SH_<route slug>` | `SH_MASBATE_MOBO` |

## Files

### `agency.txt` — who operates the service

One row per operator. If a mode has no formal operator (habal-habal drivers, most
tricycle lines), create one umbrella agency for it rather than leaving it blank —
`agency_id` is required by every route.

| Column | Required | Notes |
| --- | --- | --- |
| `agency_id` | yes | Referenced by `routes.agency_id`. |
| `agency_name` | yes | Public-facing name. |
| `agency_url` | yes | Full URL with scheme. Use the project site if the operator has none. |
| `agency_timezone` | yes | Always `Asia/Manila`. |
| `agency_lang` | no | `en` or `fil`. |
| `agency_phone` | no | Dispatcher or terminal number if one exists. |
| `agency_email` | no | |

```csv
AG_MBTT,Masbate City Tricycle Operators,https://example.org/mbtt,Asia/Manila,en,,
```

### `stops.txt` — terminals, stands, ports, landmarks

One row per place a passenger can board or alight. For informal modes this is
usually a terminal, a waiting shed, or a known landmark corner.

| Column | Required | Notes |
| --- | --- | --- |
| `stop_id` | yes | |
| `stop_code` | no | Short code shown to passengers, if any. |
| `stop_name` | yes | What a local would call it out loud. |
| `stop_desc` | no | Landmark hint — "across the public market". Don't repeat the name. |
| `stop_lat` / `stop_lon` | yes | See coordinate rules above. |
| `zone_id` | no | Fare zone. Needed only if you use zone-based fares in `fare_rules.txt`. |
| `location_type` | no | Empty or `0` = stop. `1` = station (a terminal containing several boarding bays). |
| `parent_station` | no | The `stop_id` of the enclosing station, when `location_type` is empty/`0`. |
| `wheelchair_boarding` | no | `0` unknown, `1` possible, `2` not possible. |
| `mbtt_coord_precision` | project extension | `exact`, `town_centroid` or `estimated` — how much to trust the pin. |

```csv
S_MASBATE_PORT,,Masbate Port,Ferry terminal beside the wharf,12.37340,123.62630,Z_CITY,0,,0
```

### `routes.txt` — a named service pattern

One row per route, not per vehicle and not per departure.

| Column | Required | Notes |
| --- | --- | --- |
| `route_id` | yes | |
| `agency_id` | yes here | Must match `agency.txt`. |
| `route_short_name` | one of the two | The number/code painted on the vehicle, if any. |
| `route_long_name` | one of the two | `Origin – Destination`. Fill this one if there's no code. |
| `route_desc` | no | Free text: what riders should know. |
| `route_type` | yes | See the mode table below. |
| `route_color` / `route_text_color` | no | 6-digit hex, **no** `#` (`0F7B4A`). |
| `mbtt_mode` | project extension | Plain mode word, matches a `vihicles.name` row. |
| `mbtt_leg_id` | project extension | The `leg_id` in `../fare_legs.csv` this route is priced by. |
| `mbtt_schedule_confidence` | project extension | How far to trust the timetable. Same five values as a fare's `confidence`. |
| `mbtt_schedule_as_of` | project extension | Date the timetable was last checked against a source. |
| `mbtt_schedule_source` | project extension | Where the timetable came from. Empty means nowhere — it was invented. |
| `mbtt_schedule_note` | project extension | What is wrong with it, in words. |

`mbtt_mode` is not part of the GTFS spec — it's an extra column so the app can
show the right vehicle icon and fare logic. Validators will flag it as unknown;
that's expected and harmless.

#### Schedule confidence

A fare in this dataset already says how much to trust it. A departure time did
not, and that was the bigger lie: GTFS renders `10:00:00` identically whether it
came from the operator or from someone's guess about how often a habal-habal
turns up. `mbtt_schedule_confidence` closes that gap using the same vocabulary
as `fare_legs.csv`, so one rule covers both.

| Value | Means | Count |
| --- | --- | --- |
| `published` | From the operator | 0 |
| `reported` | Recent listing or travel writing, corroborated | 3 |
| `estimate` | Operating window is plausible, the headway is invented | 14 |
| `stale` | Real once, and a newer source now contradicts the feed | 3 |
| `unknown` | Nothing published, or nothing in the feed to schedule | 2 |

Nothing in this feed is `published`. Every ferry time here comes from a booking
aggregator or a blog, not from Montenegro, Barrun or Kho.

Three things the confidence pass turned up that are worth fixing before they
reach a screen:

- **`R_RORO_MSB_PILAR` has no Masbate → Pilar direction.** Five trips, all
  inbound. The feed cannot route anyone *off* the island on the main gateway
  route. The May 2026 listing has Masbate departing 08:00, 10:00, 12:00 and
  16:00; the five inbound times in the feed match no published source either.
- **`R_FC_MSB_PILAR` has no trips at all.** Route row and fare leg exist,
  nothing schedulable against them.
- **`R_PUMP_MSB_LAGUNDI` runs three hours too late.** The feed keeps pumpboats
  going to 16:00; the only published account puts the last one off the Fish Port
  at about 13:00. This is the failure mode that strands someone.

**Mode → `route_type`**

| Local mode | `route_type` | `mbtt_mode` |
| --- | --- | --- |
| Bus | `3` | `Bus` |
| Mini jeep / jeepney | `3` | `Mini Jeep` |
| Van (UV Express) | `3` | `Van` |
| Tricycle | `3` | `Tricycle` |
| Habal-habal | `3` | `Motorcycle` |
| Ferry / RORO / pumpboat | `4` | `Ferry` |

GTFS has no code for tricycle or habal-habal, so they ride under `3` (bus) and
are distinguished by `mbtt_mode`. Keep `route_type` to these standard values —
extended route types break some consumers.

```csv
R_JEEP_MASBATE_MOBO,AG_MBTT,,Masbate City – Mobo,Loads at the public market until full,3,0F7B4A,FFFFFF,Mini Jeep
```

### `calendar.txt` — which days a service runs

One row per service pattern, reused by many trips. Most of Masbate needs only two
or three rows total.

`monday`–`sunday` are `1` (runs) or `0` (doesn't). `start_date`/`end_date` bound
the whole feed's validity — set them to the survey period you're confident about,
not to a date far in the future.

```csv
DAILY,1,1,1,1,1,1,1,20260901,20270831
WD,1,1,1,1,1,0,0,20260901,20270831
```

### `calendar_dates.txt` — holiday and fiesta exceptions

Only for days that break the `calendar.txt` pattern. `exception_type` is `1`
(service added on this date) or `2` (service removed). Leave the file empty
except for the header if you have no exceptions yet.

```csv
WD,20261101,2
```

### `trips.txt` — one departure, or one representative run

For fixed-schedule modes (bus, ferry, van) create one trip per scheduled
departure. For load-and-go modes (tricycle, habal, most jeeps) create **one**
representative trip per route per service pattern, then describe how often it
runs in `frequencies.txt`.

| Column | Required | Notes |
| --- | --- | --- |
| `route_id` | yes | Matches `routes.txt`. |
| `service_id` | yes | Matches `calendar.txt` or `calendar_dates.txt`. |
| `trip_id` | yes | |
| `trip_headsign` | no | Destination as shown/shouted to riders. |
| `direction_id` | no | `0` outbound, `1` inbound. Pick one direction as `0` and be consistent for that route. |
| `shape_id` | no | Matches `shapes.txt`. Leave empty until you have a traced path. |

```csv
R_JEEP_MASBATE_MOBO,DAILY,R_JEEP_MASBATE_MOBO_DAILY_01,Mobo,0,SH_MASBATE_MOBO
```

### `stop_times.txt` — the stops of each trip, in order

The largest file. Every trip needs at least two rows.

| Column | Required | Notes |
| --- | --- | --- |
| `trip_id` | yes | |
| `arrival_time` / `departure_time` | first and last stop | May be empty at intermediate stops — set `timepoint` to `0` there. |
| `stop_id` | yes | |
| `stop_sequence` | yes | Increasing along the trip. Use `10, 20, 30…` so you can insert stops later without renumbering. |
| `pickup_type` / `drop_off_type` | no | `0` normal, `1` none, `2` phone ahead, `3` flag down / arrange with driver. Use `3` for hail-anywhere segments. |
| `timepoint` | no | `1` the time is exact, `0` it's approximate. Be honest — most surveyed times are `0`. |
| `shape_dist_traveled` | no | Km from the start of the trip along `shapes.txt`. Powers the distance shown in the app. |

For a frequency-based trip the actual clock times don't matter, but the
*differences* between them do — they define how long each leg takes. Start at a
round time and lay out realistic travel times from there.

```csv
R_JEEP_MASBATE_MOBO_DAILY_01,06:00:00,06:00:00,S_MASBATE_TERMINAL,10,0,0,1,0.0
R_JEEP_MASBATE_MOBO_DAILY_01,06:25:00,06:25:00,S_MOBO_POB,20,0,0,0,9.4
```

### `frequencies.txt` — headway instead of a timetable

This is the file that makes informal transport work in GTFS. One row says
"between these hours, a vehicle leaves roughly every N seconds".

| Column | Required | Notes |
| --- | --- | --- |
| `trip_id` | yes | The representative trip from `trips.txt`. |
| `start_time` / `end_time` | yes | The window the headway applies to — effectively the operating hours. |
| `headway_secs` | yes | Typical wait between departures. `600` = 10 min, `1800` = 30 min. |
| `exact_times` | no | `0` = vehicles leave when full, no fixed clock (use this for tricycle, habal, jeep). `1` = departures land on an exact repeating schedule. |

Split the day into rows when the wait changes: a dense morning window and a
sparse midday one are two rows for the same trip. Windows must not overlap.

```csv
R_JEEP_MASBATE_MOBO_DAILY_01,05:00:00,08:00:00,900,0
R_JEEP_MASBATE_MOBO_DAILY_01,08:00:00,18:00:00,1800,0
```

### `fare_attributes.txt` + `fare_rules.txt` — what it costs

`fare_attributes.txt` defines a price; `fare_rules.txt` says where that price
applies.

| `fare_attributes` column | Notes |
| --- | --- |
| `fare_id` | |
| `price` | Decimal, no currency symbol (`15.00`). |
| `currency_type` | Always `PHP`. |
| `payment_method` | `0` pay on board, `1` pay before boarding (ferry tickets, terminal booths). |
| `transfers` | `0` none allowed, `1` one, `2` two, empty = unlimited. Almost always `0` here. |
| `agency_id` | Fill it in — the feed has multiple agencies. |
| `transfer_duration` | Seconds a transfer stays valid. Usually empty. |

In `fare_rules.txt`, fill `route_id` for a flat per-route fare, or
`origin_id`/`destination_id` (which hold **`zone_id`** values from `stops.txt`,
not stop ids) for zone-to-zone pricing. Leave the columns you don't use empty.

Negotiated fares (habal-habal, special trips) have no single true price. Record
the common minimum as the fare and put the range in `routes.route_desc`.

```csv
# fare_attributes.txt
F_JEEP_MASBATE_MOBO,25.00,PHP,0,0,AG_MBTT,

# fare_rules.txt
F_JEEP_MASBATE_MOBO,R_JEEP_MASBATE_MOBO,,,
```

### `shapes.txt` — the drawn path of a route

Optional, and the most tedious to collect — skip it until routes and times are
solid. Points are ordered by `shape_pt_sequence` along the direction of travel;
`shape_dist_traveled` is cumulative km from the first point and must match the
units used in `stop_times.txt`.

```csv
SH_MASBATE_MOBO,12.37050,123.62280,1,0.0
SH_MASBATE_MOBO,12.36510,123.63140,2,1.2
```

### `feed_info.txt` — about this dataset

A single row.

| Column | Notes |
| --- | --- |
| `feed_publisher_name` | `MBTT`. |
| `feed_publisher_url` | Project URL, required with a scheme. |
| `feed_lang` | `en`. |
| `feed_start_date` / `feed_end_date` | Should agree with `calendar.txt`. |
| `feed_version` | Bump on every published change — dated is easiest: `2026-09-01`. |
| `feed_contact_email` | |

## Suggested fill-in order

Each step only references the ones before it, so nothing dangles:

1. `agency.txt` — a couple of rows, done once.
2. `stops.txt` — every terminal and landmark you know. Do this in bulk.
3. `routes.txt` — one row per origin–destination–mode combination.
4. `calendar.txt` — `DAILY`, and `WD`/`WE` only if service really differs.
5. `trips.txt` — one representative trip per route to start.
6. `stop_times.txt` — at minimum the first and last stop of each trip.
7. `frequencies.txt` — operating hours and typical wait, per trip.
8. `fare_attributes.txt` / `fare_rules.txt` — prices.
9. `shapes.txt`, `calendar_dates.txt` — later, when the basics are stable.

Steps 1–7 already produce a valid feed. Partial data is fine; wrong data isn't —
leave an optional field empty rather than guessing at it.

## Validating

Run the [MobilityData GTFS validator](https://github.com/MobilityData/gtfs-validator)
against the folder before committing a batch:

```sh
zip -j -r mbtt-gtfs.zip data/gtfs/*.txt
java -jar gtfs-validator.jar -i mbtt-gtfs.zip -o /tmp/gtfs-report
```

Expect `unknown_column` notices for `routes.mbtt_mode`, `routes.mbtt_leg_id`
and `stops.mbtt_coord_precision`. Anything at ERROR level needs fixing.

## Importing

The backend schema now mirrors these files one table per file — `agencies`,
`stops`, `routes`, `services`, `service_exceptions`, `trips`, `stop_times`,
`frequencies`, `fares`, `fare_rules` — each keeping the feed's own identifier in
a unique `gtfs_id` column. `routes.mbtt_mode` maps to a `vihicles` row via its
`slug`. See [DATA_MODEL.md](../../docs/DATA_MODEL.md).

`db/seeds.rb` imports `stops.txt` (upserting on `gtfs_id`) along with the
research CSVs in the parent directory. The remaining files — routes, trips,
stop_times, frequencies, fares — still have no importer; their tables exist and
are exercised by the worked example in the seeds. `shapes.txt` has no table
behind it.

## Provenance and confidence

Everything in these files is desk research collected 20 August 2026 — ferry
operator listings, LGU rates, travel blogs, Wikipedia — not survey. Treat it as
a starting point to verify. The feed is internally consistent (every id
resolves, every trip has ordered stop_times) but "consistent" is not "true".

What that means per file:

- **`stops.txt`** — 32 stops, all with coordinates. The project extension
  `mbtt_coord_precision` says how good each one is: `town_centroid` (the
  municipality centre, from OpenStreetMap — right town, wrong pin) or
  `estimated` (a jump-off or landing inferred from its nearest town). None are
  surveyed. They are good enough to draw a map and not good enough to navigate.
- **`routes.txt`** — 22 routes. Endpoints are reliable. `mbtt_leg_id` links
  each route to its row in `../fare_legs.csv`.
- **`trips.txt` / `stop_times.txt`** — 45 trips. The Masbate–Lagundi,
  Bulan–San Jacinto, Pasacao–San Pascual and Pilar–Masbate crossings have real
  published departure times. Load-and-go modes get one representative trip each,
  described by `frequencies.txt`.
- **`frequencies.txt`** — 16 rows. Operating windows are plausible; **the
  headways are guesses** and should be the first thing a surveyor replaces.
  `exact_times` is `0` throughout, which is honest — nothing here leaves on a
  fixed clock.
- **`fare_attributes.txt` / `fare_rules.txt`** — 19 fares, generated from the
  per-rider subset of `../fare_legs.csv`. The other 14 legs — boat charter,
  negotiated habal-habal, distance bands, and legs with no published price —
  have no GTFS representation at all. See [../README.md](../README.md).
- **`calendar.txt`** — one `DAILY` service. No route here is known to vary by
  day of week, which is an absence of evidence rather than evidence of absence.
- **`shapes.txt`, `calendar_dates.txt`** — still empty.

`../places.csv` holds the tourist destinations, with `../place_access.csv`,
`../fare_legs.csv` and `../place_fees.csv` describing how to reach each one and
what it costs. Those are not GTFS files — GTFS has no concept of a destination —
and they feed the app's own tables. See [../README.md](../README.md) for the
fare model and for what to verify first.
