import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/safety_zone.dart';
import '../models/route_option.dart';

/// Scores each candidate route against the Week 1 crime-zone safety scores.
///
/// HOW IT WORKS:
///   1. The route is sampled every [sampleEveryM] metres.
///   2. Each sample takes the safety score of the nearest zone, using true
///      (haversine) distance. If no zone is within [zoneRadiusM], a neutral
///      [defaultScore] is used instead of a wrong far-away zone's score.
///   3. Route score = 70% average + 30% average of the worst 20% of samples,
///      so one dangerous stretch cannot hide among many safe ones.
///   4. "Safest" is chosen only among routes no slower than
///      [maxTimeFactor] x the fastest route, so there is no huge detour.
class SafetyScoreService {
  // ---- Tunable settings ----
  static const double sampleEveryM = 30;
  static const double zoneRadiusM = 250;
  static const double defaultScore = 80;
  static const double maxTimeFactor = 1.5;
  static const double avgWeight = 0.7;
  static const double worstFraction = 0.2;

  List<SafetyZone> _zones = [];
  bool _loaded = false;

  Future<void> loadZones() async {
    if (_loaded) return;

    final raw = await rootBundle.loadString('assets/data/nerul_zone_safety_scores.csv');
    final rows = const CsvToListConverter(shouldParseNumbers: true, eol: '\n')
        .convert(raw.replaceAll('\r', ''));

    // rows[0] is the header: zone_id, center_lat, center_lon, incident_count,
    // raw_danger_score, safety_score_0to100
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

  double _scoreAt(LatLng p) {
    double bestDist = double.infinity;
    double bestScore = defaultScore;
    for (final z in _zones) {
      final d = _haversine(p.latitude, p.longitude, z.centerLat, z.centerLon);
      if (d < bestDist) {
        bestDist = d;
        bestScore = z.safetyScore;
      }
    }
    return bestDist <= zoneRadiusM ? bestScore : defaultScore;
  }

  double scoreRoute(List<LatLng> points) {
    if (_zones.isEmpty || points.isEmpty) return defaultScore;

    final samples = _samplePath(points, sampleEveryM);
    final scores = samples.map(_scoreAt).toList();

    final avg = scores.reduce((a, b) => a + b) / scores.length;
    final sorted = [...scores]..sort();
    final worstCount = max(1, (sorted.length * worstFraction).ceil());
    final worstAvg = sorted.take(worstCount).reduce((a, b) => a + b) / worstCount;

    return avgWeight * avg + (1 - avgWeight) * worstAvg;
  }

  /// Scores all routes, flags fastest and safest, and returns them with the
  /// safest route first, then the others by score.
  Future<List<RouteOption>> scoreAndRankRoutes(List<RouteOption> routes) async {
    await loadZones();
    for (final r in routes) {
      r.safetyScore = scoreRoute(r.points);
    }

    final fastest = routes.reduce((a, b) => a.durationSeconds <= b.durationSeconds ? a : b);
    fastest.isFastest = true;

    final eligible = routes
        .where((r) => r.durationSeconds <= fastest.durationSeconds * maxTimeFactor)
        .toList()
      ..sort((a, b) => b.safetyScore.compareTo(a.safetyScore));
    eligible.first.isSafest = true;

    routes.sort((a, b) {
      if (a.isSafest) return -1;
      if (b.isSafest) return 1;
      return b.safetyScore.compareTo(a.safetyScore);
    });
    return routes;
  }

  static List<LatLng> _samplePath(List<LatLng> path, double spacing) {
    if (path.length < 2) return List.of(path);
    final out = <LatLng>[path.first];
    double carry = 0;
    for (int i = 1; i < path.length; i++) {
      final a = path[i - 1], b = path[i];
      final seg = _haversine(a.latitude, a.longitude, b.latitude, b.longitude);
      if (seg == 0) continue;
      double pos = spacing - carry;
      while (pos <= seg) {
        final t = pos / seg;
        out.add(LatLng(a.latitude + (b.latitude - a.latitude) * t,
            a.longitude + (b.longitude - a.longitude) * t));
        pos += spacing;
      }
      carry = seg - (pos - spacing);
    }
    out.add(path.last);
    return out;
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1), dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return 2 * r * asin(sqrt(a));
  }

  static double _rad(double d) => d * pi / 180;
}
