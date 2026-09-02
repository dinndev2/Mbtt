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
| `published` | From the operator or LGU |
| `reported` | Recent travel writing |
| `estimate` | Inferred from a comparable leg — flagged in `notes` |
| `stale` | A real figure, but years old |
| `unknown` | Route exists, no price found. `amount_min_php` is empty |

Leave an amount empty rather than guessing. An empty amount makes the estimate
`complete: false`, which the UI shows as "from ₱X" instead of a total.

### `place_access.csv` — the chain of legs to a place

`option` groups legs into **alternative** routes, not consecutive steps. Option
A for Sombrero Island is the Pasacao ferry then a boat hire; option B is the
Masbate City RoRo, a van, then the same boat hire. `seq` orders the steps
*within* one option.

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
GET /api/v1/bundles?island=burias&pax=4
```

Party size can't be precomputed. Buntod sandbar is ₱670 each for one person and
₱253 each for six, and the cheaper *option* flips between them: the small boat
wins solo, the large boat wins from five up.

## What to verify first

Ranked by how much a wrong number would mislead someone. Reordered on
24 August 2026 after the prominence, signals and schedule-confidence pass.

1. **`R_RORO_MSB_PILAR` is missing its outbound direction.** Five trips in the
   feed, all Pilar → Masbate. Nobody can be routed off the island on the main
   gateway route. The inbound times match no published source either — a May
   2026 listing has Masbate departing 08:00/10:00/12:00/16:00 and Pilar
   10:00/12:00/20:00, six hours, ₱360 regular. That listing also settles the old
   288-vs-360 dispute in favour of 360.
2. **`R_PUMP_MSB_LAGUNDI` runs three hours too late in the feed.** Modelled to
   16:00; the last one really goes about 13:00. Someone reading this feed misses
   the last boat off Ticao.
3. **`R_FERRY_BULAN_SJ` still carries the 2017 pattern.** Five sailings each way
   in the feed; a May 2026 listing has three — Bulan 08:30/12:30/15:30, San
   Jacinto 05:30/10:00/13:00, Barrun Sealines, ₱200 RoRo. Even that source is
   not clean: a search summary of the same page reported different times.
4. **`L_RORO_MOBO_CLAVERIA`.** Still nothing published — no fare, no timetable,
   no operator. The only Masbate-side route into Burias, and it leaves two
   Burias places `complete: false`. In practice almost everyone reaches Burias
   from San Andres, Quezon or Pasacao instead, which may be the real answer.
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

Turned up while checking the above, not yet added:

- **Pilar (Sorsogon) – San Jacinto RoRo.** Kho Shipping, Pilar 15:00 and San
  Jacinto 05:00, about 2.5 hours, ₱390 economy / ₱520 aircon. A second, older
  source describes a Pilar – Monreal crossing at ₱120 plus a ₱15 terminal fee,
  Pilar 12:00 and Monreal 07:00. A direct Sorsogon–Ticao link that skips Masbate
  City entirely.
- **San Andres, Quezon – Burias.** The way most people actually reach Animasola,
  Sombrero and Dapa: about two hours. The dataset only knows the Pasacao and
  Claveria approaches.
- **Aroroy Port – Bugui Point public boat.** 11:00 daily, ₱50, one hour, return
  06:00 the next day. Charter about ₱800 round trip for four, quoted up to
  ₱1,500. Currently the lighthouse has no access chain at all.
- **San Fernando, Ticao.** Ticao's fourth municipality. It has a port that
  appears in Coast Guard cancellation notices, and no places or stops here.
