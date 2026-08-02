# Women Safety App

An Android + IoT based women safety application (no AI/ML) built as a college mini project.

## Core Features
1. **Safest Route Suggestion** — suggests the safest path to a destination by analyzing area-wise crime data, not just the shortest route.
2. **Volume-Button Emergency SOS** — triggered by rapid volume-key presses, sends live location via SMS to saved emergency contacts and the nearest police station.
3. **No-Network Emergency SOS via ESP32** — a companion ESP32 hardware unit (with its own GSM + GPS) sends an SOS SMS independently, even when the phone has no network connectivity.

## Team
4-member group project | 6-week build timeline

## Repo Structure
```
women-safety-app/
├── android-app/       Android Studio project (Kotlin) — Week 2 onward
├── firmware/           ESP32 Arduino/PlatformIO firmware — Week 4-5
├── docs/                Project documentation
│   └── SRS_Document.docx
└── data-pipeline/       Crime data generation + safety-scoring algorithm
    ├── README.md
    ├── requirements.txt
    ├── generate_crime_dataset.py
    ├── preprocess_crime_data.py
    ├── nerul_crime_data.csv
    ├── nerul_zone_safety_scores.csv
    └── nerul_crime_heatmap.png
```

## Status
- [x] Week 1 — Research, SRS, crime data pipeline (Nerul, Navi Mumbai demo dataset)
- [ ] Week 2 — Android app skeleton (auth, contacts, maps)
- [ ] Week 3 — Safest route feature
- [ ] Week 4 — Volume-button SOS + hardware bring-up
- [ ] Week 5 — ESP32 no-network SOS integration
- [ ] Week 6 — Testing, polish, final report

See `data-pipeline/README.md` for details on the crime dataset and safety-scoring algorithm.
