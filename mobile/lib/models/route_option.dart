import 'package:google_maps_flutter/google_maps_flutter.dart';

/// One candidate route returned by Google Directions API
/// (requested with alternatives=true), plus the safety score
/// SafetyScoreService computed for it.
class RouteOption {
  final List<LatLng> points;
  final double distanceMeters;
  final int durationSeconds;
  final String summary; // route name, e.g. "Palm Beach Rd"
  double safetyScore; // filled in after scoring, 0-100 (100 = safest)
  bool isSafest;
  bool isFastest;

  RouteOption({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.summary = '',
    this.safetyScore = 0,
    this.isSafest = false,
    this.isFastest = false,
  });

  String get distanceText => distanceMeters >= 1000
      ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
      : '${distanceMeters.round()} m';

  String get durationText => durationSeconds >= 3600
      ? '${durationSeconds ~/ 3600} h ${(durationSeconds % 3600 / 60).round()} min'
      : '${(durationSeconds / 60).round()} min';
}
