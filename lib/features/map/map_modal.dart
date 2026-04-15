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
