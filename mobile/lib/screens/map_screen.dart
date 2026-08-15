import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../config.dart';
import '../models/route_option.dart';
import '../services/directions_service.dart';
import '../services/safety_score_service.dart';

/// WEEK 2 scope: request location permission, show current location on
/// the map with a marker.
///
/// WEEK 3 scope (this is the Feature 1 "Safest Route" implementation):
///   1. User types a destination.
///   2. DirectionsService fetches 2-3 alternative walking routes.
///   3. SafetyScoreService scores each route using the Week 1 crime-data
///      pipeline's zone safety scores, and ranks them safest-first.
///   4. All routes are drawn on the map -- the safest in solid green,
///      others in dashed grey -- with a bottom panel listing each
///      route's distance, duration, and safety score so the user can
///      see WHY the recommended route was chosen, not just trust a
///      black box.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final _destinationController = TextEditingController();
  final _directionsService = DirectionsService(googleMapsApiKey);
  final _safetyScoreService = SafetyScoreService();

  LatLng? _currentLatLng;
  List<RouteOption> _routes = [];
  int _selectedRouteIndex = 0;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _determineCurrentPosition();
  }

  Future<void> _determineCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showMessage('Location permission is needed to show your position on the map');
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLatLng = LatLng(position.latitude, position.longitude);
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng!, 15));
  }

  Future<void> _findSafeRoute() async {
    final destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      _showMessage('Enter a destination');
      return;
    }
    if (_currentLatLng == null) {
      _showMessage('Still finding your current location, try again in a moment');
      return;
    }

    setState(() => _isSearching = true);

    final origin = '${_currentLatLng!.latitude},${_currentLatLng!.longitude}';
    final rawRoutes = await _directionsService.fetchRouteAlternatives(
      origin: origin,
      destination: destination,
    );

    if (rawRoutes.isEmpty) {
      setState(() => _isSearching = false);
      // Expected until a real API key with billing enabled is added --
      // see mobile/README.md for setup instructions.
      _showMessage('Could not find a route. Check your API key / destination spelling.');
      return;
    }

    final rankedRoutes = await _safetyScoreService.scoreAndRankRoutes(rawRoutes);

    setState(() {
      _routes = rankedRoutes;
      _selectedRouteIndex = 0; // index 0 is always the safest after ranking
      _isSearching = false;
    });

    _fitCameraToRoute(rankedRoutes.first);
  }

  void _fitCameraToRoute(RouteOption route) {
    if (route.points.isEmpty || _mapController == null) return;

    double minLat = route.points.first.latitude, maxLat = route.points.first.latitude;
    double minLng = route.points.first.longitude, maxLng = route.points.first.longitude;
    for (final point in route.points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
        60, // padding in pixels
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score < 30) return Colors.red;
    if (score < 70) return Colors.orange;
    return Colors.green;
  }

  Set<Polyline> _buildPolylines() {
    final polylines = <Polyline>{};
    for (int i = 0; i < _routes.length; i++) {
      final isSelected = i == _selectedRouteIndex;
      final isSafest = i == 0; // routes are pre-sorted safest-first
      polylines.add(Polyline(
        polylineId: PolylineId('route_$i'),
        points: _routes[i].points,
        color: isSelected
            ? (isSafest ? Colors.green : Colors.purple)
            : Colors.grey.withOpacity(0.5),
        width: isSelected ? 6 : 3,
        patterns: isSelected ? [] : [PatternItem.dash(12), PatternItem.gap(8)],
      ));
    }
    return polylines;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Safe Route'),
        backgroundColor: const Color(0xFF8E24AA),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _destinationController,
                    decoration: const InputDecoration(
                      hintText: 'Enter destination (e.g. Seawoods Grand Central)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSearching ? null : _findSafeRoute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E24AA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                  child: _isSearching
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search),
                ),
              ],
            ),
          ),
          Expanded(
            child: _currentLatLng == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(target: _currentLatLng!, zoom: 15),
                    onMapCreated: (controller) => _mapController = controller,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    polylines: _buildPolylines(),
                    markers: _currentLatLng == null
                        ? {}
                        : {
                            Marker(
                              markerId: const MarkerId('current_location'),
                              position: _currentLatLng!,
                              infoWindow: const InfoWindow(title: 'You are here'),
                            ),
                          },
                  ),
          ),
          if (_routes.isNotEmpty) _buildRoutePanel(),
        ],
      ),
    );
  }

  Widget _buildRoutePanel() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 160),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _routes.length,
        itemBuilder: (context, index) {
          final route = _routes[index];
          final isSafest = index == 0;
          final isSelected = index == _selectedRouteIndex;
          return ListTile(
            selected: isSelected,
            selectedTileColor: const Color(0xFFF3E5F5),
            leading: CircleAvatar(
              backgroundColor: _scoreColor(route.safetyScore),
              child: Text(
                route.safetyScore.toStringAsFixed(0),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(isSafest ? 'Safest Route' : 'Alternative Route ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${route.distanceText} · ${route.durationText} · Safety score ${route.safetyScore.toStringAsFixed(0)}/100'),
            onTap: () {
              setState(() => _selectedRouteIndex = index);
              _fitCameraToRoute(route);
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }
}
