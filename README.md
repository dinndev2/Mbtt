# MBTT — Masbate Transport

A travel guide for getting around Masbate, Ticao and Burias in the
Philippines. Pick the island you are on and the place you want to reach, and
MBTT shows how to get there: which boat or ride to take, where to board, what
the trip costs and when the last trip back leaves.

## Why it exists

Getting around Masbate is easy once you know how, and hard to find out
beforehand. Fares, boarding points and boat times are rarely published in one
place. Travellers end up asking around, and locals often have to go to a
ticketing booth in person, which is not always practical when you live far
from the city or have a tight budget. A lot of the islands' best places stay
unvisited simply because the information is hard to find.

MBTT puts that information in one place, on the phone, in a few taps.

## Who it is for

- **Travellers** who have just arrived and want to reach a beach, island or
  landmark without getting stranded.
- **Locals** who need a fare or a boarding point without making a trip to the
  terminal to ask.

## What it does

- **Start from where you are.** Choose Masbate, Ticao or Burias, and every
  fare, crossing and travel time is worked out from that island.
- **Find a place.** Search by name, town or island, with a photo, the travel
  time and the fare in each result.
- **See the whole trip.** Each place shows:
  - **The last way back:** the latest time to leave and still get home the
    same day, or a plain "ask at the terminal" when nobody publishes it.
  - **The crossing:** the boat off your island, when the place is on another
    one.
  - **Each leg:** the vehicle (tricycle, habal-habal, bus, van, boat or
    ferry), its fare and its departures or operating hours.
  - **The terminals:** where to board, with photos, facilities, ticketing and
    a map.
  - **Fees:** gate, environmental and landing fees, included in the total.
- **Know what to carry.** The trip fare stays pinned to the bottom of the
  screen, per person or split across your party, and says when part of it is
  unpriced, haggled or cheaper in a group.

An admin area lets the maintainer sign in and add, edit or remove places and
their photos.

## Intended use

MBTT is a planning tool, not a booking service. Use it to decide where to go,
what to bring and when to head back. Then confirm with the driver, boatman or
terminal before you set off. It has no tickets, payments, live tracking or
user accounts.

The project starts small, with Masbate and its two neighbouring islands, and
is built so that more places can be added later. Working offline is a goal,
so the guide stays useful where reception is poor.

## About the data

The fares, routes and schedules are desk research collected in August 2026
from ferry operator listings, LGU rate sheets and travel blogs. None of it has
been surveyed on the ground yet. The app says so wherever a number is missing
or uncertain, instead of inventing one.

The data lives as CSV files and a GTFS feed in [`data/`](data/). Correcting a
number means editing the CSV and re-seeding. [`data/README.md`](data/README.md)
explains each file and why fares are not stored in GTFS alone.

## How it is built

| Part | Stack | Folder |
| --- | --- | --- |
| API | Ruby on Rails 8, SQLite | [`backend/`](backend/) |
| App | React, TypeScript, Vite, Tailwind CSS, Leaflet | [`frontend/`](frontend/) |
| Data | CSV and GTFS | [`data/`](data/) |
| Docs | Problem, scope, data model, decisions | [`docs/`](docs/) |

## Running it locally

You need Ruby 3.2.2 and Node.js.

```sh
# API on http://localhost:3100
cd backend
bundle install
bin/rails db:setup        # creates the database and loads the data
bin/rails server -p 3100

# App on http://localhost:5173 (in a second terminal)
cd frontend
npm install
npm run dev
```

The app reads the API address from `VITE_API_URL` in
`frontend/.env.development`, and the API only accepts requests from
`http://localhost:5173` (see `backend/config/initializers/cors.rb`).

## License

[MIT](LICENSE) © 2026 Din Penagunda
