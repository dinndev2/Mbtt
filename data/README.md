# MBTT research data

Everything here is **desk research** — ferry operator listings, LGU rate sheets
and travel blogs — collected 20 August 2026. None of it is surveyed. It is
shaped to be corrected in place: fix a number in the CSV, re-run `bin/rails
db:seed`, and the API changes.

`gtfs/` holds the transit feed. The files described below sit alongside it
because GTFS cannot express most of how Masbate actually charges for travel.

The idea is to get a quick information about the place the user wants to with a few clicks even offline.

## Why the fares don't live in GTFS

`fare_attributes.txt` carries exactly one thing: a flat price per rider. That
covers 19 of the 33 legs in this dataset. The other 14 are the ones that matter
most to a traveller:

| What it is | Example | Why GTFS can't hold it |
| --- | --- | --- |
| Boat charter | Burias island hopping, ₱3,000–4,000 | Priced per boat, not per rider |
| Negotiated | Lagundi → Monreal habal-habal, ₱300–500 | No single true price |
| Distance band | Provincial bus, ₱40–200 | A range, not a figure |
| Unpriced | Mobo → Claveria RoRo | Nothing published |

So `fare_legs.csv` is the source of truth for cost, and the GTFS fare files are
generated from the subset it can represent.

## The files

### `fare_legs.csv` — one priceable hop

The unit of cost. Three columns do the real work:

- **`basis`** — `per_person`, `per_boat` or `per_vehicle`. Decides whether the
  app divides the amount by the party size. This is the whole reason the data
  is computable: a ₱4,000 boat is ₱4,000 for a solo traveller and ₱400 each for
  ten.
- **`covers_pax`** — how many riders one unit covers. Six people needing a
  second four-seater pay for two boats, not 1.5.
- **`fare_kind`** — `ticket` (fixed published price), `range` (distance band),
  `negotiated` (haggled; the band is what people report paying), `hire` (whole
  vehicle).

Plus **`confidence`** and **`valid_as_of`**, which say how much to trust the
number:

| `confidence` | Meaning |
| --- | --- |
| `published` | From the operator, the LGU, or MARINA's route register |
| `reported` | Recent travel writing |
| `estimate` | Inferred from a comparable leg — flagged in `notes` |
| `stale` | A real figure, but years old |
| `unknown` | Route exists, no price found. `amount_min_php` is empty |

Leave an amount empty rather than guessing. An empty amount makes the estimate
`complete: false`, which the UI shows as "from ₱X" instead of a total.

**`to_label`** — where the leg actually lands, in words. `to_stop_id` is empty
for six legs and always will be: a provincial bus fare is a distance band with
no single destination, a habal-habal goes wherever you point it, and an
island-hopping charter is a circuit that ends where it started. Those legs still
have to render, so every leg carries a readable destination whether or not a
stop id exists.

#### Schedule columns — when the hop runs

Departure times were researched separately from fares and are dated separately,
because the two go stale at different speeds: a ferry timetable changes when the
operator reshuffles vessels, a fare when fuel moves. `schedule_confidence`,
`schedule_as_of`, `schedule_source` and `schedule_note` therefore mirror
`confidence`/`valid_as_of`/`source_url`/`notes` rather than reusing them — a leg
can have a trustworthy 2026 timetable attached to a 2018 fare, and
`L_PUMP_MSB_LAGUNDI` is exactly that.

**`schedule_kind`** decides which of the remaining columns are filled:

| `schedule_kind` | Means | Columns used |
| --- | --- | --- |
| `departures` | A real timetable you can read off | `departures_out`, `departures_back` |
| `window` | Operating hours and a typical wait — the only truthful schedule for a vehicle that leaves when it fills up | `service_start`, `service_end`, `headway_min` |
| `on_demand` | Arranged on the spot: a chartered boat, a haggled habal-habal. The hours bound when it is possible at all | `service_start`, `service_end` |
| `unknown` | Nothing published. One leg, `L_RORO_MOBO_CLAVERIA` | none |

These columns are now **loaded into the `fare_legs` table and served on the
API**, rather than only feeding the GTFS generation. That is deliberate: the
verify list below has the feed contradicted in both directions on
`R_RORO_MSB_PILAR` and running three hours late on `R_PUMP_MSB_LAGUNDI`, so the
research CSV is the better source. `departures_back` matters most of all — it
is the direction a traveller crossing *towards* Masbate City rides, and the
direction the feed does not carry at all on the main gateway route.

`departures_out` runs `from_stop_id` → `to_stop_id`; `departures_back` is the
return. Both are `HH:MM` on a 24-hour clock, semicolon-separated, earliest
first. **The return matters as much as the outbound** — it is what decides
whether a place is a day trip or an overnight, and four of the `warn` advisories
exist because someone missed a last boat.

**This used to say nothing here was `published`. That is no longer true.**
MARINA's Philippine Nautical Highway Matrix — the national maritime
regulator's own route register — carries authorised fares, certified crossing
times and full timetables for four of these legs, and it settled the main
gateway route in both directions. Everything else still came from a booking
aggregator or a travel blog, never from Montenegro, Barrun, Kho or Starhorse
directly, so `reported` remains the ceiling for those. `estimate` on a land route means the operating window
is what travellers describe and the headway is inferred — no Masbate bus, van,
jeep or tricycle publishes a timetable anywhere, and that is a finding, not a
gap waiting on more searching.

### `place_access.csv` — the chain of legs to a place

`option` groups legs into **alternative** routes, not consecutive steps. Option
A for Sombrero Island is the Pasacao ferry then a boat hire; option B is the
Masbate City RoRo, a van, then the same boat hire. `seq` orders the steps
*within* one option.

**Every chain here starts from an origin the file never states.** Most begin at
Masbate City; the Burias circuit begins at Pasacao on the mainland. There is no
column for it and there does not need to be — the origin is the island of the
first leg's `from_stop_id`, which `stops.txt` now records. See
[Where the traveller is](#where-the-traveller-is), which is what stops a chain
being read literally and sending a Ticao local to a Ticao waterfall by way of
Masbate City and back.

### `last_trips.csv` — the last service of the day

The figure that decides whether a place is a day trip. Collected, never
inferred from a service window. See [The last trip home](#the-last-trip-home).

### `stops.csv` — what is at each terminal

A sidecar to `gtfs/stops.txt`, holding what a traveller would want to preview
before travelling to a pier. Two of its fields decide whether a crossing is
possible at all. See [the section below](#stopscsv--what-is-actually-at-a-terminal).

### `place_fees.csv` — entrance, environmental and docking charges

Not transport, but on the same bill. Same `basis`/`covers_pax` rules — a ₱300
docking fee is charged to the boat, so it splits. `required = 0` marks optional
extras (guide, snorkel gear, tent) that stay out of the base estimate.

### `places.csv` — the destinations

`coord_status` is the honest bit:

| Value | Count | Meaning |
| --- | --- | --- |
| `verified` | 2 | Cross-checked against two authoritative sources |
| `web_sourced` | 4 | A coordinate someone published |
| `town_centroid` | 27 | The municipality centre — right town, wrong pin |

Most places are `town_centroid`. They map to roughly the right place and are
useless for navigation. The API exposes this as `coordinates_approximate`.

### `advisories.csv` — operational notes that fit nowhere else

The things a local would tell you that no fare table can hold: that the sandbar
is only there at low tide, that the last pumpboat off Ticao goes at one in the
afternoon, that there is no ATM on Burias, that the boat back from Bugui Point
is tomorrow morning. Thirty-three rows, all hand-written from research on
24 August 2026.

Named advisories rather than signals because Ruby already has a core `Signal`
module and the Rails model could not use the word.

This file exists because of a distinction worth keeping: a claim about **now**
("the 10:30 crossing still has space") needs a live feed and cannot survive
offline, but a claim about **how things usually are** ("boats leave when full,
last one about 13:00") answers the same question, ships in the bundle, and stays
true. Everything here is the second kind.

| Column | Notes |
| --- | --- |
| `advisory_id` | `A_<slug>`. Not `S_` — that prefix belongs to stops. |
| `scope` / `scope_ref` | What it applies to: `province` (ref empty), `island`, `municipality`, `place` (a `place_id`), `route` (a `route_id`), `leg` (a `leg_id`). |
| `kind` | `season`, `tide`, `last_departure`, `cash`, `permit`, `fee`, `safety`, `connectivity`, `access`, `event`, `disruption`. |
| `severity` | `info` worth knowing · `plan` changes what you book · `warn` could cost you the day or strand you. |
| `headline` | One line. This is the whole signal on a small screen. |
| `detail` | The rest, including the figures. |
| `season_from` / `season_to` | `MM-DD`, inclusive, wrapping across the new year. Empty means all year. |
| `confidence`, `valid_as_of`, `source_url` | Same meaning as in `fare_legs.csv`. |

Nine rows are `warn`. Those are the ones that strand people:

- Rough seas cancel crossings the same day, province-wide, with no notice.
- The last pumpboat off Ticao is early afternoon, not late.
- There is no same-day public boat back from Bugui Point — the return is 06:00
  tomorrow.
- Nothing at all is sold on the Burias islets, and there is no ATM to fix it.

Served on the bundle as `advisories`, already scoped to the island when the
request carries one and sorted warn first. Season is *not* evaluated
server-side: the client owns the clock and may be days offline, so the payload
carries `season_from`/`season_to` and the client decides. `isInSeason()` in the
frontend and `Advisory#in_season?` in Rails implement the same wrap rule.

### `places.csv` prominence — how well known, honestly measured

The app wants to say "best known on Ticao". It cannot say "most visited",
because nothing here counts visits. So the columns measure the thing that was
actually measurable — **how much independent published coverage a place has** —
and are named for that.

| Column | Notes |
| --- | --- |
| `prominence_rank` | 1–33 across the province, 1 = most covered. Filter by island for a per-island ranking. |
| `prominence_tier` | `anchor` (8) · `established` (7) · `documented` (4) · `sparse` (8) · `unverified` (6). |
| `source_count` | Distinct independently-authored published sources found for that place. |
| `prominence_basis` | `published_coverage` for every row. The column exists so a later crowd or telemetry basis can sit beside it rather than overwrite it. |
| `prominence_as_of` | `2026-08-24` for every row. |

Counted: travel writing, news, Wikipedia, Lonely Planet, LGU and provincial
tourism pages, dive press, a place's own TripAdvisor page. Not counted:
AI-generated listicles, aggregator stubs, Pinterest, Instagram location pages,
Facebook posts.

The top of the list, and why:

| Rank | Place | Island | Evidence |
| --- | --- | --- | --- |
| 1 | Buntod Reef sandbar | Masbate | 33 TripAdvisor reviews — the highest in the province — plus 11 sources |
| 2 | Sombrero Island | Burias | The headline of every Burias itinerary; 12 sources |
| 3 | Animasola Island | Burias | Own Wikipedia article and TripAdvisor page |
| 4 | Catandayagan Falls | Ticao | 10 sources; the set piece of Ticao travel writing |
| 5 | Manta Bowl Shoal | Ticao | International dive press; inside a named Important Shark and Ray Area |

**What "best known on Ticao" resolves to: Catandayagan Falls.** Not the manta
rays, which are better known abroad than on the island, and not Bongsanglay,
which has a Wikipedia article and almost no travel writing.

The bottom is the more useful half. Six places are `unverified`. Four of them —
Burabod Spring, the San Jacinto cannons, the old houses of Monreal, San Jacinto
Water Park — appear in exactly one source, a tourism-potential study, and
nowhere else. Gawas Beach has a Wikimedia photograph and a passing Wikipedia
mention. Aroroy Lighthouse has one listicle and is probably not a real second
lighthouse at all. The app should not put any of them in front of someone as a
destination until they are confirmed.

### `place_images.csv` — bundled photos

14 images over 8 of 33 places, in `frontend/public/images/places/`, 4.7 MB
total at 1200px. All are Wikimedia Commons files under CC BY-SA — see
[ATTRIBUTION.md](./ATTRIBUTION.md). **Displaying the credit is a licence
condition**, which is why `credit` is a field on the API response rather than
something the frontend may skip.

The other 25 places have no image because nothing openly licensed exists for
them. Travel-blog photos are copyrighted; bundling them offline would be
redistribution.

### `stop_images.csv` — bundled photos of the stops

10 images over 6 of 34 stops, in `frontend/public/images/stops/`, 2.3 MB
total at 1200px. Commons only, all CC BY-SA — see section 4 of
[ATTRIBUTION.md](./ATTRIBUTION.md). Flickr was searched as a second source
through Openverse on 2026-10-02 and added nothing — section 5 lists what came
back instead. The columns are the `place_images.csv` ones
plus `caption`, one plain sentence saying what the photo shows. It says so
when the photo is the town rather than the pier, because a traveller uses it
to recognise where to stand.

The six are Masbate City Port, Buntod Sandbar, San Pascual Poblacion, San
Pascual Port, Pio Duran Port and Pasacao Port. The other 28 have none: either
Commons has nothing for them, or what it has is a map, a flag, a
2020 earthquake-damage report, or a different town. Openverse's Flickr index
has even less: namesakes elsewhere (Mobo in Aklan, Claveria in Cagayan, Masbat
in Egypt) and museum specimens. A port stop only gets a
photo of the port. A town-centre photo counts only for a `Poblacion` stop.

Seeded into the same `images` table as place photos - `Image` is polymorphic
(`imageable` is a Place or a Stop) - and served as `images` on each entry of
the bundle's `stops` directory, with `caption` alongside `credit`. Stops
nested under a place or a transfer do not repeat them.

## Where the traveller is

A chain answers "how do I get there from the usual starting point". It cannot
answer "how do I get there from here", and those differ for anyone not standing
in Masbate City. The island selector asks **"leaving from"**, so the app needs
both halves.

### `gtfs/stops.txt` — the `mbtt_island` extension

Each stop now records which island it is on, alongside the existing
`mbtt_coord_precision`. The value is derived from `zone_id`, which was already
drawn along municipality lines, and no municipality straddles two islands — so
it is a lookup, not a judgement call.

| Island | Stops | Note |
| --- | --- | --- |
| Masbate | 20 | Ten municipality zones, plus the Bugui Point landing |
| Ticao | 6 | `Z_TICAO` |
| Burias | 3 | `Z_BURIAS` |
| Luzon | 5 | Pilar and Bulan (Sorsogon), Pio Duran (Albay), Pasacao (Camarines Sur), San Andres (Quezon) |

Naming the mainland `Luzon` rather than leaving it blank keeps the graph
uniform and lets the app answer for someone arriving from Bicol.

`Z_OFFISLAND` was **split into `Z_PILAR`, `Z_BULAN`, `Z_PIODURAN` and
`Z_PASACAO`**. It was the only zone in the feed that was not one municipality,
and once zones became load-bearing it made Bulan and Pasacao — 200 km apart —
look like the same place.

### The crossing graph is derived, not maintained

There is no table of crossings. **A crossing is any leg whose two stops
disagree about which island they are on**, so adding a ferry to `fare_legs.csv`
adds it to the graph for free. Fourteen legs qualify today, up from nine before
the September 2026 research pass, and all fourteen are priced.

Reversibility needs no column either. Every leg that can be ridden backwards
already carries the return: the `departures` legs all have `departures_back`,
and a `window` or `on_demand` service runs the same hours both ways. So a leg
is reversible exactly when it has a `to_stop_id` — the six that do not are the
ones that land nowhere nameable, and those never cross anything.

Reachability, at four islands. **Every crossing is now priced and every pair
now meets pier to pier** — the September 2026 research pass took the graph
from nine crossings to fourteen and closed the gap that used to sit in the
middle of it:

| From → To | Masbate | Ticao | Burias |
| --- | --- | --- | --- |
| **Masbate** | — | 4 ways | Mobo → Claveria, Kho, ₱540 |
| **Ticao** | 4 ways | — | San Jacinto → Mobo → Claveria, 2 hops, no transfer |
| **Burias** | Claveria → Mobo | Claveria → Mobo → San Jacinto | — |

The Ticao–Burias entry is the one worth reading twice. It used to route
through Masbate City and then an unresearched hour down the coast to Mobo
Port. `L_RORO_MOBO_SANJACINTO` — Masbate island to Ticao without touching
Masbate City — lands at the same pier the Burias sailing leaves from, so the
journey now connects. It is slower and cheaper than the fastcraft and no
per-crossing comparison would ever have picked it; see **Two rules**, below,
for why the planner does.

### Two rules that keep this honest

**A chain is joined where the traveller already stands.** Someone on Ticao
looking at Catandayagan Falls, which is on Ticao, is not shown the fastcraft
from Masbate City and is not charged the ₱243 for it — ₱1550 against ₱1793.
Only a *crossing* can already have been made; an intra-island leg never has,
however much its destination island matches, or the boat out to Buntod sandbar
would vanish for a Masbate traveller and leave them on the beach.

**A crossing that lands at the wrong pier says so.** Ticao to Burias is two
ferries that do not meet: the first lands at Masbate City Port, the second
leaves from Mobo Port. Reporting the ferries and staying quiet about the hop
between them is how someone ends up stranded, so the gap is a field. A gap
inside one municipality is a tricycle and one line of text; a gap across
municipalities with nothing joining it is a warning.

The link lookup falls back from the exact pier to the municipality on purpose.
The feed names Mobo Port and Mobo Poblacion separately at identical
coordinates, and the researched jeep to Masbate City runs from the poblacion —
demanding the exact pier reported every arrival from Burias as a broken journey
across a town the dataset already covers. Forty false alarms is the fastest way
to teach someone to ignore the real ones, of which there are four, all of them
long overland hops on mainland Bicol that nobody has researched:

| Land at | Continue from | Roughly |
| --- | --- | --- |
| Pilar | Pasacao | 150 km |
| Pilar | Bulan | 60 km |
| Bulan | Pasacao | 200 km |
| Pasacao | Bulan | 200 km |

**A third rule follows from the first two: the crossing is chosen for where it
lands, not only for what it costs.** Scoring each crossing on its own fare and
timetable cannot see that landing at the wrong pier ends the journey, so the
whole path — including the pier the place's own access chain picks up from —
is scored together. Picking greedily from either end settles one boundary and
constrains the rest, which gets one direction right and its mirror wrong. Two
places on the same island can therefore want different boats, and the cache is
keyed accordingly.

## The last trip home

The fear that keeps people off these islands is not getting lost. It is being
stranded — the last boat off Ticao, the last van out of the terminal, the
lighthouse whose only public boat back is tomorrow morning. That figure decides
whether a place is a day trip, it is close to unfindable online, and it is
cheap to collect: one question at a ticket booth.

Everything else in this dataset answers *how do I get there*. This answers the
question people actually ask.

### `last_trips.csv` — collected, never inferred

One row per leg per boarding stop. Keyed on the stop rather than a direction,
because the two ends of a route rarely run to the same clock: **the last
pumpboat off Masbate City is 13:00 and the last one off Ticao is 14:00**, and
the shared service window in `fare_legs.csv` cannot express that hour.

| Column | Notes |
| --- | --- |
| `board_stop_id` | Where the traveller gets on. Not a direction. |
| `last_departure` | `HH:MM`. |
| `overnight` | `1` when the "last trip" is not late in the day but the next morning. Bugui Point's only public boat back is 06:00 tomorrow, which is an overnight, not a late departure, and the difference is the whole point of the field. |
| `confidence`, `valid_as_of`, `source_url` | As everywhere else. |

Four rows today. Every one was already in the dataset as prose inside an
advisory, where the app could read it to a human but not compute with it.

### A last trip is never read off a service window

This is the rule the whole feature rests on. Twenty-six of the forty legs here
are services that leave when they fill, and their closing hour is the shape of
a day, not a departure — fourteen of those windows are `estimate`, meaning, in
this README's own earlier words, plausible hours with an invented headway.

Turning one into "last bus 17:00" manufactures a departure nobody observed, and
someone plans their afternoon around it. So a last trip is either **collected**,
or **derived from a timetable trusted at `published` or `reported`**, or
**unknown** — and unknown is reported as unknown.

| Basis | Meaning | Count |
| --- | --- | --- |
| `collected` | Somebody asked. | 4 |
| `timetable` | Read off a real published schedule. | ~11 crossings |
| `round_trip` | Chartered, so it waits — there is no last trip to miss. | every `hire` leg |
| `unknown` | Nobody knows. Ask at the terminal. | the rest |

`round_trip` matters more than it looks. A chartered boat cannot strand you:
you hired it, it waits on the sandbar, it brings you back. Reporting that as
`unknown` would make every island-hopping trip in the province look
unplannable.

### The arithmetic

A backward pass over the journey home. Each hop's last departure is pushed back
through everything that has to happen before it, and the earliest survivor
wins:

```
latest start = min over hops of ( last departure of hop − travel time before it )
```

The hop that wins is named, because **"back by 14:15" is a rule someone can
hold in their head, and "the 15:00 fastcraft off Lagundi is what decides it" is
one they can plan around** — and can check when the boat turns out not to run.

Four states, which the UI must never collapse into one another:

| State | Means |
| --- | --- |
| a time | Start back by then. |
| `overnight` | There is no way back today at all. |
| `no_deadline` | You chartered the boat; it waits. Relax. |
| `same_day: null` | Nobody knows. Go and ask at the terminal. |

`same_day: null` is **not** `false`. One sends a traveller to ask a dispatcher;
the other tells them the trip is impossible.

### What to ask, ranked

`bin/rails last_trips:gaps` walks every place, every way in and every origin
island, and turns the unanswered hops into a list of questions ordered by how
many destinations each answer unblocks. `bin/rails 'last_trips:gaps[write]'`
writes it to [ASK-TOURISM.md](./ASK-TOURISM.md).

Twenty-one questions today. The top one — how late a habal-habal can still be
found — unblocks fifteen destinations on its own, and no ferry operator can
answer it; only a drivers' association can.

The task phrases each question by mode on purpose. A ferry has a last
departure. A habal-habal does not: it has an hour after which the stand empties,
which is a different question, and asking it the wrong way gets a guess back.

## Computing an estimate

`FareEstimate` (in `backend/app/services/`) walks one option's legs plus the
place's required fees:

```
per person = Σ per_person amounts
           + Σ (ceil(pax / covers_pax) × amount) / pax   for shared costs
```

It returns a min/max range and the flags a UI needs to explain a soft number —
`complete`, `negotiable`, `group_sensitive`, `confidence`, `oldest_source`.

```
GET /api/v1/bundles?from=ticao&pax=4
```

`from` is where the traveller **is**, not where they are going, and it is not a
filter. It used to be, which quietly broke the main journey: the selector asked
"leaving from", the API took that answer and narrowed places *to* that island,
and so someone on Ticao could never be shown Buntod sandbar at all. `island` is
still available where a genuine destination filter is wanted.

Party size can't be precomputed. Buntod sandbar is ₱670 each for one person and
₱253 each for six, and the cheaper *option* flips between them: the small boat
wins solo, the large boat wins from five up.

## What to verify first

Ranked by how much a wrong number would mislead someone. Reordered on
24 August 2026 after the prominence, signals and schedule-confidence pass.

1. ~~**`R_RORO_MSB_PILAR` is missing its outbound direction.**~~ **RESOLVED,
   and the old figures were wrong in both directions.** MARINA's route
   register has twelve sailings each way daily, every two hours from midnight,
   crossing in **3 hours** — not four sailings out, three back, over six. The
   authorised rate of ₱10.00 per nautical mile over 36 NM computes to exactly
   ₱360, settling the 288-vs-360 dispute. The GTFS feed still carries the old
   pattern and needs regenerating from `fare_legs.csv`.

2. **`R_PUMP_MSB_LAGUNDI` runs three hours too late in the feed.** Modelled to
   16:00; the last one really goes about 13:00. Someone reading this feed misses
   the last boat off Ticao.
3. **`R_FERRY_BULAN_SJ` still carries the 2017 pattern.** Partly closed: the
   operator is Barrun Sealines with MV Marilou Singko and MB Marilou Kwatro,
   MARINA certifies the route SERVED at 10.5 NM, and **San Jacinto Port is
   daytime navigation only** — there is no evening crossing to Ticao here
   whatever a timetable says. The sailing times themselves are still disputed.
   Original note: Five sailings each way
   in the feed; a May 2026 listing has three — Bulan 08:30/12:30/15:30, San
   Jacinto 05:30/10:00/13:00, Barrun Sealines, ₱200 RoRo. Even that source is
   not clean: a search summary of the same page reported different times.
4. ~~**`L_RORO_MOBO_CLAVERIA`.**~~ **RESOLVED — it was published after all.**
   Kho Shipping Lines, MV Cataingan, Mobo 00:01 arriving Claveria 04:00 and
   Claveria 18:00 arriving Mobo 22:00, four hours, ₱540 economy / ₱660
   tourist. The just-after-midnight departure is real: MARINA files Mobo –
   Claveria – Pio Duran as one route and the times chain across all three
   ports. The practical consequence stands, though — **Ticao to Burias cannot
   be done in a day.**

5. **`R_FC_MSB_PILAR` has no trips.** Route and fare leg with nothing to
   schedule. Find the timetable or drop the route.
6. **Every `stale` fare.** The Buntod boat rates are 2018 figures, though 2026
   sources still quote ₱500 and ₱800 — possibly genuine, possibly blogs copying
   each other. The 2018 Masbate–Lagundi pumpboat fare (₱80) is the weaker one.
7. **`P_LICUSON` is probably in the wrong municipality.** Two independent
   sources put Licuson Beach in **Mobo**, not Aroroy. That changes its access
   chain completely.
8. **`P_AROROY_LIGHTHOUSE` is probably a duplicate of `P_BUGUI_LIGHTHOUSE`.** A
   2026 sweep found no source describing a lighthouse at Aroroy poblacion
   distinct from Bugui Point, and the TripAdvisor entry called "Aroroy
   Lighthouse" carries reviews of the Bugui structure. Merge or delete.
9. **`L_HIRE_BURIAS_3ISL` capacity.** Unchanged: one source says 5–6 pax,
   another up to 10. That doubles or halves the per-person cost.
10. **`P_LAPUSLAPUS` municipality.** Filed under San Jacinto, but it is sold as
    part of the Monreal island-hopping circuit, which points to Monreal.
11. **The 27 `town_centroid` coordinates.**
12. **The four `unverified` places** — Burabod Spring, the San Jacinto cannons,
    the old houses of Monreal, San Jacinto Water Park. One source each, and that
    source is a tourism-potential study rather than anyone who went.
13. **Frequency headways in `gtfs/frequencies.txt`.** Now labelled: 14 of 22
    routes are `estimate`, meaning the window is plausible and the headway is
    invented.

## Routes and places this dataset is missing

Three of the four routes listed here in August were found in September and are
now in `fare_legs.csv`:

- ~~**Pilar (Sorsogon) – San Jacinto RoRo.**~~ **Found.**
  `L_RORO_SANJACINTO_PILAR` — Kho Shipping, Pilar 15:00 and San Jacinto 05:00,
  2.5 hours, ₱390 economy / ₱520 aircon. A direct Sorsogon–Ticao link that
  skips Masbate City. Note the gap against the regulator: MARINA's authorised
  rate over 22 NM computes to ₱200–300, well under what is charged.
- ~~**San Andres, Quezon – Burias.**~~ **Found.**
  `L_FERRY_SANPASCUAL_SANANDRES` — MV Kho Ferry I on the San Andres – San
  Pascual – Pasacao circuit, ₱625, San Pascual 14:00 arriving 16:30. **Trap
  avoided:** an aggregator route called "San Pascual to San Andres" at ₱300 is
  San Pascual in *Batangas*, a different province and a different sea.
- ~~**Aroroy Port – Bugui Point public boat.**~~ **Found**, and the lighthouse
  finally has an access chain. Public boat 11:00, ₱50, one hour, return 06:00
  the next day; charter ₱500–800 for up to four. Both figures are from a
  January 2018 article and are marked `stale` accordingly.
- **San Fernando, Ticao.** Partly closed. The port is LGU-operated and
  operational, and serves the fishing community; MARINA records Bulan – San
  Fernando as UNSERVED by RoRo, so it is not a passenger gateway. Still no
  places and no priced legs here.
- **Overland links between the mainland ports.** Pilar to Pasacao, Pilar to
  Bulan, Bulan to Pasacao. Each is the gap in a route the app can otherwise
  cost end to end; see the table in
  [Where the traveller is](#where-the-traveller-is). These are now the only
  unresearched transfers left in the graph.

### A whole category this dataset does not cover

The September pass turned up a dozen sailings that leave the province
altogether, none of them modelled:

| From | To | Operator |
| --- | --- | --- |
| Masbate City | Cebu City | Trans-Asia, Cokaliong |
| Masbate City | Lucena (Quezon), Calbayog (Samar) | Starhorse |
| Aroroy | Lucena (Quezon) | Starhorse |
| Mandaon (Nin Bay) | Culasi, Roxas City (Panay) | Kho Ferry |
| Balud (Calumpang) | Culasi, Roxas City (Panay) | MBca Gezel Kelvin |
| Placer | Maya, Daanbantayan (Cebu) | Trans-Asia |
| Cataingan / Mintac | Bogo and Cebu City, Calbayog | Kho, Montenegro |

Masbate is a crossroads, not a cul-de-sac, and the app currently models it as
one. Whether that matters depends on whether the traveller is assumed to
arrive through Bicol — which every access chain currently assumes.

Also turned up and not yet added: **Pio V. Corpuz**, a RoRo port just south of
Mobo serving Claveria, Pio Duran, Calbayog and Cebu, which may be the real
Masbate-side gateway to Burias rather than Mobo. And **Jintotolo Island
Lighthouse**, reached from Calumpang in Balud.

## `stops.csv` — what is actually at a terminal

Thirty-four stops. **21 now carry researched detail**; the remaining
13 carry a role and nothing else, and that blank is the
finding rather than a gap waiting on more searching — there is nothing
published about a roadside arch at Bat-ongan or a village path at Pawa.

GTFS has nowhere to put any of this, which is why it sits beside the feed like
`fare_legs.csv` does. `stop_desc` is one short line and was empty for eleven
stops.

| Column | Notes |
| --- | --- |
| `role` | `gateway` (inter-island port) · `terminal` (land transport) · `jump_off` (where a ride or boat is arranged) · `landing` (where one drops you). Derivable, so every row has it. |
| `port_authority` | `PPA`, `LGU` or `private`. Who to ask when a timetable is wrong. |
| `navigation` | `daytime` or `day_and_night`. **Load-bearing:** a daytime-only port has no evening crossing however late the operator's timetable runs. |
| `serves` / `operators` / `facilities` | Semicolon-separated, same convention as `departures_out`, so the file stays editable in a spreadsheet. |
| `ticketing`, `arrive_before_min` | Booth on site, pay onboard, or arrange with the boatman; and how early to turn up. Thin — mostly operator policy rather than port policy. |
| `confidence`, `valid_as_of`, `source_url` | Same meaning as everywhere else. Served as `detail` on the API, null where nothing was found. |

### The two facts here that change whether a trip is possible

Everything else on a stop is convenience. These two are not:

- **San Jacinto Port is daytime navigation only.** MARINA certifies it. There
  is no evening crossing from Bulan to Ticao, whatever a timetable implies.
- **Aroroy Port is not viable for RoRo operation.** MARINA says so plainly,
  and adds that passengers and shippers prefer Masbate City — which is why
  sailings there are thin and some have been unserved since the pandemic. No
  vehicles, and do not plan a connection through it.

A third is worth knowing for the opposite reason: **Masbate City Port is
sheltered behind Ticao Island** and stays workable in weather that closes
others, which is the one piece of good news in a province where
[`A_NOSAIL`](#advisoriescsv--operational-notes-that-fit-nowhere-else) can
cancel everything on the morning.

### Where it is still thin

`ticketing` and `arrive_before_min` are filled for four stops and are operator
policy rather than anything observed at the pier. Nothing here records whether
there is a CR, a waiting shed, food or an ATM at any terminal — the one
funded claim is that there is no ATM in San Pascual, and that lives in
`advisories.csv` where it belongs. A survey would fix this; desk research will
not.

### An unresolved conflict

This dataset files **Lagundi Port under Monreal**; a January 2026 provincial
survey puts it in **Batuan**. Both are on Ticao, so routing and fares are
unaffected, but the municipality is wrong in one of the two places and
`P_LAPUSLAPUS` already has a similar problem. Recorded on the stop rather than
silently picked.
