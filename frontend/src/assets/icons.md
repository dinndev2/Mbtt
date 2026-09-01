# Icons used in the mockups

Every icon is [Lucide](https://lucide.dev) at stroke width 2–2.4, `stroke="currentColor"`, no fill.
Install once and import by name — don't paste the SVGs.

```bash
npm i lucide-react
```

```jsx
import { Search, MapPin, Clock, ChevronRight } from "lucide-react";

<Search size={18} strokeWidth={2.2} color="#16587b" />
```

## The set, by where it appears

| Purpose | Lucide name | Size used |
| --- | --- | --- |
| Search field | `search` | 18–19 |
| Offline / saved indicator | `cloud-download` | 13–14 |
| Language toggle | `globe` | 13 |
| Row affordance | `chevron-right` | 17–20 |
| Collapsed picker | `chevron-down` | 16 |
| Back | `arrow-left` | 19 |
| Clear input | `x` | 11 |
| Terminal / boarding point | `map-pin` | 12–19 |
| Duration | `clock` | 12–15 |
| Fare, peso amounts | `philippine-peso` | 13–19 |
| Save trip | `bookmark` | 18–19 |
| Recommended / top pick | `star` | 13–15 |
| Survey note, help | `info` | 15–17 |
| Category · Sea | `waves` | 15–16 |
| Category · Nature | `mountain` | 15–16 |
| Category · City | `building-2` | 15–16 |
| Category · Food & markets | `utensils` | 15–16 |
| Ride · habal-habal, tricycle | `bike` | 15–21 |
| Ride · jeep, van, bus | `bus` | 12–21 |
| Ride · ferry, RoRo, boat | `sailboat` | 15–21 |

## Conventions

- Vehicle and category icons: `strokeWidth={1.9}` with `strokeLinejoin="round"`.
- Interface icons (search, chevrons, close): `strokeWidth={2.2}`–`2.4`.
- Color is `#16587B` on cream, `#F7F4EE` on a blue fill, `rgba(46,58,67,.72)` when secondary.
- Icons never carry meaning alone — every one sits beside a text label.
