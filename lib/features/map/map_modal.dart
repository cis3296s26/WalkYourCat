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
import 'package:shared_preferences/shared_preferences.dart';

import '../shop/shop_item.dart';
import '../shop/shop_service.dart';
import '../inventory/inventory_service.dart';

// trail can be locked (haven't started), active (currently walking it), or completed
enum TrailStatus { locked, active, completed }

// one walkable spot nearby — a park, trail
class NearbyPlace {
  final String id;
  final String name;
  final String type;           // 'park' | 'trail' | 'path'
  final LatLng center;
  final List<LatLng> boundary; // the actual OSM shape
  final Color color;

  // reward gets set by the shop after we load, don't set it yourself
  ShopItem? rewardItem;

  TrailStatus status;
  double walkedFraction;

  final Set<String> _visitedSegments = {};

  NearbyPlace({
    required this.id,
    required this.name,
    required this.type,
    required this.center,
    required this.boundary,
    required this.color,
    this.rewardItem,
    this.status = TrailStatus.locked,
    this.walkedFraction = 0.0,
  });

  // total walkable length of this path in meters, adds up all the little segments
  double get perimeterMeters {
    if (boundary.length < 2) return 0;
    const Distance d = Distance();
    double total = 0;
    for (int i = 0; i < boundary.length - 1; i++) {
      total += d.as(LengthUnit.Meter, boundary[i], boundary[i + 1]);
    }
    return total;
  }

  double get perimeterMiles => perimeterMeters / 1609.344;

  // rough walking time assuming avg person walks about 80 meters per minute
  int get estimatedMinutes => (perimeterMeters / 80).ceil().clamp(1, 999);

  // rough step count based on ~2112 steps per mile
  int get estimatedSteps => (perimeterMiles * 2112).round().clamp(100, 999999);

  String get distanceLabel {
    final miles = perimeterMiles;
    if (miles >= 0.1) return '${miles.toStringAsFixed(2)} mi';
    return '${(miles * 5280).round()} ft';
  }

  // called every GPS update — marks segments near us as visited, checks if we're done
  void checkUserPosition(LatLng userPos) {
    if (status == TrailStatus.completed || boundary.isEmpty) return;

    const Distance dist = Distance();

    // if we're within 40m of a segment's midpoint, count it as walked
    for (int i = 0; i < boundary.length - 1; i++) {
      final segId = '$id-seg-$i';
      if (_visitedSegments.contains(segId)) continue;

      final segMid = LatLng(
        (boundary[i].latitude  + boundary[i + 1].latitude)  / 2,
        (boundary[i].longitude + boundary[i + 1].longitude) / 2,
      );
      if (dist.as(LengthUnit.Meter, userPos, segMid) < 40) {
        _visitedSegments.add(segId);
      }
    }

    // also count the center so parks register even if we don't walk the whole boundary
    final dCenter = dist.as(LengthUnit.Meter, userPos, center);
    if (dCenter < 60) _visitedSegments.add('$id-center');

    final totalPossible = boundary.length > 1 ? boundary.length - 1 : 1;
    walkedFraction = (_visitedSegments.length / totalPossible).clamp(0.0, 1.0);

    // flip to active once the user enters the area or starts walking any segment
    if (status == TrailStatus.locked && (walkedFraction > 0 || dCenter < 200)) {
      status = TrailStatus.active;
    }

    // 70% coverage is good enough, nobody walks every single GPS node lol
    if (walkedFraction >= 0.7 && status == TrailStatus.active) {
      status = TrailStatus.completed;
      walkedFraction = 1.0;
    }
  }
}

// handles saving progress to SharedPrefs, resets itself every day at midnight
// stores completed trail IDs as a comma-joined string under today's date key
// also saves which shop item was rewarded per trail so reopening restores state without re-awarding
class _TrailPersistence {
  static const _kDateKey      = 'trail_date';           // YYYY-MM-DD of current tracking window
  static const _kIdsKey       = 'trail_completed_ids';  // comma-joined completed trail IDs
  static const _kRewardPrefix = 'trail_reward_';        // trail_reward_<trailId> -> shop item int id

  // today's date as YYYY-MM-DD, comparing this is how we know if we need to reset
  static String _today() {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  // load which trails were completed today
  static Future<Set<String>> loadCompletedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_kDateKey) ?? '';

    if (savedDate != _today()) {
      //reset all trail progress so you can walk them again
      await prefs.remove(_kIdsKey);
      await prefs.setString(_kDateKey, _today());
      final staleKeys = prefs.getKeys().where((k) => k.startsWith(_kRewardPrefix)).toList();
      for (final k in staleKeys) await prefs.remove(k);

      return {};
    }

    final raw = prefs.getString(_kIdsKey) ?? '';
    if (raw.isEmpty) return {};
    return raw.split(',').toSet();
  }

  // mark a trail as done + optionally save which item dropped, calling this twice is fine
  static Future<void> markCompleted(String trailId, {int? rewardItemId}) async {
    final prefs = await SharedPreferences.getInstance();

    // make sure the date key is set so tomorrow's load knows to reset
    await prefs.setString(_kDateKey, _today());

    // append this trail to the completed set
    final raw     = prefs.getString(_kIdsKey) ?? '';
    final current = raw.isEmpty ? <String>{} : raw.split(',').toSet();
    current.add(trailId);
    await prefs.setString(_kIdsKey, current.join(','));

    // save the reward item ID so we can restore it next time the app opens
    if (rewardItemId != null) {
      await prefs.setInt('$_kRewardPrefix$trailId', rewardItemId);
    }
  }

  // look up the saved shop item ID for a trail, returns null if nothing was saved
  static Future<int?> getRewardItemId(String trailId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_kRewardPrefix$trailId')
        ? prefs.getInt('$_kRewardPrefix$trailId')
        : null;
  }
}

// these are the Overpass API mirrors — we try them in order in case one is slow or down
const _overpassEndpoints = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass.openstreetmap.ru/api/interpreter',
];

// fetches everything walkable near us from OpenStreetMap via Overpass
// no minimum distance filter — we want to show ALL the options near us
Future<List<NearbyPlace>> fetchNearbyPlaces(LatLng center) async {
  const double radiusMeters = 8000; // ~5 miles radius, big enough to have options
  final lat = center.latitude;
  final lon = center.longitude;

  // querying parks, nature reserves, named footpaths, trails, cycleways, and hiking routes
  final query =
      '[out:json][timeout:25];'
      '('
      'way["leisure"~"^(park|nature_reserve|recreation_ground)\$"](around:$radiusMeters,$lat,$lon);'
      'way["highway"~"^(path|footway|cycleway|track)\$"]["name"](around:$radiusMeters,$lat,$lon);'
      'way["route"="hiking"](around:$radiusMeters,$lat,$lon);'
      ');'
      'out geom qt 200;'; // bumped to 200 so we actually get everything nearby

  http.Response? response;
  for (final endpoint in _overpassEndpoints) {
    try {
      debugPrint('[map] trying $endpoint');
      response = await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 && response.body.startsWith('{')) {
        debugPrint('[map] got a response from $endpoint, let\'s gooo');
        break;
      }
      debugPrint('[map] bad status ${response.statusCode} from $endpoint');
    } catch (e) {
      debugPrint('[map] $endpoint threw: $e');
      response = null;
    }
  }

  if (response == null || response.statusCode != 200) {
    debugPrint('[map] all endpoints failed rip');
    return [];
  }

  Map<String, dynamic> data;
  try {
    data = jsonDecode(response.body) as Map<String, dynamic>;
  } catch (e) {
    debugPrint('[map] json parse blew up: $e');
    return [];
  }

  final elements = (data['elements'] as List<dynamic>?) ?? [];
  debugPrint('[map] got ${elements.length} raw elements from overpass');

  // rotate through colors so each place looks distinct on the map
  const colors = [
    Color(0xFF2ECC71), Color(0xFF3498DB), Color(0xFFE67E22),
    Color(0xFF9B59B6), Color(0xFFE74C3C), Color(0xFF1ABC9C),
    Color(0xFFF39C12), Color(0xFF27AE60), Color(0xFF8E44AD),
    Color(0xFFD35400),
  ];

  final List<NearbyPlace> places = [];
  final Set<String> seenIds = {};
  int colorIndex = 0;
  const Distance distCalc = Distance();

  for (final el in elements) {
    // we only queried ways but just double checking in case something weird slips in
    if ((el['type'] as String? ?? '') != 'way') continue;

    final String elId = 'way-${el['id']}';
    if (seenIds.contains(elId)) continue;

    final tags = (el['tags'] as Map<String, dynamic>?) ?? {};

    String name =
        tags['name:en']       as String? ??
        tags['official_name'] as String? ??
        tags['name']          as String? ??
        tags['ref']           as String? ??
        '';

    if (name.isEmpty) {
      final leisure = tags['leisure'] as String?;
      final highway = tags['highway'] as String?;
      final route   = tags['route']   as String?;
      final natural = tags['natural'] as String?;
      final landuse = tags['landuse'] as String?;

      if      (leisure != null) name = '${_capitalize(leisure.replaceAll('_', ' '))} Park';
      else if (route   != null) name = '${_capitalize(route)} Trail';
      else if (highway != null) name = '${_capitalize(highway.replaceAll('_', ' '))} Trail';
      else if (landuse != null || natural != null) name = 'Neighborhood Park';
      else continue;
    }

    // figure out what kind of place this is
    final leisure = tags['leisure'] as String?;
    final highway = tags['highway'] as String?;
    final route   = tags['route']   as String?;
    final natural = tags['natural'] as String?;
    final landuse = tags['landuse'] as String?;

    String typeLabel = 'park';
    if (route   != null) typeLabel = 'trail';
    if (highway != null) typeLabel = 'path';
    // green space tags always win the type label battle
    if (leisure != null || natural != null || landuse != null) typeLabel = 'park';

    // parse the actual GPS points from the geometry
    final rawGeom = el['geometry'] as List<dynamic>? ?? [];
    final List<LatLng> boundary = rawGeom
        .map<LatLng?>((g) {
          final gLat = (g['lat'] as num?)?.toDouble();
          final gLon = (g['lon'] as num?)?.toDouble();
          if (gLat == null || gLon == null) return null;
          return LatLng(gLat, gLon);
        })
        .whereType<LatLng>()
        .toList();

    if (boundary.isEmpty) continue;

    // measure the actual walking distance — skip anything under 0.1 miles
    // we want to show short paths too, not just huge loops
    double totalMeters = 0;
    for (int i = 0; i < boundary.length - 1; i++) {
      totalMeters += distCalc.as(LengthUnit.Meter, boundary[i], boundary[i + 1]);
    }
    if (totalMeters < 160) continue; // ~0.1 mile minimum, tiny dead ends aren't useful

    // centroid = average of all boundary points
    final avgLat = boundary.map((p) => p.latitude).reduce((a, b) => a + b)  / boundary.length;
    final avgLon = boundary.map((p) => p.longitude).reduce((a, b) => a + b) / boundary.length;
    final placeCenter = LatLng(avgLat, avgLon);

    // if the centroid ended up way outside our radius, skip it
    if (distCalc.as(LengthUnit.Meter, center, placeCenter) > radiusMeters * 1.2) continue;

    seenIds.add(elId);
    places.add(NearbyPlace(
      id: elId, name: name, type: typeLabel,
      center: placeCenter, boundary: boundary,
      color: colors[colorIndex % colors.length],
    ));

    colorIndex++;
    if (places.length >= 150) break;
  }

  debugPrint('[map] ${places.length} places found (≥0.1 mi, within ~5 miles)');

  // sort nearest-first so the bottom cards are actually useful
  places.sort((a, b) => distCalc
      .as(LengthUnit.Meter, center, a.center)
      .compareTo(distCalc.as(LengthUnit.Meter, center, b.center)));

  return places;
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// maps shop item tags to emojis — these have to match what shop_item.dart uses exactly
String _tagEmoji(String tag) {
  switch (tag) {
    case 'food':     return '🍞';
    case 'drinks':   return '🥤';
    case 'medicine': return '💊';
    case 'fun':      return '🎾';
    case 'cosmetic': return '👓';
    default:         return '📦';
  }
}

// opens the map as a bottom sheet modal
void showMapModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: const MapModalContent(),
    ),
  );
}

// outer shell with the drag handle, title bar, then the map below it
class MapModalContent extends StatelessWidget {
  const MapModalContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1923),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: const Column(
        children: [
          SizedBox(height: 10),
          _DragHandle(),
          SizedBox(height: 10),
          Text(
            '🐾  Trail Explorer',
            style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold,
              color: Colors.white, letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: 10),
          Expanded(child: MapModalService()),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 5,
      decoration: BoxDecoration(
        color: Colors.grey, borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

// main stateful widget that handles location, data fetching, and the reward flow
class MapModalService extends StatefulWidget {
  const MapModalService({super.key});

  @override
  State<MapModalService> createState() => _MapModalServiceState();
}

class _MapModalServiceState extends State<MapModalService>
    with TickerProviderStateMixin {

  // defaulting to philly until GPS actually fires
  LatLng _currentLocation = const LatLng(39.9812, -75.1554);
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;

  List<NearbyPlace> _places    = [];
  List<ShopItem>    _shopItems = [];
  bool   _loading    = true;
  String _loadingMsg = 'Getting your location…';

  // controls whether the reward pop-up is showing and what it says
  bool      _showReward      = false;
  ShopItem? _rewardItem;
  String    _rewardPlaceName = '';

  late AnimationController _rewardAnim;
  late Animation<double>   _rewardScale;
  late Animation<double>   _rewardOpacity;

  @override
  void initState() {
    super.initState();
    _setupRewardAnimation();
    _initApp();
  }

  // bounces in with elastic curve, fades out toward the end like a nice lil popup
  void _setupRewardAnimation() {
    _rewardAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800));
    _rewardScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _rewardAnim, curve: Curves.elasticOut));
    _rewardOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _rewardAnim,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut)));
  }

  Future<void> _initApp() async {
    // load shop items first so reward assignment is ready right after places load
    try {
      _shopItems = await ShopService.loadShopAssets();
    } catch (e) {
      debugPrint('[map] shop load failed lol: $e');
      _shopItems = [];
    }
    await _initLocation();
  }

  // assigns rewards based on walking distance tier, all items come from shop_item.dart
  //   0.1–2 mi  → food / drinks   (easy walk, grab a snack)
  //   2–4 mi    → medicine / fun  (decent effort, decent drop)
  //   4+ mi     → cosmetic        (big walk, rare item, treat yourself)
  void _assignRewards() {
    if (_shopItems.isEmpty) return;

    final tier0 = _shopItems.where((i) => i.tag == 'food'     || i.tag == 'drinks').toList();
    final tier1 = _shopItems.where((i) => i.tag == 'medicine' || i.tag == 'fun').toList();
    final tier2 = _shopItems.where((i) => i.tag == 'cosmetic').toList();

    for (final place in _places) {
      final miles = place.perimeterMiles;

      // fall back up the tier chain if a tier happens to be empty
      List<ShopItem> pool;
      if      (miles >= 4.0 && tier2.isNotEmpty) pool = tier2;
      else if (miles >= 2.0 && tier1.isNotEmpty) pool = tier1;
      else if (tier0.isNotEmpty)                 pool = tier0;
      else                                       pool = _shopItems; // just use everything if tiers are empty

      // deterministic hash so same trail always gives same item each day, no randomness
      place.rewardItem = pool[place.id.hashCode.abs() % pool.length];
    }
  }

  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() { _loadingMsg = 'Location services are off'; _loading = false; });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() { _loadingMsg = 'Location permission denied'; _loading = false; });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() { _loadingMsg = 'Location permission permanently denied'; _loading = false; });
      return;
    }

    // one-shot fix to get the map moving before Overpass responds
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _loadingMsg = 'Finding trails & parks within 5 miles…';
    });
    _mapController.move(_currentLocation, 14.0);

    // hit overpass API
    final places = await fetchNearbyPlaces(_currentLocation);
    if (!mounted) return;

    _places = places;
    _assignRewards();

    // restore completed state from SharedPrefs
    // this is key — on reopen we restore which trails were done today and which item
    // was collected, so it looks right without accidentally re-awarding inventory items
    final completedIds = await _TrailPersistence.loadCompletedToday();
    for (final place in _places) {
      if (!completedIds.contains(place.id)) continue;

      place.status        = TrailStatus.completed;
      place.walkedFraction = 1.0;

      // if the reward wasn't assigned above somehow, restore it from prefs
      if (place.rewardItem == null && _shopItems.isNotEmpty) {
        final savedId = await _TrailPersistence.getRewardItemId(place.id);
        if (savedId != null) {
          place.rewardItem = _shopItems.firstWhere(
            (i) => i.id == savedId,
            orElse: () => _shopItems.first,
          );
        }
      }
    }

    setState(() => _loading = false);

    // start streaming GPS updates for walk tracking
    // distanceFilter: 5 means only fires when user moves 5+ meters, saves battery
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);
  }

  // fires on every GPS update — checks if any trail just got completed
  void _onPosition(Position pos) {
    if (!mounted) return;
    final loc = LatLng(pos.latitude, pos.longitude);

    setState(() => _currentLocation = loc);
    _mapController.move(loc, _mapController.camera.zoom);

    for (final place in _places) {
      final prevStatus = place.status;
      place.checkUserPosition(loc);

      // if this GPS update flipped a trail to completed, time to hand out the loot
      if (place.status == TrailStatus.completed &&
          prevStatus != TrailStatus.completed) {
        _awardItem(place);
      }
    }

    setState(() {}); // re-render so progress bars update
  }

  // saves completion to prefs, adds item to inventory, shows the popup
  Future<void> _awardItem(NearbyPlace place) async {
    // persist so next app open shows this trail as done
    await _TrailPersistence.markCompleted(
      place.id,
      rewardItemId: place.rewardItem?.id,
    );

    // same addItem call as the shop, goes straight to inventory
    if (place.rewardItem != null) {
      await InventoryService.instance.addItem(place.rewardItem!);
    }

    if (!mounted) return;
    setState(() {
      _rewardItem      = place.rewardItem;
      _rewardPlaceName = place.name;
      _showReward      = true;
    });

    // run the animation then hide the popup
    _rewardAnim.forward(from: 0).then((_) {
      if (mounted) setState(() => _showReward = false);
    });
  }

  // manual complete button from the detail sheet — same flow as GPS auto-complete
  void _manualComplete(NearbyPlace place) {
    if (place.status == TrailStatus.completed) return;
    setState(() {
      place.status        = TrailStatus.completed;
      place.walkedFraction = 1.0;
    });
    _awardItem(place);
  }

  void _showPlaceDetail(NearbyPlace place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PlaceDetailSheet(
        place: place,
        onComplete: () {
          Navigator.pop(ctx);
          _manualComplete(place);
        },
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _rewardAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        // the actual map — OpenStreetMap tiles with polylines and markers on top
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation,
            initialZoom: 14.0,
            keepAlive: true,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'app',
            ),

            // colored outlines for each nearby place
            if (_places.isNotEmpty)
              PolylineLayer(
                polylines: _places
                    .where((p) => p.boundary.length > 1)
                    .map<Polyline>((p) => Polyline(
                          points: p.boundary,
                          color: p.color.withOpacity(
                            p.status == TrailStatus.completed ? 1.0 : 0.55),
                          strokeWidth: p.status == TrailStatus.completed ? 4.5 : 2.5,
                        ))
                    .toList(),
              ),

            // floating name + reward labels over each place
            if (_places.isNotEmpty)
              MarkerLayer(
                markers: _places
                    .map((p) => Marker(
                          point: p.center,
                          width: 140, height: 52,
                          child: _PlaceLabel(place: p),
                        ))
                    .toList(),
              ),

            // lil cat at user's current position
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLocation,
                  width: 40, height: 40,
                  child: const Text('🐱', style: TextStyle(fontSize: 30)),
                ),
              ],
            ),

            RichAttributionWidget(
              attributions: [TextSourceAttribution('OpenStreetMap contributors')],
            ),
          ],
        ),

        // loading overlay while we wait for GPS + Overpass
        if (_loading)
          Container(
            color: const Color(0xFF0F1923).withOpacity(0.85),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF2ECC71), strokeWidth: 2.5),
                  const SizedBox(height: 16),
                  Text(_loadingMsg,
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  const Text('(this may take a few seconds)',
                      style: TextStyle(color: Colors.white30, fontSize: 11)),
                ],
              ),
            ),
          ),

        // empty state when Overpass comes back with nothing
        if (!_loading && _places.isEmpty)
          Positioned(
            top: 16, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2535).withOpacity(0.97),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No trails or parks found nearby.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() { _loading = true; _loadingMsg = 'Retrying…'; });
                      fetchNearbyPlaces(_currentLocation).then((places) {
                        if (!mounted) return;
                        _places = places;
                        _assignRewards();
                        setState(() => _loading = false);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2ECC71)),
                      ),
                      child: const Text('Retry',
                          style: TextStyle(color: Color(0xFF2ECC71),
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // re-center button top left
        Positioned(
          top: 12, left: 12,
          child: GestureDetector(
            onTap: () => _mapController.move(_currentLocation, 14.0),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2535).withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.my_location, color: Color(0xFF2ECC71), size: 20),
            ),
          ),
        ),

        // horizontal scrollable cards at the bottom
        if (!_loading && _places.isNotEmpty)
          Positioned(
            bottom: 12, left: 0, right: 0,
            child: _PlaceLegend(
              places: _places,
              onTap: (p) {
                _mapController.move(p.center, 15.5);
                _showPlaceDetail(p);
              },
            ),
          ),

        // reward popup after completing a trail
        if (_showReward)
          Center(
            child: AnimatedBuilder(
              animation: _rewardAnim,
              builder: (ctx, _) => Opacity(
                opacity: _rewardOpacity.value,
                child: Transform.scale(
                  scale: _rewardScale.value,
                  child: _RewardBurst(
                    item: _rewardItem,
                    placeName: _rewardPlaceName,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// floating label on the map showing the place name + reward preview
class _PlaceLabel extends StatelessWidget {
  final NearbyPlace place;
  const _PlaceLabel({required this.place});

  @override
  Widget build(BuildContext context) {
    final isComplete = place.status == TrailStatus.completed;
    final labelColor = isComplete ? const Color(0xFFFFD700) : place.color;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // name pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: labelColor.withOpacity(0.92),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isComplete)
                const Text('✓ ', style: TextStyle(color: Colors.black, fontSize: 9)),
              Flexible(
                child: Text(
                  place.name,
                  style: TextStyle(
                    color: isComplete ? Colors.black : Colors.white,
                    fontSize: 9, fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 3),

        // reward preview below the name pill using shop tag emojis
        if (!isComplete && place.rewardItem != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2535).withOpacity(0.93),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: place.color.withOpacity(0.6), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_tagEmoji(place.rewardItem!.tag),
                    style: const TextStyle(fontSize: 8)),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    place.rewardItem!.name,
                    style: TextStyle(
                      color: place.color, fontSize: 8, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )
        else if (isComplete && place.rewardItem != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFFD700), width: 1),
            ),
            child: const Text('✓ collected',
                style: TextStyle(
                  color: Color(0xFFFFD700), fontSize: 8, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}

// bottom horizontal scroll list of place cards
class _PlaceLegend extends StatelessWidget {
  final List<NearbyPlace> places;
  final void Function(NearbyPlace) onTap;
  const _PlaceLegend({required this.places, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: places.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onTap(places[i]),
          child: _PlaceCard(place: places[i]),
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final NearbyPlace place;
  const _PlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    final isComplete  = place.status == TrailStatus.completed;
    final borderColor = isComplete ? const Color(0xFFFFD700) : place.color;
    final reward      = place.rewardItem;

    return Container(
      width: 165,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1923).withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          // place name with color dot
          Row(
            children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: place.color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(place.name,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 11, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),

          // type label and distance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(place.type.toUpperCase(),
                  style: TextStyle(color: place.color.withOpacity(0.8),
                      fontSize: 9, letterSpacing: 0.8)),
              Text(place.distanceLabel,
                  style: const TextStyle(color: Colors.white38, fontSize: 9)),
            ],
          ),

          // progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: place.walkedFraction,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? const Color(0xFFFFD700) : place.color),
              minHeight: 4,
            ),
          ),

          // status + reward name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isComplete ? '✓ Done'
                    : place.status == TrailStatus.active
                        ? '${(place.walkedFraction * 100).round()}%'
                        : 'Nearby',
                style: TextStyle(
                  color: isComplete ? const Color(0xFFFFD700) : Colors.white54,
                  fontSize: 10),
              ),
              if (reward != null)
                Row(
                  children: [
                    Text(_tagEmoji(reward.tag), style: const TextStyle(fontSize: 10)),
                    const SizedBox(width: 2),
                    Text(reward.name,
                        style: TextStyle(
                          color: isComplete ? const Color(0xFFFFD700) : place.color,
                          fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// full detail sheet that pops up when you tap a place card
class _PlaceDetailSheet extends StatelessWidget {
  final NearbyPlace place;
  final VoidCallback onComplete;
  const _PlaceDetailSheet({required this.place, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final isComplete = place.status == TrailStatus.completed;
    final reward     = place.rewardItem;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1923),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),

          // header row with name and done badge
          Row(
            children: [
              Container(width: 12, height: 12,
                  decoration: BoxDecoration(color: place.color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(place.name,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              if (isComplete)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD700)),
                  ),
                  child: const Text('✓ Done',
                      style: TextStyle(color: Color(0xFFFFD700),
                          fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(place.type.toUpperCase(),
              style: TextStyle(color: place.color.withOpacity(0.8),
                  fontSize: 11, letterSpacing: 1.2)),
          const SizedBox(height: 20),

          // stat chips — time, steps, distance
          Row(
            children: [
              _StatChip(
                icon: '⏱️', label: 'Est. time',
                value: place.estimatedMinutes < 60
                    ? '${place.estimatedMinutes} min'
                    : '${(place.estimatedMinutes / 60).toStringAsFixed(1)} hr',
                color: place.color,
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: '👟', label: 'Est. steps',
                value: place.estimatedSteps >= 1000
                    ? '~${(place.estimatedSteps / 1000).toStringAsFixed(1)}k'
                    : '${place.estimatedSteps}',
                color: place.color,
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: '📏', label: 'Distance',
                value: place.distanceLabel,
                color: place.color,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // progress bar only shows when actively walking
          if (!isComplete && place.status == TrailStatus.active) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Progress',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text('${(place.walkedFraction * 100).round()}%',
                    style: TextStyle(color: place.color, fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: place.walkedFraction,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(place.color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // reward preview using shop item name + tag emoji
          if (reward != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: place.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: place.color.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Text(_tagEmoji(reward.tag), style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isComplete ? 'Collected!' : 'Reward',
                          style: TextStyle(
                            color: isComplete ? const Color(0xFFFFD700) : Colors.white54,
                            fontSize: 10),
                        ),
                        Text(reward.name,
                            style: TextStyle(
                              color: isComplete ? const Color(0xFFFFD700) : Colors.white,
                              fontSize: 14, fontWeight: FontWeight.bold)),
                        Text(reward.description,
                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // done state vs the "I completed this!" button
          if (isComplete)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Text('🐱', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 6),
                  Text('Trail done!',
                      style: TextStyle(color: Color(0xFFFFD700),
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('Item added to inventory',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: onComplete,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [place.color, place.color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                    color: place.color.withOpacity(0.35),
                    blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🐾', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 10),
                    Text('I completed this!',
                        style: TextStyle(color: Colors.white,
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// time / steps / distance stat boxes in the detail sheet
class _StatChip extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.icon, required this.label,
    required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(
              color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// popup that bounces in right after completing a trail, shows the item you got
class _RewardBurst extends StatelessWidget {
  final ShopItem? item;
  final String placeName;
  const _RewardBurst({required this.item, required this.placeName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1923),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.35),
            blurRadius: 28, spreadRadius: 6),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🐱', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 8),
          const Text('Trail Complete!',
              style: TextStyle(color: Colors.white,
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(placeName,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 14),

          // shows which shop item dropped — emoji from _tagEmoji, name from ShopItem
          if (item != null) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_tagEmoji(item!.tag), style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item!.name,
                        style: const TextStyle(color: Color(0xFFFFD700),
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const Text('added to inventory',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          const Text('Trail complete.',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}