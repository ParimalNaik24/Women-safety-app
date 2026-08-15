import 'package:google_maps_flutter/google_maps_flutter.dart';

/// One candidate route returned by Google Directions API
/// (requested with alternatives=true), plus the safety score
/// SafetyScoreService computed for it.
class RouteOption {
  final List<LatLng> points;
  final String distanceText;
  final String durationText;
  double safetyScore; // filled in after scoring, 0-100

  RouteOption({
    required this.points,
    required this.distanceText,
    required this.durationText,
    this.safetyScore = 0,
  });
}
