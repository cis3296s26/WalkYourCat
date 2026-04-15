// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';

// void showMapModal(BuildContext context) {
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     builder: (context) {
//       return SizedBox(
//         height: MediaQuery.of(context).size.height * 0.75,
//         child: const MapModalContent(),
//       );
//     },
//   );
// }

// class MapModalContent extends StatelessWidget {
//   const MapModalContent({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         const SizedBox(height: 10),
//         Container(
//           width: 40,
//           height: 5,
//           decoration: BoxDecoration(
//             color: Colors.grey,
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//         const SizedBox(height: 10),
//         const Text(
//           "Map",
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 10),
//         const Expanded(child: MapModalService()),
//       ],
//     );
//   }
// }

// class MapModalService extends StatefulWidget {
//   const MapModalService({super.key});

//   @override
//   State<MapModalService> createState() => _MapModalServiceState();
// }

// class _MapModalServiceState extends State<MapModalService> {
//   LatLng _currentLocation = const LatLng(39.9812, -75.1554);
//   final MapController _mapController = MapController();
//   StreamSubscription<Position>? _positionSubscription;

//   @override
//   void initState() {
//     super.initState();
//     _initLocation();
//   }

//   Future<void> _initLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) return;

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) return;
//     }
//     if (permission == LocationPermission.deniedForever) return;

//     final position = await Geolocator.getCurrentPosition();
//     if (mounted) {
//       setState(() {
//         _currentLocation = LatLng(position.latitude, position.longitude);
//       });
//       _mapController.move(_currentLocation, 17.0);
//     }

//     _positionSubscription = Geolocator.getPositionStream(
//       locationSettings: const LocationSettings(
//         accuracy: LocationAccuracy.high,
//         distanceFilter: 5,
//       ),
//     ).listen((Position position) {
//       if (mounted) {
//         setState(() {
//           _currentLocation = LatLng(position.latitude, position.longitude);
//         });
//         _mapController.move(_currentLocation, _mapController.camera.zoom);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _positionSubscription?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FlutterMap(
//       mapController: _mapController,
//       options: MapOptions(
//         initialCenter: _currentLocation,
//         initialZoom: 17.0,
//         keepAlive: true,
//       ),
//       children: [
//         TileLayer(
//           urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//           userAgentPackageName: 'app',
//         ),
//         MarkerLayer(
//           markers: [
//             Marker(
//               point: _currentLocation,
//               width: 40,
//               height: 40,
//               child: const Text(
//                 '🐱',
//                 style: TextStyle(fontSize: 30),
//               ),
//             ),
//           ],
//         ),
//         RichAttributionWidget(
//           attributions: [
//             TextSourceAttribution('OpenStreetMap contributors'),
//           ],
//         ),
//       ],
//     );
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

enum TrailStatus { locked, active, completed }

class NearbyPlace {
  final String id;
  final String name;
  final String type;
  final LatLng center;
  final List<LatLng> boundary;
  final int coinReward;
  final Color color;

  TrailStatus status;
  double walkedFraction;
  final Set<String> _visitedSegments = {};

  NearbyPlace({
    required this.id,
    required this.name,
    required this.type,
    required this.center,
    required this.boundary,
    required this.coinReward,
    required this.color,
    this.status = TrailStatus.locked,
    this.walkedFraction = 0.0,
  });

  /// Total perimeter in meters
  double get perimeterMeters {
    if (boundary.length < 2) return 0;
    const Distance d = Distance();
    double total = 0;
    for (int i = 0; i < boundary.length - 1; i++) {
      total += d.as(LengthUnit.Meter, boundary[i], boundary[i + 1]);
    }
    return total;
  }

  /// Perimeter in miles
  double get perimeterMiles => perimeterMeters / 1609.344;

  /// Estimated walk time in minutes at ~80 m/min casual pace
  int get estimatedMinutes => (perimeterMeters / 80).ceil().clamp(1, 999);

  /// Estimated steps — ~2112 steps per mile
  int get estimatedSteps => (perimeterMiles * 2112).round().clamp(100, 999999);

  void checkUserPosition(LatLng userPos) {
    if (status == TrailStatus.completed || boundary.isEmpty) return;

    const Distance dist = Distance();
    for (int i = 0; i < boundary.length - 1; i++) {
      final segId = '$id-seg-$i';
      if (_visitedSegments.contains(segId)) continue;

      final segMid = LatLng(
        (boundary[i].latitude + boundary[i + 1].latitude) / 2,
        (boundary[i].longitude + boundary[i + 1].longitude) / 2,
      );
      final d = dist.as(LengthUnit.Meter, userPos, segMid);
      if (d < 40) _visitedSegments.add(segId);
    }

    final dCenter = dist.as(LengthUnit.Meter, userPos, center);
    if (dCenter < 60) _visitedSegments.add('$id-center');

    final totalPossible = boundary.length > 1 ? boundary.length - 1 : 1;
    walkedFraction =
        (_visitedSegments.length / totalPossible).clamp(0.0, 1.0);

    if (status == TrailStatus.locked &&
        (walkedFraction > 0 || dCenter < 200)) {
      status = TrailStatus.active;
    }

    if (walkedFraction >= 0.7 && status == TrailStatus.active) {
      status = TrailStatus.completed;
      walkedFraction = 1.0;
    }
  }
}
// Overpass API = a way to get map data from OpenStreetMap
// We use it to find parks, trails, and walking areas near the user

// Different Overpass servers (we try another if one fails)
const _overpassEndpoints = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass.openstreetmap.ru/api/interpreter',
];

Future<List<NearbyPlace>> fetchNearbyPlaces(LatLng center) async {
  // How far from the user we want to search (in meters)
  const double radiusMeters = 2500;

  // User's location
  final lat = center.latitude;
  final lon = center.longitude;

  // This query asks OpenStreetMap:
  // "Give me parks, trails, paths, and nature areas near this location"
  final query =
      '[out:json][timeout:30];' // return data as JSON
      '('
      'way["leisure"~"^(park|nature_reserve|recreation_ground|garden|common|pitch|dog_park)\$"]'
      '(around:$radiusMeters,$lat,$lon);'
      'way["landuse"~"^(recreation_ground|village_green|grass|forest|meadow)\$"]'
      '(around:$radiusMeters,$lat,$lon);'
      'way["route"="hiking"](around:$radiusMeters,$lat,$lon);'
      'way["highway"~"^(path|footway|cycleway|bridleway|track)\$"]["foot"!="no"]'
      '(around:$radiusMeters,$lat,$lon);'
      'way["natural"~"^(wood|scrub|heath|grassland|wetland)\$"]'
      '(around:$radiusMeters,$lat,$lon);'
      ');'
      'out geom;'; // include coordinates so we can draw the shape on the map

  http.Response? response;

  // Try each server until one works
  for (final endpoint in _overpassEndpoints) {
    try {
      response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 35));

      // Stop if we got a good response
      if (response.statusCode == 200 && response.body.startsWith('{')) break;
    } catch (_) {
      // If it fails, try the next server
      response = null;
    }
  }

  // If all servers fail, return nothing
  if (response == null || response.statusCode != 200) {
    debugPrint('Overpass: all endpoints failed');
    return [];
  }

  final Map<String, dynamic> data;

  try {
    // Convert the response into usable data
    data = jsonDecode(response.body) as Map<String, dynamic>;
  } catch (e) {
    // If something goes wrong reading it
    debugPrint('Overpass JSON parse error: $e');
    return [];
  }
  