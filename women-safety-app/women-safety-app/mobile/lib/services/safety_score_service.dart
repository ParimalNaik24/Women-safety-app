import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/safety_zone.dart';
import '../models/route_option.dart';

/// WEEK 3 CORE LOGIC.
///
/// Loads the zone-wise safety scores produced by the Week 1 Python
/// data-pipeline (data-pipeline/preprocess_crime_data.py ->
/// nerul_zone_safety_scores.csv, bundled here as a Flutter asset) and uses
/// them to score each candidate route DirectionsService returns.
///
/// HOW SCORING WORKS:
///   1. A route is a list of lat/lng points tracing its path.
///   2. For a sample of points along that path, find the NEAREST scored
///      zone (the CSV divides Nerul into ~200m grid cells -- see
///      data-pipeline/README.md for how those scores were calculated).
///   3. Average the safety scores of all sampled points -> the route's
///      overall safety score (0-100, 100 = safest).
///   4. MapScreen then ranks routes by this score and highlights the
///      safest one, instead of just picking the shortest.
class SafetyScoreService {
  List<SafetyZone> _zones = [];
  bool _loaded = false;

  Future<void> loadZones() async {
    if (_loaded) return;

    final raw = await rootBundle.loadString('assets/data/nerul_zone_safety_scores.csv');
    final rows = const CsvToListConverter(shouldParseNumbers: true).convert(raw);

    // rows[0] is the header: zone_id, center_lat, center_lon, incident_count,
    // raw_danger_score, safety_score_0to100 -- skip it.
    _zones = rows.skip(1).where((row) => row.length >= 6).map((row) {
      return SafetyZone(
        centerLat: (row[1] as num).toDouble(),
        centerLon: (row[2] as num).toDouble(),
        incidentCount: (row[3] as num).toInt(),
        safetyScore: (row[5] as num).toDouble(),
      );
    }).toList();

    _loaded = true;
  }

  /// Finds the zone whose center is closest to [point] using simple
  /// squared-distance comparison. Only ~236 zones exist for Nerul, so a
  /// plain linear scan is fast enough -- no need for a spatial index here.
  SafetyZone _nearestZone(LatLng point) {
    SafetyZone best = _zones.first;
    double bestDistSq = double.infinity;
    for (final zone in _zones) {
      final dLat = zone.centerLat - point.latitude;
      final dLon = zone.centerLon - point.longitude;
      final distSq = dLat * dLat + dLon * dLon;
      if (distSq < bestDistSq) {
        bestDistSq = distSq;
        best = zone;
      }
    }
    return best;
  }

  /// Scores a single route by averaging the safety scores of the zones
  /// its path passes through. Samples at most ~30 points along the route
  /// for performance instead of checking every single decoded point.
  double scoreRoute(List<LatLng> points) {
    if (_zones.isEmpty || points.isEmpty) return 50.0; // neutral fallback

    final sampleStep = (points.length / 30).ceil().clamp(1, points.length);
    double total = 0;
    int count = 0;
    for (int i = 0; i < points.length; i += sampleStep) {
      total += _nearestZone(points[i]).safetyScore;
      count++;
    }
    return count == 0 ? 50.0 : total / count;
  }

  /// Scores every route in [routes] in place, then returns them sorted
  /// SAFEST FIRST (highest safetyScore first). This is what MapScreen
  /// calls after fetching alternatives from DirectionsService.
  Future<List<RouteOption>> scoreAndRankRoutes(List<RouteOption> routes) async {
    await loadZones();
    for (final route in routes) {
      route.safetyScore = scoreRoute(route.points);
    }
    routes.sort((a, b) => b.safetyScore.compareTo(a.safetyScore));
    return routes;
  }
}
