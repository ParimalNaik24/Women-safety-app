"""
preprocess_crime_data.py
--------------------------
Women Safety App - Mini Project (Week 1)

Takes the raw incident-level crime CSV (nerul_crime_data.csv) and:
    1. Buckets incidents into a lat/lon GRID of fixed-size zones
       (~500m x 500m cells)
    2. Computes a weighted "danger score" per zone using:
           danger_score = sum(severity) * recency_weight * time_weight
       - Recent incidents count more than old ones
       - Night/evening incidents count more than daytime ones
    3. Normalizes danger scores to a 0-100 SAFETY SCORE per zone
       (100 = safest, 0 = most dangerous)
    4. Exports:
        - mumbai_zone_safety_scores.csv   (zone_id, lat, lon, safety_score)
        - mumbai_crime_heatmap.png        (visual heatmap of danger zones)

This zone_safety_scores.csv is the file that Feature 1 (Safest Route
Suggestion) will consume in Week 3: each candidate route's polyline
will be checked against which zones it passes through, and a route's
overall safety = average safety_score of the zones it crosses.
"""

import csv
import math
from collections import defaultdict
from datetime import datetime

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

INPUT_CSV = "nerul_crime_data.csv"
ZONE_OUTPUT_CSV = "nerul_zone_safety_scores.csv"
HEATMAP_OUTPUT_PNG = "nerul_crime_heatmap.png"

# Grid cell size in degrees (~0.0018 deg ≈ 200m at this latitude).
# Nerul is a much smaller area than all of Mumbai, so a finer grid gives
# more meaningful zone-level resolution for route scoring.
CELL_SIZE = 0.0018

TIME_WEIGHT = {
    "Morning (6-12)": 0.7,
    "Afternoon (12-17)": 0.8,
    "Evening (17-21)": 1.2,
    "Night (21-6)": 1.5,
}

REFERENCE_DATE = datetime(2026, 1, 1)  # "today" for recency weighting
HALF_LIFE_DAYS = 365  # incidents lose half their weight every ~1 year


def recency_weight(date_str):
    incident_date = datetime.strptime(date_str, "%Y-%m-%d")
    age_days = (REFERENCE_DATE - incident_date).days
    age_days = max(age_days, 0)
    return 0.5 ** (age_days / HALF_LIFE_DAYS)


def zone_id_for(lat, lon):
    row = math.floor(lat / CELL_SIZE)
    col = math.floor(lon / CELL_SIZE)
    return (row, col)


def zone_center(zone_id):
    row, col = zone_id
    return (
        round((row + 0.5) * CELL_SIZE, 6),
        round((col + 0.5) * CELL_SIZE, 6),
    )


def load_incidents(path):
    incidents = []
    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        for r in reader:
            incidents.append(r)
    return incidents


def compute_zone_scores(incidents):
    zone_danger = defaultdict(float)
    zone_incident_count = defaultdict(int)

    for r in incidents:
        lat, lon = float(r["latitude"]), float(r["longitude"])
        zid = zone_id_for(lat, lon)

        severity = int(r["severity"])
        t_weight = TIME_WEIGHT.get(r["time_of_day"], 1.0)
        r_weight = recency_weight(r["date"])

        danger_contrib = severity * t_weight * r_weight
        zone_danger[zid] += danger_contrib
        zone_incident_count[zid] += 1

    return zone_danger, zone_incident_count


def normalize_to_safety_score(zone_danger):
    values = list(zone_danger.values())
    min_d, max_d = min(values), max(values)
    safety_scores = {}
    for zid, danger in zone_danger.items():
        if max_d == min_d:
            norm = 0.0
        else:
            norm = (danger - min_d) / (max_d - min_d)  # 0 (safe) -> 1 (dangerous)
        safety_scores[zid] = round((1 - norm) * 100, 2)  # flip: 100 = safest
    return safety_scores


def export_zone_csv(zone_danger, zone_incident_count, safety_scores, path):
    with open(path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["zone_id", "center_lat", "center_lon",
                          "incident_count", "raw_danger_score", "safety_score_0to100"])
        for zid in zone_danger:
            lat, lon = zone_center(zid)
            writer.writerow([
                f"{zid[0]}_{zid[1]}",
                lat, lon,
                zone_incident_count[zid],
                round(zone_danger[zid], 2),
                safety_scores[zid],
            ])
    print(f"Exported {len(zone_danger)} zones -> {path}")


def plot_heatmap(zone_danger, safety_scores, path):
    lats, lons, colors = [], [], []
    for zid in zone_danger:
        lat, lon = zone_center(zid)
        lats.append(lat)
        lons.append(lon)
        colors.append(100 - safety_scores[zid])  # plot danger (inverse of safety)

    plt.figure(figsize=(9, 9))
    sc = plt.scatter(lons, lats, c=colors, cmap="RdYlGn_r", s=180, marker="s", alpha=0.85)
    plt.colorbar(sc, label="Danger Level (0=safe, 100=high risk)")
    plt.title("Navi Mumbai (Nerul) Simulated Crime Density Heatmap (Zone-wise)")
    plt.xlabel("Longitude")
    plt.ylabel("Latitude")
    plt.grid(alpha=0.2)
    plt.tight_layout()
    plt.savefig(path, dpi=150)
    print(f"Saved heatmap visualization -> {path}")


def main():
    incidents = load_incidents(INPUT_CSV)
    zone_danger, zone_incident_count = compute_zone_scores(incidents)
    safety_scores = normalize_to_safety_score(zone_danger)

    export_zone_csv(zone_danger, zone_incident_count, safety_scores, ZONE_OUTPUT_CSV)
    plot_heatmap(zone_danger, safety_scores, HEATMAP_OUTPUT_PNG)

    # Quick console summary for sanity-check
    sorted_zones = sorted(safety_scores.items(), key=lambda x: x[1])
    print("\nTop 5 most dangerous zones (lowest safety score):")
    for zid, score in sorted_zones[:5]:
        lat, lon = zone_center(zid)
        print(f"  Zone {zid} @ ({lat},{lon}) -> safety_score={score}")

    print("\nTop 5 safest zones:")
    for zid, score in sorted_zones[-5:]:
        lat, lon = zone_center(zid)
        print(f"  Zone {zid} @ ({lat},{lon}) -> safety_score={score}")


if __name__ == "__main__":
    main()
