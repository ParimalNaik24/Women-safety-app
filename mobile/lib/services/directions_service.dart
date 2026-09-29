import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_option.dart';

/// Calls the Google Routes API (computeRoutes, WALK, alternatives on).
/// Google's old Directions API can no longer be enabled on new projects.
/// Throws an Exception with a readable message on any failure so the
/// screen can show the real reason instead of a generic error.
class DirectionsService {
  final String apiKey;
  DirectionsService(this.apiKey);

  Future<List<RouteOption>> fetchRouteAlternatives({
    required String origin, // "lat,lng"
    required String destination, // place name or address
  }) async {
    final parts = origin.split(',');
    final body = jsonEncode({
      'origin': {
        'location': {
          'latLng': {
            'latitude': double.parse(parts[0]),
            'longitude': double.parse(parts[1]),
          }
        }
      },
      'destination': {'address': destination},
      'travelMode': 'WALK',
      'computeAlternativeRoutes': true,
      'polylineQuality': 'HIGH_QUALITY',
      'regionCode': 'IN',
      'languageCode': 'en-IN',
      'units': 'METRIC',
    });

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes'),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': apiKey,
              'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,'
                  'routes.description,routes.polyline.encodedPolyline',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 20));
    } on SocketException {
      throw Exception('No internet connection');
    } catch (_) {
      throw Exception('Could not reach Google. Check your internet.');
    }

    if (response.statusCode == 403) {
      throw Exception(
          'Request denied: enable Routes API + billing, and add Routes API to the key restrictions');
    }
    if (response.statusCode == 404) {
      throw Exception('Destination not found. Try a more specific place name');
    }
    if (response.statusCode != 200) {
      String msg = 'HTTP ${response.statusCode}';
      try {
        msg = jsonDecode(response.body)['error']['message'] as String;
      } catch (_) {}
      throw Exception('Routes error: $msg');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw Exception('No walking route found. Try a more specific place name');
    }

    return routes.map<RouteOption>((route) {
      // duration comes back as a string like "1234s"
      final seconds =
          int.tryParse((route['duration'] as String? ?? '0s').replaceAll('s', '')) ?? 0;
      return RouteOption(
        points: _decodePolyline(route['polyline']['encodedPolyline'] as String),
        distanceMeters: (route['distanceMeters'] as num? ?? 0).toDouble(),
        durationSeconds: seconds,
        summary: (route['description'] as String?) ?? '',
      );
    }).toList();
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
