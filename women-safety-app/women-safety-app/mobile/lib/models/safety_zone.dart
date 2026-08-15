/// One graded zone from the Week 1 crime-data-pipeline output
/// (assets/data/nerul_zone_safety_scores.csv). See data-pipeline/README.md
/// for how these scores were calculated.
class SafetyZone {
  final double centerLat;
  final double centerLon;
  final int incidentCount;
  final double safetyScore; // 0-100, 100 = safest

  SafetyZone({
    required this.centerLat,
    required this.centerLon,
    required this.incidentCount,
    required this.safetyScore,
  });
}
