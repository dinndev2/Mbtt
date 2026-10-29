# Image attribution

Images in `frontend/public/images/places/` come from two places, and they are
**not** interchangeable. Check which list a file is in before you reuse it.

The API serves `images[].credit` on each place and each stop in the bundle's
`stops` directory, from `attribution` + `license` (`Image#credit`).
Don't drop it.

## 1. Wikimedia Commons -- CC BY-SA, safe to publish

Downloaded 2026-08-20 at 1200px. Attribution is a condition of use: the credit
must appear wherever the photo is displayed. A file's licence on Commons can
change, so re-check before publishing.

| Place | File | Photographer | Licence | Source |
| --- | --- | --- | --- | --- |
| Buntod Reef Marine Sanctuary and Sandbar | `p_buntod-1.jpg` | Johrabino | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:BUNTOD_MASBATE_SANDBAR.jpg) |
| Buntod Reef Marine Sanctuary and Sandbar | `p_buntod-2.jpg` | Bert Andone | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Buntod_Reef_Marine_Sanctuary_%26_Sandbar.jpg) |
| Masbate Cathedral | `p_masbate_cathedral-1.jpg` | Benedict Esber | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Masbate_Cathedral.jpg) |
| Masbate Cathedral | `p_masbate_cathedral-2.jpg` | Mootboot12 | CC BY-SA 3.0 | [Commons](https://commons.wikimedia.org/wiki/File:Masbate_Cathedral_-_Exterior_View.jpg) |
| Gawas Beach | `p_gawas_beach-1.jpg` | Reygel Perales | CC BY-SA 3.0 | [Commons](https://commons.wikimedia.org/wiki/File:Gawas_beach,_Esperanza,_Masbate,_Philippines.jpg) |
| Gawas Beach | `p_gawas_beach-2.jpg` | Reygel Perales | CC BY-SA 3.0 | [Commons](https://commons.wikimedia.org/wiki/File:The_Baruto(canoe)_Gawas_beach,_Esperanza,_Masbate,_Philippines.jpg) |
| Lapus-Lapus Green Lagoon | `p_lapuslapus-1.jpg` | Denica Daniel Catapat | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Beauty_of_Ticao_Island.jpg) |
| Manta Bowl Shoal | `p_manta_bowl-1.jpg` | JoseZander Servando | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Sunset_at_Ticao_Pass.jpg) |
| Animasola Island | `p_animasola-1.jpg` | Glenn Rivera | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Animasola_Island_Rock_Formation_01.jpg) |
| Animasola Island | `p_animasola-2.jpg` | Irvin Parco Sto. Tomas | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Animasola_Island,_Masbate_1.jpg) |
| Sombrero Island | `p_sombrero-1.jpg` | Maffeth.opiana | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Sombrero_Island.jpg) |
| Sombrero Island | `p_sombrero-2.jpg` | Derk29 | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Sombrero_Island_Beach.jpg) |
| Tinalisayan Island | `p_tinalisayan-1.jpg` | Derk29 | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Tinalisayan_Island.jpg) |
| Tinalisayan Island | `p_tinalisayan-2.jpg` | Irvin Parco Sto. Tomas | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Sandbar_at_Tinalisayan_Island_in_San_Pascual,_Masbate.jpg) |

## 2. Open web -- licence UNVERIFIED, personal use only

Collected 2026-09-07 for personal, offline use because no
openly-licensed photograph of these places exists on Commons -- the searches
that found the list above return car ads and 17th-century PDFs for most of
Masbate. **No licence was granted for any of these.** They carry `license =
unverified` in `place_images.csv` so nothing in the codebase can mistake them
for the CC BY-SA set.

Before this project is ever published, every row here must be replaced with a
licensed photograph or removed. `attribution` holds the site the file came
from, which is a provenance record, not a rights grant.

| Place | File | Source page |
| --- | --- | --- |
| Pawa Mangrove Park | `p_pawa-1.jpg` | [langyaw.com](https://langyaw.com/2013/10/20/1-7-km-bamboo-footbridge-masbate-city/) |
| Pawa Mangrove Park | `p_pawa-2.jpg` | [justinvawter.com](https://justinvawter.com/budget-guide/explore-masbate/) |
| Mount Mayong Payong | `p_mayong_payong-1.jpg` | [shammieragos.blogspot.com](https://shammieragos.blogspot.com/2017/02/travel-mt-mayong-payong-mobo-masbate.html) |
| Mount Mayong Payong | `p_mayong_payong-2.jpg` | [shammieragos.blogspot.com](https://shammieragos.blogspot.com/2017/02/travel-mt-mayong-payong-mobo-masbate.html) |
| Bat-ongan Cave | `p_batongan_cave-1.jpg` | [bicoltravelguides.com](https://bicoltravelguides.com/climb-through-time-at-bat-ongan-cave-in-masbate/) |
| Bat-ongan Cave | `p_batongan_cave-2.jpg` | [outoftownblog.com](https://outoftownblog.com/masbate-tourist-spots/) |
| Palani White Beach | `p_palani_beach-1.jpg` | [tripadvisor.com.ph](https://www.tripadvisor.com.ph/Attraction_Review-g8126282-d4346511-Reviews-Palani_White_Beach-Balud_Masbate_Island_Masbate_Province_Bicol_Region_Luzon.html) |
| Palani White Beach | `p_palani_beach-2.jpg` | [tripadvisor.com.ph](https://www.tripadvisor.com.ph/Attraction_Review-g8126282-d4346511-Reviews-Palani_White_Beach-Balud_Masbate_Island_Masbate_Province_Bicol_Region_Luzon.html) |
| Bugui Point Lighthouse | `p_bugui_lighthouse-1.jpg` | [tripadvisor.at](https://www.tripadvisor.at/Attraction_Review-g6103862-d9696123-Reviews-Aroroy_Lighthouse-Masbate_Island_Masbate_Province_Bicol_Region_Luzon.html) |
| Bugui Point Lighthouse | `p_bugui_lighthouse-2.jpg` | [bicoltravelguides.com](https://bicoltravelguides.com/bugui-point-lighthouse-a-glimpse-into-masbates-maritime-past/) |
| Busay de Gracia Falls | `p_busay_de_gracia-1.jpg` | [outoftownblog.com](https://outoftownblog.com/masbate-tourist-spots/) |
| Busay de Gracia Falls | `p_busay_de_gracia-2.jpg` | [jontotheworld.com](https://jontotheworld.com/best-masbate-tourist-spots/) |
| Porta Vega Beach | `p_porta_vega-1.jpg` | [shammieragos.blogspot.com](https://shammieragos.blogspot.com/2014/04/summer-2014-porta-vega-beach-resort.html) |
| Porta Vega Beach | `p_porta_vega-2.jpg` | [it.pinterest.com](https://it.pinterest.com/pin/porta-vega-dimasalang-masbate--71846556535092676/) |
| Nagarao Island | `p_nagarao-1.jpg` | [buzzsetter.com](https://buzzsetter.com/best-masbate-tourist-spots/) |
| Nagarao Island | `p_nagarao-2.jpg` | [tripadvisor.com](https://www.tripadvisor.com/Attraction_Review-g6103862-d7182973-Reviews-Nagarao_Island-Masbate_Island_Masbate_Province_Bicol_Region_Luzon.html) |
| Matayum Lagoon | `p_matayum-1.jpg` | [catainganmasbate.gov.ph](https://catainganmasbate.gov.ph/) |
| Matayum Lagoon | `p_matayum-2.jpg` | [mindtrip.ai](https://mindtrip.ai/attraction/cataingan-luzon/masbate-lagoon/at-ME21Acy9) |
| La Manok Island | `p_la_manok-1.jpg` | [shammieragos.blogspot.com](https://shammieragos.blogspot.com/2021/06/island-hopping-la-manok-island-masbate.html) |
| La Manok Island | `p_la_manok-2.jpg` | [shammieragos.blogspot.com](https://shammieragos.blogspot.com/2021/06/island-hopping-la-manok-island-masbate.html) |
| Matang Tubig Spring | `p_matang_tubig-1.jpg` | [flickr.com](https://www.flickr.com/photos/136561464@N06/21593987499) |
| Matang Tubig Spring | `p_matang_tubig-2.jpg` | [daisyruado.blogspot.com](https://daisyruado.blogspot.com/) |
| Halea Nature Park | `p_halea-1.jpg` | [flickr.com](https://www.flickr.com/photos/gabzki/34191821030) |
| Halea Nature Park | `p_halea-2.jpg` | [rizzasalas.blogspot.com](https://rizzasalas.blogspot.com/2017/09/Masbate2017.html) |
| Catandayagan Falls | `p_catandayagan-1.jpg` | [tripadvisor.at](https://www.tripadvisor.at/Attraction_Review-g3830444-d8132861-Reviews-Catandayagan_Falls-Ticao_Island_Masbate_Province_Bicol_Region_Luzon.html) |
| Catandayagan Falls | `p_catandayagan-2.jpg` | [flickr.com](https://www.flickr.com/photos/md_mc/13962159973/) |
| Burubangkaso Islet | `p_burubangkaso-1.jpg` | [tripadvisor.com](https://www.tripadvisor.com/Attraction_Review-g667127-d25239837-Reviews-Borobangcaso_Islet-Masbate_City_Masbate_Island_Masbate_Province_Bicol_Region_Luz.html) |
| Burubangkaso Islet | `p_burubangkaso-2.jpg` | [tripadvisor.es](https://www.tripadvisor.es/Attraction_Review-g667127-d25239837-Reviews-Borobangcaso_Islet-Masbate_City_Masbate_Island_Masbate_Province_Bicol_Region_Luz.html) |
| Lapus-Lapus Green Lagoon | `p_lapuslapus-2.jpg` | [outoftownblog.com](https://outoftownblog.com/masbate-tourist-spots/) |
| Bongsanglay Natural Park | `p_bongsanglay-1.jpg` | [7641islands.ph](https://www.7641islands.ph/explore/visiting-bongsanglay-natural-park/) |
| Bongsanglay Natural Park | `p_bongsanglay-2.jpg` | [7641islands.ph](https://www.7641islands.ph/explore/visiting-bongsanglay-natural-park/) |
| Manta Bowl Shoal | `p_manta_bowl-2.jpg` | [islandhoppinginthephilippines.com](https://islandhoppinginthephilippines.com/visayas/faq/diving-ticao-pass-masbate/) |
| Dapa Island | `p_dapa-1.jpg` | [jontotheworld.com](https://jontotheworld.com/dapa-burias-island-masbate/) |
| Dapa Island | `p_dapa-2.jpg` | [tripadvisor.nl](https://www.tripadvisor.nl/Attraction_Review-g667126-d26328927-Reviews-Dapa_or_Snake_Island-Burias_Island_Masbate_Province_Bicol_Region_Luzon.html) |

## 3. Still without any image

No photograph that could be confirmed as the place itself was found for these.
Searches return a plausible-looking but *different* subject, which is worse than
an empty slot -- so the slot stays empty until someone who knows the province
supplies one.

| Place | Municipality | What the search returns instead |
| --- | --- | --- |
| Bat-ongan Falls | Mandaon | Catandayagan Falls, every time |
| Matincal Beach | Aroroy | Tigbao, Amoroy and Tinigban beaches |
| Licuson Beach | Aroroy | one Pinterest pin, captioned Mobo rather than Aroroy |
| Aroroy Lighthouse | Aroroy | Bugui Point Lighthouse -- possibly the same structure |
| Mababoy Island | Monreal | unnamed Ticao coves |
| Burabod Spring | San Jacinto | Matang Tubig Spring, indistinguishable |
| Spanish-era Cannons of San Jacinto | San Jacinto | the San Jacinto battlefield cannons in Texas |
| Old Houses of Monreal | Monreal | generic Filipino ancestral houses |
| San Jacinto Water Park | San Jacinto | Ticao Island Resort |

48 images over 24 of 33 places:
14 from Commons, 34 from the open web. 9 places have none.

## 4. Stop photos -- Wikimedia Commons, safe to publish

Images in `frontend/public/images/stops/`, listed in `stop_images.csv`.
Downloaded 2026-10-02 from the 1280px Commons thumbnail and scaled to 1200px
locally -- Commons no longer serves a 1200px step. Same rules as section 1:
the credit must appear wherever the photo is displayed, and a file's licence
on Commons can change, so re-check before publishing. There is no open-web
tier for stops; a stop without a Commons photo simply has none.

`Masbate Port 1.jpg` is titled and categorised as Masbate City's port on
Commons, but its geotag and its scenery are San Pascual on Burias, so it is
filed under `S_SANPASCUAL_PORT` here.

| Stop | File | Photographer | Licence | Source |
| --- | --- | --- | --- | --- |
| Masbate City Port | `s_masbate_port-1.jpg` | Patrickroque01 | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Masbate_Port_(Masbate_City;_04-12-2024).jpg) |
| Masbate City Port | `s_masbate_port-2.jpg` | Patrickroque01 | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Masbate_City_skyline_port_area_(Masbate_City;_04-12-2024).jpg) |
| Buntod Sandbar | `s_buntod_sandbar-1.jpg` | Bert Andone | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Buntod_Reef_Marine_Sanctuary.jpg) |
| Buntod Sandbar | `s_buntod_sandbar-2.jpg` | Mark arcelo | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Buntod_Beach_Resort.jpg) |
| San Pascual Poblacion | `s_sanpascual_pob-1.jpg` | Ringer | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:San_Pascual.jpg) |
| San Pascual Poblacion | `s_sanpascual_pob-2.jpg` | Ringer (Central Bikol Wikipedia) | CC BY-SA 3.0 | [Commons](https://commons.wikimedia.org/wiki/File:Munisipyo_kan_San_Pascualo.jpg) |
| San Pascual Port | `s_sanpascual_port-1.jpg` | Maffeth.opiana | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Masbate_Port_1.jpg) |
| San Pascual Port | `s_sanpascual_port-2.jpg` | MarvinBikolano | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Part_of_the_port_of_San_Pascual,_Masbate.jpg) |
| Pio Duran Port | `s_pioduran_port-1.jpg` | Patrickroque01 | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Pio_Duran_skyline_sea_view_(Pio_Duran,_Albay;_04-12-2024).jpg) |
| Pasacao Port | `s_pasacao_port-1.jpg` | BiancaBrazal | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:View_of_Pasacao_port.jpg) |

10 images over 6 of 34 stops.

## 5. Stop photos from Flickr (via Openverse) -- searched, none qualified

Searched 2026-10-02 through the Openverse API
(`license=by,by-sa,cc0,pdm`, Wikimedia excluded because section 4 already
covers it), by keyword and by Flickr tag, for every stop with fewer than two
photos. The rule was the same as section 4 plus one more check: the licence had
to match on the Flickr page itself, not only in Openverse's index, and the
uploader had to plausibly be the photographer.

Nothing passed, so no stop photo comes from Flickr and `stop_images.csv` is
unchanged. Openverse holds almost nothing openly licensed for Masbate: most
hits are museum specimens tagged with the province, or a namesake somewhere
else. Recorded here so the search isn't repeated blind.

| Search | What came back instead |
| --- | --- |
| Masbate, Masbate City, port, pier, terminal | Masbat Bay in Dahab, Egypt; a Sinulog pageant in Cebu; land snails |
| Mobo | Mobo in Kalibo, Aklan |
| Claveria | Claveria, Cagayan; Claveria Street, Davao; resized stock with numeric file names |
| Ticao, San Jacinto, Monreal | a Brazilian bar nicknamed Ticão; San Jacinto, Pangasinan; the Monreal Stones in a museum |
| Pilar, Sorsogon | one outrigger on still water in Pilar Bay, not the port |
| Bulan, Pio Duran, Pasacao, San Andres | nothing in the Philippines, or nothing at all |
| Every other town, Nagarao, Porta Vega, Bugui, Bat-ongan, Pawa, Rendezvous | no results |

The only openly licensed Masbate scenery Openverse returned is four beach and pasture
shots by one uploader (Palani Beach, unnamed coast, cattle pasture) -- places,
not stops.
