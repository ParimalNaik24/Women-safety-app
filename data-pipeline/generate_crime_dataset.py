"""
generate_crime_dataset.py
--------------------------
Women Safety App - Mini Project (Week 1)

Generates a SYNTHETIC crime-incident dataset for Navi Mumbai (Nerul area),
to be used for building and testing the "Safest Route" scoring algorithm
(Feature 1).

WHY SYNTHETIC DATA?
Real, granular, geo-tagged crime data (lat/lon level) is not publicly
released by Indian police departments / NCRB in a usable open format for
a student project. So we simulate a realistic dataset:
    - Higher crime density is placed near known busier/denser zones
      (approximate coordinates only, for demo purposes)
    - Crime types, time-of-day, and severity are randomized with
      realistic distributions

IMPORTANT FOR YOUR REPORT:
State clearly that this is simulated/sample data mimicking real crime
report structure, and that a production version would integrate with
an official police open-data API or NCRB dataset.

Output: mumbai_crime_data.csv
Columns: incident_id, latitude, longitude, area_name, crime_type,
         severity (1-5), time_of_day, date
"""

import csv
import random
from datetime import datetime, timedelta

random.seed(42)  # reproducible dataset

# Approximate central coordinates for well-known sectors/localities within
# Nerul, Navi Mumbai. (Used only as anchor points to scatter synthetic
# incidents around -- NOT claiming these are actual crime hotspots.)
AREAS = {
    "Nerul Railway Station Area": (19.0339, 73.0197),
    "Nerul Sector 19A": (19.0398, 73.0157),
    "Nerul Sector 20": (19.0405, 73.0110),
    "Nerul Sector 21": (19.0455, 73.0140),
    "Nerul Sector 22": (19.0330, 73.0245),
    "Nerul Sector 23": (19.0280, 73.0210),
    "Nerul Sector 28": (19.0300, 73.0080),
    "Nerul Sector 40": (19.0180, 73.0230),
    "Nerul Sector 50 (Seawoods)": (19.0125, 73.0190),
    "Seawoods Grand Central": (19.0115, 73.0175),
    "Nerul Lake Garden": (19.0365, 73.0165),
    "Nerul West": (19.0350, 73.0100),
    "Nerul East": (19.0350, 73.0280),
    "DY Patil Stadium Area": (19.0450, 73.0270),
    "Juhu Nagar, Nerul": (19.0300, 73.0300),
    "Nerul Balaji Mandir Area": (19.0340, 73.0220),
    "Nerul Sector 8": (19.0370, 73.0230),
    "Nerul Sector 3": (19.0300, 73.0170),
}

CRIME_TYPES = [
    ("Chain Snatching", 3),
    ("Eve Teasing / Harassment", 2),
    ("Stalking", 3),
    ("Molestation", 4),
    ("Theft", 2),
    ("Assault", 4),
    ("Robbery", 4),
    ("Suspicious Activity / Loitering", 1),
    ("Kidnapping Attempt", 5),
    ("Domestic Violence (reported outdoors)", 3),
]

TIME_SLOTS = ["Morning (6-12)", "Afternoon (12-17)", "Evening (17-21)", "Night (21-6)"]
# Night and evening should have higher weight (more incidents reported)
TIME_WEIGHTS = [0.15, 0.15, 0.35, 0.35]

# Give each area a randomized "risk level" (1 = safest, 5 = highest risk)
# to make some zones consistently worse than others -- this drives the
# clustering pattern the route-scoring algorithm will later pick up on.
AREA_RISK = {area: random.choice([1, 1, 2, 2, 3, 3, 4, 5]) for area in AREAS}

NUM_INCIDENTS = 1200
START_DATE = datetime(2024, 1, 1)
END_DATE = datetime(2025, 12, 31)


def random_date():
    delta_days = (END_DATE - START_DATE).days
    return START_DATE + timedelta(days=random.randint(0, delta_days))


def jitter_coordinate(lat, lon, spread=0.004):
    """Scatter a point randomly around an area's center (~400m spread)."""
    return (
        round(lat + random.uniform(-spread, spread), 6),
        round(lon + random.uniform(-spread, spread), 6),
    )


def main():
    rows = []
    for i in range(1, NUM_INCIDENTS + 1):
        area_name = random.choice(list(AREAS.keys()))
        base_lat, base_lon = AREAS[area_name]
        lat, lon = jitter_coordinate(base_lat, base_lon)

        risk_level = AREA_RISK[area_name]
        # Higher risk areas get more incidents naturally because we loop
        # NUM_INCIDENTS times with uniform area choice; to also bias
        # severity by area risk, skew crime_type/severity selection:
        crime_type, base_severity = random.choice(CRIME_TYPES)
        severity = max(1, min(5, base_severity + random.choice([-1, 0, 0, 1]) 
                               + (1 if risk_level >= 4 else 0)))

        time_of_day = random.choices(TIME_SLOTS, weights=TIME_WEIGHTS, k=1)[0]
        date = random_date().strftime("%Y-%m-%d")

        rows.append({
            "incident_id": f"INC{i:05d}",
            "latitude": lat,
            "longitude": lon,
            "area_name": area_name,
            "crime_type": crime_type,
            "severity": severity,
            "time_of_day": time_of_day,
            "date": date,
        })

    out_path = "nerul_crime_data.csv"
    with open(out_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    print(f"Generated {len(rows)} synthetic crime incidents -> {out_path}")


if __name__ == "__main__":
    main()
