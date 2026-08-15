import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_option.dart';

/// Calls the Google Directions API. Week 2 used this for a single basic
/// route; Week 3 requests alternatives=true to get 2-3 candidate routes,
/// which SafetyScoreService then scores so MapScreen can rank them.
class DirectionsService {
  final String apiKey;
  DirectionsService(this.apiKey);

  /// Fetches route alternatives between [originAddressOrLatLng] and
  /// [destinationQuery]. Both can be a "lat,lng" string OR a place name /
  /// address -- Google's Directions API accepts either directly, so we
  /// don't need a separate geocoding call for the destination search box.
  Future<List<RouteOption>> fetchRouteAlternatives({
    required String origin,
    required String destination,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=$origin'
      '&destination=$destination'
      '&mode=walking'
      '&alternatives=true'
      '&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) return [];

    final json = jsonDecode(response.body);
    final routes = json['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return [];

    return routes.map<RouteOption>((route) {
      final overviewPolyline = route['overview_polyline']['points'] as String;
      final points = _decodePolyline(overviewPolyline);

      // A route can have multiple "legs" if waypoints are used -- we only
      // ever request a single origin->destination, so there's just one leg.
      final leg = (route['legs'] as List<dynamic>).first;
      final distanceText = leg['distance']['text'] as String;
      final durationText = leg['duration']['text'] as String;

      return RouteOption(
        points: points,
        distanceText: distanceText,
        durationText: durationText,
      );
    }).toList();
  }

  /// Standard Google encoded-polyline decoding algorithm -- the Directions
  /// API returns each route's shape as a compact encoded string, not a
  /// plain list of coordinates.
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
