# Week 1 — Setup & Research
## Women Safety App (Android + IoT) — Mini Project

This folder contains everything for Week 1 of the 6-week roadmap:
tech stack finalization, SRS document, and the crime dataset pipeline
that Feature 1 (Safest Route Suggestion) will be built on in Week 3.

---

## 1. What's in this folder

```
week1/
├── README.md                          <- you are here
├── requirements.txt                   <- Python deps for the scripts below
├── SRS_Document.docx                  <- formal Software Requirements Spec
└── crime_data/
    ├── generate_crime_dataset.py      <- creates the synthetic incident dataset
    ├── nerul_crime_data.csv          <- 1,200 synthetic crime incidents (raw)
    ├── preprocess_crime_data.py       <- grids incidents into zones, scores safety
    ├── nerul_zone_safety_scores.csv  <- output: 236 zones with 0-100 safety score
    └── nerul_crime_heatmap.png       <- visual heatmap of the zone scores
```

## 2. How to run it

```bash
pip install -r requirements.txt

cd crime_data
python3 generate_crime_dataset.py      # -> nerul_crime_data.csv
python3 preprocess_crime_data.py       # -> zone scores + heatmap
```

## 3. Why synthetic data?

Real, granular (lat/lon-level) crime data isn't publicly available from
Indian police departments in a usable open format for a student project.
`generate_crime_dataset.py` creates a **realistic simulated dataset**:
1,200 incidents scattered around 18 real sectors/localities within Nerul,
Navi Mumbai (e.g. Sector 19A, Sector 20, Seawoods, Nerul West/East, DY Patil
Stadium area), with randomized crime types, severity (1-5), time-of-day bias
(more incidents at night/evening), and dates across 2024-2025.

**Say this explicitly in your report/viva:** this is simulated data
mimicking the structure of real crime reports. A production version would
integrate with an official police open-data API or an NCRB dataset release.

## 4. How the safety scoring works (`preprocess_crime_data.py`)

1. **Grid the Nerul area** into ~200m × 200m zones (lat/lon cells — finer
   than a city-wide grid, since Nerul itself is a small locality)
2. For every incident in a zone, compute a weighted "danger contribution":
   `danger = severity × time_of_day_weight × recency_weight`
   - Night/evening incidents weighted higher than daytime
   - Recent incidents weighted higher than old ones (exponential decay, ~1yr half-life)
3. Sum danger contributions per zone → `raw_danger_score`
4. Normalize across all zones and flip the scale → `safety_score_0to100`
   (100 = safest zone, 0 = most dangerous)
5. Output `nerul_zone_safety_scores.csv` — this is what **Feature 1** will
   consume in Week 3: each candidate route from Google Directions API gets
   checked against which zones its polyline passes through, and the route's
   overall safety = average `safety_score` of those zones.

## 5. Finalized Tech Stack

| Layer | Choice |
|---|---|
| Mobile App | Android Studio, Kotlin |
| Backend/Auth | Firebase Auth + Firestore |
| Maps & Routing | Google Maps Directions API + Places API |
| Crime Data Prep | Python (pandas, matplotlib) — this folder |
| Volume-button SOS | Android AccessibilityService + SmsManager |
| No-network SOS Hardware | ESP32 + SIM800L (GSM/SMS) + NEO-6M (GPS) |
| Phone ↔ ESP32 Link | Bluetooth Low Energy (BLE) |
| Version Control | GitHub (see suggested repo structure below) |

## 6. Suggested full GitHub repo structure (for Week 2 onward)

```
women-safety-app/
├── android-app/            <- Android Studio project (Kotlin)
├── firmware/                <- ESP32 Arduino/PlatformIO sketch
├── data-pipeline/            <- this week1/crime_data content, evolves over time
├── docs/
│   ├── SRS_Document.docx
│   ├── architecture-diagrams/
│   └── weekly-progress-reports/
└── README.md
```

## 7. Week 1 checklist status

- [x] Tech stack finalized
- [x] GitHub repo structure planned
- [x] Synthetic crime dataset generated (nerul_crime_data.csv)
- [x] Zone-based safety scoring algorithm prototyped (Python)
- [x] SRS document drafted
- [ ] Hardware components ordered (ESP32, SIM800L, NEO-6M) — **team action item, do this ASAP, GSM modules can take days to arrive**
- [ ] GitHub repo actually created and pushed

## 8. Next: Week 2

Android Studio project skeleton — login/signup, Firestore-backed emergency
contact CRUD, and basic Google Maps display of current location.
