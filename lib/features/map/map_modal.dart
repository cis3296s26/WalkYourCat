import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walkyourcat/services/geo_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../shop/shop_item.dart';
import '../shop/shop_service.dart';
import '../inventory/inventory_service.dart';
import 'map_service.dart';
// import 'location_cache_service.dart';


const _geoapifyApiKey = 'bcbd88fabee5488493869a851cca70b5';

final _service = LocationDbService();
// final _service = LocationCacheService();

enum TrailStatus { locked, active, completed }

enum DistanceFilter { half, one, two, five, all }

extension DistanceFilterX on DistanceFilter {
  double? get maxMiles {
    switch (this) {
      case DistanceFilter.half:  return 0.5;
      case DistanceFilter.one:   return 1.0;
      case DistanceFilter.two:   return 2.0;
      case DistanceFilter.five:  return 5.0;
      case DistanceFilter.all:   return null;
    }
  }

  String get label {
    switch (this) {
      case DistanceFilter.half:  return '½ mi';
      case DistanceFilter.one:   return '1 mi';
      case DistanceFilter.two:   return '2 mi';
      case DistanceFilter.five:  return '5 mi';
      case DistanceFilter.all:   return 'All';
    }
  }

  bool matches(double perimeterMiles) {
    if (maxMiles == null) return true;
    return perimeterMiles <= maxMiles!;
  }
}

// NearbyPlace model
class NearbyPlace {
  final String id;
  final String name;
  final String type;
  final LatLng center;
  final List<LatLng> boundary;
  final Color color;

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

  int get estimatedMinutes => (perimeterMeters / 80).ceil().clamp(1, 999);

  int get estimatedSteps => (perimeterMiles * 2112).round().clamp(100, 999999);

  String get distanceLabel {
    final miles = perimeterMiles;
    if (miles >= 0.1) return '${miles.toStringAsFixed(2)} mi';
    return '${(miles * 5280).round()} ft';
  }

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
      if (dist.as(LengthUnit.Meter, userPos, segMid) < 40) {
        _visitedSegments.add(segId);
      }
    }

    final dCenter = dist.as(LengthUnit.Meter, userPos, center);
    if (dCenter < 60) _visitedSegments.add('$id-center');

    final totalPossible = boundary.length > 1 ? boundary.length - 1 : 1;
    walkedFraction = (_visitedSegments.length / totalPossible).clamp(0.0, 1.0);

    if (status == TrailStatus.locked && (walkedFraction > 0 || dCenter < 200)) {
      status = TrailStatus.active;
    }
    if (walkedFraction >= 0.7 && status == TrailStatus.active) {
      status = TrailStatus.completed;
      walkedFraction = 1.0;
    }
  }
}

// Persistence
class _TrailPersistence {
  static const _kDateKey    = 'trail_date';
  static const _kIdsKey     = 'trail_completed_ids';
  static const _kRewardPfx  = 'trail_reward_';
  static const _kFilterKey  = 'trail_distance_filter';

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  static Future<Set<String>> loadCompletedToday() async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getString(_kDateKey) ?? '') != _today()) {
      await prefs.remove(_kIdsKey);
      await prefs.setString(_kDateKey, _today());
      for (final k in prefs.getKeys().where((k) => k.startsWith(_kRewardPfx)).toList()) {
        await prefs.remove(k);
      }
      return {};
    }
    final raw = prefs.getString(_kIdsKey) ?? '';
    return raw.isEmpty ? {} : raw.split(',').toSet();
  }

  static Future<void> markCompleted(String trailId, {int? rewardItemId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDateKey, _today());
    final raw = prefs.getString(_kIdsKey) ?? '';
    final current = raw.isEmpty ? <String>{} : raw.split(',').toSet();
    current.add(trailId);
    await prefs.setString(_kIdsKey, current.join(','));
    if (rewardItemId != null) {
      await prefs.setInt('$_kRewardPfx$trailId', rewardItemId);
    }
  }

  static Future<int?> getRewardItemId(String trailId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_kRewardPfx$trailId')
        ? prefs.getInt('$_kRewardPfx$trailId')
        : null;
  }

  static Future<void> saveFilter(DistanceFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kFilterKey, filter.index);
  }

  static Future<DistanceFilter> loadFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_kFilterKey);
    if (idx == null || idx >= DistanceFilter.values.length) return DistanceFilter.all;
    return DistanceFilter.values[idx];
  }
}

// trail cache
// round coords to ~1km grid so nearby opens hit the same cache bucket
String _cacheKey(LatLng center) {
  final lat = (center.latitude  * 100).round() / 100;
  final lon = (center.longitude * 100).round() / 100;
  return 'trail_cache_${lat}_$lon';
}

const _kCacheTimeKey = 'trail_cache_time'; // stores epoch ms of last fetch

// how long before we consider the cache stale and re-fetch (24 hours)
const _kCacheTtl = Duration(hours: 24);

// save raw geojson string + timestamp to prefs
Future<void> _saveCache(String key, String body) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, body);
  await prefs.setInt(_kCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
}

// load cached geojson if it's still fresh, returns null if stale/missing
Future<String?> _loadCache(String key) async {
  final prefs = await SharedPreferences.getInstance();
  final savedAt = prefs.getInt(_kCacheTimeKey);
  if (savedAt == null) return null;

  final age = DateTime.now().millisecondsSinceEpoch - savedAt;
  if (age > _kCacheTtl.inMilliseconds) {
    debugPrint('[map] cache expired, gonna re-fetch');
    return null;
  }

  final body = prefs.getString(key);
  if (body == null || body.isEmpty) return null;

  debugPrint('[map] cache hit! skipping api call 🎉');
  return body;
}

// GEOAPIFY fetch docs: https://apidocs.geoapify.com/docs/places/
// quick flow:
//   1. check cache, if we have fresh data for this area, use it (instant)
//   2. otherwise hit geoapify places api to get parks/trails nearby
//   3. parse the geojson into NearbyPlace objects with boundaries
//   4. if geoapify fails for any reason, fall back to overpass (slower but reliable)
//   5. save result to cache so next open is instant
Future<List<NearbyPlace>> fetchNearbyPlaces(LatLng center) async {
  // these are the geoapify place categories we care about — parks, nature, leisure
  // full list at: https://apidocs.geoapify.com/docs/places/#categories
  final categories = [
    'leisure.park',
    'leisure.park.nature_reserve',
    'leisure.park.garden',
    'leisure.playground',
    'leisure.picnic',
    'natural.forest',
    'natural.protected_area',
    'natural.water',
    'tourism.attraction',
    'sport.track',
  ].join(',');

  final lat = center.latitude;
  final lon = center.longitude;
  const radiusMeters = 8000; // ~5 miles

  //step 1: try cache first
  final cacheKey = _cacheKey(center);
  final cached = await _loadCache(cacheKey);

  String responseBody;

  if (cached != null) {
    // we have fresh cached data. skip the network call entirely
    responseBody = cached;
  } else {
    //  step 2: hit the api
    // note: geoapify uses "apiKey" (camelCase) as the query param name
    // and the filter format is "circle:lon,lat,radiusMeters" (lon comes first!)
    final uri = Uri(
      scheme: 'https',
      host: 'api.geoapify.com',
      path: '/v2/places',
      queryParameters: {
        'categories': categories,
        'filter': 'circle:$lon,$lat,$radiusMeters',
        'bias': 'proximity:$lon,$lat',
        'limit': '150',
        'apiKey': _geoapifyApiKey,
      },
    );

    debugPrint('[map] fetching from geoapify: ${uri.toString()}');

    http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      // network died or timed out, overpass fallback will be our savior
      debugPrint('[map] geoapify request threw: $e');
      return _fetchNearbyPlacesOverpassFallback(center);
    }

    if (response.statusCode == 401) {
      debugPrint('[map] geoapify 401 — double-check your api key');
      return _fetchNearbyPlacesOverpassFallback(center);
    }

    if (response.statusCode != 200) {
      debugPrint('[map] geoapify returned ${response.statusCode}: ${response.body}');
      return _fetchNearbyPlacesOverpassFallback(center);
    }

    responseBody = response.body;

    // step 3: cache it for next time 
    await _saveCache(cacheKey, responseBody);
    debugPrint('[map] cached geoapify response for next open');
  }

  //  step 4: parse the geojson
  Map<String, dynamic> data;
  try {
    data = jsonDecode(responseBody) as Map<String, dynamic>;
  } catch (e) {
    debugPrint('[map] json parse blew up: $e');
    return [];
  }

  final features = (data['features'] as List<dynamic>?) ?? [];

  // colors we cycle through for each trail/park on the map
  const colors = [
    Color(0xFF2ECC71), Color(0xFF3498DB), Color(0xFFE67E22),
    Color(0xFF9B59B6), Color(0xFFE74C3C), Color(0xFF1ABC9C),
    Color(0xFFF39C12), Color(0xFF27AE60), Color(0xFF8E44AD),
    Color(0xFFD35400),
  ];

  const Distance distCalc = Distance();
  final List<NearbyPlace> places = [];
  int colorIndex = 0;

  for (final feature in features) {
    final props = (feature['properties'] as Map<String, dynamic>?) ?? {};

    // grab the name, fall back to generated label from category
    String name = props['name'] as String? ?? '';
    if (name.isEmpty) {
      final cats = (props['categories'] as List<dynamic>?)?.cast<String>() ?? [];
      name = _labelFromCategories(cats);
      if (name.isEmpty) continue; // no name and no useful category? skip it
    }

    // figure out what "type" to show in the ui (park / trail / nature etc.)
    final cats = (props['categories'] as List<dynamic>?)?.cast<String>() ?? [];
    final typeLabel = _typeFromCategories(cats);

    // parse the geometry — geoapify can return Point, Polygon, LineString, etc.
    final geometry = feature['geometry'] as Map<String, dynamic>?;
    if (geometry == null) continue;

    final geoType = geometry['type'] as String? ?? '';
    final coords  = geometry['coordinates'];

    LatLng placeCenter;
    List<LatLng> boundary;

    if (geoType == 'Point') {
      final c = coords as List<dynamic>;
      placeCenter = LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
      boundary = _syntheticCircle(placeCenter, _radiusFromProps(props));
    } else if (geoType == 'Polygon') {
      final ring = (coords as List<dynamic>)[0] as List<dynamic>;
      boundary = ring.map<LatLng>((pt) {
        final p = pt as List<dynamic>;
        return LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble());
      }).toList();
      if (boundary.isEmpty) continue;
      final avgLat = boundary.map((p) => p.latitude).reduce((a,b)=>a+b) / boundary.length;
      final avgLon = boundary.map((p) => p.longitude).reduce((a,b)=>a+b) / boundary.length;
      placeCenter = LatLng(avgLat, avgLon);
    } else {
      // LineString or MultiPolygon — flatten to a list of points
      boundary = _flattenGeometry(geometry);
      if (boundary.isEmpty) continue;
      final avgLat = boundary.map((p) => p.latitude).reduce((a,b)=>a+b) / boundary.length;
      final avgLon = boundary.map((p) => p.longitude).reduce((a,b)=>a+b) / boundary.length;
      placeCenter = LatLng(avgLat, avgLon);
    }

    // skip anything tiny — less than 160m perimeter isn't really walkable
    double totalM = 0;
    for (int i = 0; i < boundary.length - 1; i++) {
      totalM += distCalc.as(LengthUnit.Meter, boundary[i], boundary[i+1]);
    }
    if (totalM < 160) continue;

    // stable id — prefer geoapify's place_id, fall back to osm id or a hash
    final placeId = props['place_id'] as String?
        ?? props['osm_id']?.toString()
        ?? 'geo-${props['name']}-$colorIndex';

    places.add(NearbyPlace(
      id: placeId,
      name: name,
      type: typeLabel,
      center: placeCenter,
      boundary: boundary,
      color: colors[colorIndex % colors.length],
    ));

    colorIndex++;
    if (places.length >= 150) break;
  }

  // sort by distance so closest trails show up first in the list
  places.sort((a, b) =>
    distCalc.as(LengthUnit.Meter, center, a.center)
        .compareTo(distCalc.as(LengthUnit.Meter, center, b.center)));

  debugPrint('[map] geoapify parsed ${places.length} walkable places');
  return places;
}

List<LatLng> _syntheticCircle(LatLng center, double radiusMeters) {
  const steps = 16;
  const Distance d = Distance();
  return List.generate(steps + 1, (i) {
    final bearing = (360.0 / steps) * i;
    return d.offset(center, radiusMeters, bearing);
  });
}

// estimate radius from the place's bounding box — bigger bbox = bigger circle
double _radiusFromProps(Map<String, dynamic> props) {
  final bbox = props['bbox'] as Map<String, dynamic>?;
  if (bbox != null) {
    final lon1 = (bbox['lon1'] as num?)?.toDouble() ?? 0;
    final lat1 = (bbox['lat1'] as num?)?.toDouble() ?? 0;
    final lon2 = (bbox['lon2'] as num?)?.toDouble() ?? 0;
    final lat2 = (bbox['lat2'] as num?)?.toDouble() ?? 0;
    const d = Distance();
    final diag = d.as(LengthUnit.Meter, LatLng(lat1, lon1), LatLng(lat2, lon2));
    return (diag / 2).clamp(80, 2000);
  }
  return 200; // default to 200m if we have no bbox info
}

// map geoapify category strings
String _labelFromCategories(List<String> cats) {
  if (cats.any((c) => c.contains('nature_reserve'))) return 'Nature Reserve';
  if (cats.any((c) => c.contains('park')))           return 'Park';
  if (cats.any((c) => c.contains('forest')))         return 'Park';
  if (cats.any((c) => c.contains('grassland')))      return 'Field';
  if (cats.any((c) => c.contains('playground')))     return 'Playground';
  if (cats.any((c) => c.contains('pitch')))          return 'Trail';
  if (cats.any((c) => c.contains('water')))          return 'Lakeside';
  if (cats.any((c) => c.contains('tourism')))        return 'Attraction';
  return '';
}

// map categories to the type badge shown in the ui card
String _typeFromCategories(List<String> cats) {
  if (cats.any((c) => c.contains('nature_reserve') || c.contains('forest'))) return 'nature';
  if (cats.any((c) => c.contains('park')))    return 'park';
  if (cats.any((c) => c.contains('pitch')))   return 'trail';
  return 'park';
}

// flatten weird geometry types (LineString, MultiPolygon) into a simple point list
List<LatLng> _flattenGeometry(Map<String, dynamic> geometry) {
  final type   = geometry['type'] as String? ?? '';
  final coords = geometry['coordinates'];
  try {
    if (type == 'LineString') {
      return (coords as List<dynamic>).map<LatLng>((pt) {
        final p = pt as List<dynamic>;
        return LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble());
      }).toList();
    }
    if (type == 'MultiPolygon') {
      final ring = ((coords as List<dynamic>)[0] as List<dynamic>)[0] as List<dynamic>;
      return ring.map<LatLng>((pt) {
        final p = pt as List<dynamic>;
        return LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble());
      }).toList();
    }
  } catch (_) {}
  return [];
}
// Overpass fallback
// Only called if Geoapify is unavailable.
const _overpassEndpoints = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
];

Future<List<NearbyPlace>> _fetchNearbyPlacesOverpassFallback(LatLng center) async {
  debugPrint('[map] Falling back to Overpass…');
  const double radiusMeters = 8000;
  final lat = center.latitude;
  final lon = center.longitude;

  // Leaner query: only named parks + paths, shorter timeout.
  final query =
      '[out:json][timeout:10];'
      '('
      'way["leisure"~"^(park|nature_reserve)\$"]["name"](around:$radiusMeters,$lat,$lon);'
      'way["highway"~"^(path|footway|cycleway)\$"]["name"](around:$radiusMeters,$lat,$lon);'
      ');'
      'out geom qt 100;';

  http.Response? response;
  for (final endpoint in _overpassEndpoints) {
    try {
      response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': query},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.body.startsWith('{')) break;
    } catch (e) {
      debugPrint('[map] Overpass $endpoint failed: $e');
      response = null;
    }
  }

  if (response == null || response.statusCode != 200) return [];

  Map<String, dynamic> data;
  try {
    data = jsonDecode(response.body) as Map<String, dynamic>;
  } catch (_) {
    return [];
  }

  const colors = [
    Color(0xFF2ECC71), Color(0xFF3498DB), Color(0xFFE67E22),
    Color(0xFF9B59B6), Color(0xFFE74C3C), Color(0xFF1ABC9C),
  ];

  final elements = (data['elements'] as List<dynamic>?) ?? [];
  const Distance distCalc = Distance();
  final List<NearbyPlace> places = [];
  int colorIndex = 0;

  for (final el in elements) {
    if ((el['type'] as String? ?? '') != 'way') continue;
    final tags = (el['tags'] as Map<String, dynamic>?) ?? {};
    final name = tags['name'] as String? ?? '';
    if (name.isEmpty) continue;

    final rawGeom = el['geometry'] as List<dynamic>? ?? [];
    final boundary = rawGeom.map<LatLng?>((g) {
      final gLat = (g['lat'] as num?)?.toDouble();
      final gLon = (g['lon'] as num?)?.toDouble();
      if (gLat == null || gLon == null) return null;
      return LatLng(gLat, gLon);
    }).whereType<LatLng>().toList();
    if (boundary.isEmpty) continue;

    double totalM = 0;
    for (int i = 0; i < boundary.length - 1; i++) {
      totalM += distCalc.as(LengthUnit.Meter, boundary[i], boundary[i+1]);
    }
    if (totalM < 160) continue;

    final avgLat = boundary.map((p) => p.latitude).reduce((a,b)=>a+b) / boundary.length;
    final avgLon = boundary.map((p) => p.longitude).reduce((a,b)=>a+b) / boundary.length;

    places.add(NearbyPlace(
      id: 'way-${el['id']}',
      name: name,
      type: (tags['highway'] != null) ? 'trail' : 'park',
      center: LatLng(avgLat, avgLon),
      boundary: boundary,
      color: colors[colorIndex % colors.length],
    ));
    colorIndex++;
    if (places.length >= 80) break;
  }

  places.sort((a, b) =>
    distCalc.as(LengthUnit.Meter, center, a.center)
        .compareTo(distCalc.as(LengthUnit.Meter, center, b.center)));

  return places;
}

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

void showMapModal(
  BuildContext context, {
  Future<void> Function(GlobalKey)? runAddToCartAnimation,
  GlobalKey? inventoryTargetKey,
}) {
  showDialog(
    context: context,
    builder: (context) {
      final screenSize = MediaQuery.of(context).size;
      final dialogWidth = screenSize.width < 600 ? screenSize.width * 0.90 : 400.0;
      final dialogHeight = screenSize.height < 760 ? screenSize.height * 0.80 : 500.0;

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1821),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 32, spreadRadius: 4),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: MapModalService(
              runAddToCartAnimation: runAddToCartAnimation,
              inventoryTargetKey: inventoryTargetKey,
            ),
          ),
        ),
      );
    },
  );
}

class MapModalService extends StatefulWidget {
  final Future<void> Function(GlobalKey)? runAddToCartAnimation;
  final GlobalKey? inventoryTargetKey;

  const MapModalService({
    super.key,
    this.runAddToCartAnimation,
    this.inventoryTargetKey,
  });

  @override
  State<MapModalService> createState() => _MapModalServiceState();
}

enum _BottomTab { nearby, done }

class _MapModalServiceState extends State<MapModalService>
    with TickerProviderStateMixin {
  LatLng _currentLocation = const LatLng(39.9812, -75.1554);
  final MapController _mapController = MapController();
  final GlobalKey _rewardItemKey = GlobalKey();
  StreamSubscription<Position>? _positionSubscription;

  List<NearbyPlace> _allPlaces      = [];
  List<NearbyPlace> _filteredPlaces = [];
  List<ShopItem>    _shopItems      = [];
  final List<Map<String, dynamic>> _otherUsers = [];

  bool   _loading    = true;
  String _loadingMsg = 'Getting your location…';

  DistanceFilter _activeFilter = DistanceFilter.all;
  _BottomTab     _activeTab    = _BottomTab.nearby;

  NearbyPlace? _selectedPlace;

  // Reward overlay
  bool     _showReward    = false;
  ShopItem? _rewardItem;
  String   _rewardPlaceName = '';

  late AnimationController _rewardAnim;
  late Animation<double>   _rewardScale;
  late Animation<double>   _rewardOpacity;

  // Detail sheet animation
  late AnimationController _sheetAnim;
  late Animation<double>   _sheetSlide;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initApp();
  }

  void _setupAnimations() {
    _rewardAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _rewardScale   = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _rewardAnim, curve: Curves.elasticOut));
    _rewardOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _rewardAnim, curve: const Interval(0.65, 1.0, curve: Curves.easeOut)));

    _sheetAnim  = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _sheetSlide = CurvedAnimation(parent: _sheetAnim, curve: Curves.easeOutCubic);
  }

  Future<void> _initApp() async {
    _activeFilter = await _TrailPersistence.loadFilter();
    try { _shopItems = await ShopService.loadShopAssets(); }
    catch (e) { debugPrint('[map] shop load failed: $e'); }
    await _initLocation();
  }

  void _applyFilter() {
    setState(() {
      _filteredPlaces = _allPlaces.where((p) => _activeFilter.matches(p.perimeterMiles)).toList();
    });
  }

  void _setFilter(DistanceFilter filter) {
    if (_activeFilter == filter) return;
    setState(() => _activeFilter = filter);
    _TrailPersistence.saveFilter(filter);
    _applyFilter();
  }

  void _assignRewards() {
    if (_shopItems.isEmpty) return;
    final tier0 = _shopItems.where((i) => i.tag == 'food'     || i.tag == 'drinks').toList();
    final tier1 = _shopItems.where((i) => i.tag == 'medicine' || i.tag == 'fun').toList();
    final tier2 = _shopItems.where((i) => i.tag == 'cosmetic').toList();

    for (final place in _allPlaces) {
      final miles = place.perimeterMiles;
      List<ShopItem> pool;
      if      (miles >= 4.0 && tier2.isNotEmpty) pool = tier2;
      else if (miles >= 2.0 && tier1.isNotEmpty) pool = tier1;
      else if (tier0.isNotEmpty)                  pool = tier0;
      else                                         pool = _shopItems;
      place.rewardItem = pool[place.id.hashCode.abs() % pool.length];
    }
  }

  void _upsertOtherUser(Map<String, dynamic> userData) {
    final id = userData['id'] ?? userData['uid'] ?? userData['userId'] ?? userData['username'];
    if (id != null) {
      final idx = _otherUsers.indexWhere(
          (u) => (u['id'] ?? u['uid'] ?? u['userId'] ?? u['username']) == id);
      if (idx >= 0) _otherUsers[idx] = userData;
      else          _otherUsers.add(userData);
      return;
    }
    final lat = (userData['lat'] as num?)?.toDouble();
    final lng = (userData['lng'] as num?)?.toDouble();
    final idx = _otherUsers.indexWhere(
        (u) => (u['lat'] as num?)?.toDouble() == lat && (u['lng'] as num?)?.toDouble() == lng);
    if (idx < 0) _otherUsers.add(userData);
    else         _otherUsers[idx] = userData;
  }

  Future<void> _initLocation() async {
    bool hasPermission = await GeoService.instance.checkLocationPermission();
    if (!hasPermission) {
      setState(() { _loadingMsg = 'Location permission denied'; _loading = false; });
      return;
    }

    _service.startLocationSharing(onNewUserFound: (userData) {
      if (!mounted) return;
      setState(() => _upsertOtherUser(Map<String, dynamic>.from(userData)));
    });

    Position? position = GeoService.instance.currentPosition
        ?? await GeoService.instance.getCurrentPosition();

    if (!mounted) return;
    if (position != null) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _loadingMsg = 'Finding trails & parks nearby…';
      });
      _mapController.move(_currentLocation, 14.0);
    } else {
      setState(() => _loadingMsg = 'Could not get location');
    }

    final places = await fetchNearbyPlaces(_currentLocation);
    if (!mounted) return;

    _allPlaces = places;
    _assignRewards();

    final completedIds = await _TrailPersistence.loadCompletedToday();
    for (final place in _allPlaces) {
      if (!completedIds.contains(place.id)) continue;
      place.status = TrailStatus.completed;
      place.walkedFraction = 1.0;
      if (place.rewardItem == null && _shopItems.isNotEmpty) {
        final savedId = await _TrailPersistence.getRewardItemId(place.id);
        if (savedId != null) {
          place.rewardItem = _shopItems.firstWhere(
            (i) => i.id == savedId, orElse: () => _shopItems.first);
        }
      }
    }

    _applyFilter();
    setState(() => _loading = false);

    _positionSubscription = GeoService.instance.positionStream
        .where((pos) => pos != null)
        .cast<Position>()
        .listen(_onPosition);
  }

  void _onPosition(Position pos) {
    if (!mounted) return;
    final loc = LatLng(pos.latitude, pos.longitude);
    setState(() => _currentLocation = loc);
    _mapController.move(loc, _mapController.camera.zoom);

    for (final place in _allPlaces) {
      final prev = place.status;
      place.checkUserPosition(loc);
      if (place.status == TrailStatus.completed && prev != TrailStatus.completed) {
        _awardItem(place);
      }
    }
    setState(() {});
  }

  Future<void> _awardItem(NearbyPlace place) async {
    await _TrailPersistence.markCompleted(place.id, rewardItemId: place.rewardItem?.id);
    if (place.rewardItem != null) await InventoryService.instance.addItem(place.rewardItem!);
    if (!mounted) return;
    setState(() {
      _rewardItem = place.rewardItem;
      _rewardPlaceName = place.name;
      _showReward = true;
    });

    final runAnimation = widget.runAddToCartAnimation;
    if (place.rewardItem != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_showReward) return;
        if (widget.inventoryTargetKey != null) unawaited(_runRewardFlight());
        else if (runAnimation != null) unawaited(runAnimation(_rewardItemKey));
      });
    }
    _rewardAnim.forward(from: 0).then((_) {
      if (mounted) setState(() => _showReward = false);
    });
  }

  void _manualComplete(NearbyPlace place) {
    if (place.status == TrailStatus.completed) return;
    setState(() { place.status = TrailStatus.completed; place.walkedFraction = 1.0; });
    _awardItem(place);
  }

  void _selectPlace(NearbyPlace place) {
    setState(() => _selectedPlace = place);
    _sheetAnim.forward(from: 0);
    _mapController.move(place.center, 15.5);
  }

  void _closeSheet() {
    _sheetAnim.reverse().then((_) {
      if (mounted) setState(() => _selectedPlace = null);
    });
  }

  Future<void> _runRewardFlight() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final srcBounds = _globalPaintBounds(_rewardItemKey);
    final tgtBounds = widget.inventoryTargetKey == null 
        ? null 
        : _globalPaintBounds(widget.inventoryTargetKey!);

    if (srcBounds == null || tgtBounds == null) {
      debugPrint("Animation skipped: Bounds not found. Src: $srcBounds, Tgt: $tgtBounds");
      return;
    }

    final item = _rewardItem;
    final overlay = Overlay.of(context, rootOverlay: true);
    if (item == null) return;

    final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 850));
    final anim = CurvedAnimation(parent: ctrl, curve: Curves.easeInOutCubic);
    
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => AnimatedBuilder(
      animation: anim,
      builder: (ctx, child) {
        final rect = Rect.lerp(srcBounds, tgtBounds, anim.value)!;
        final lift = 40 * (1 - (2 * anim.value - 1).abs()); 
        
        return Positioned(
          left: rect.left, 
          top: rect.top - lift,
          width: rect.width, 
          height: rect.height,
          child: IgnorePointer(
            child: Transform.scale(
              scale: 1 - (anim.value * 0.3), 
              child: child,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5CC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD700), width: 2),
        ),
        child: Center(child: _RewardItemVisual(item: item, size: 30)),
      ),
    ));

    overlay.insert(entry);
    await ctrl.forward();
    entry.remove();
    ctrl.dispose();
  }
  Rect? _globalPaintBounds(GlobalKey key) {
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    
    final offset = renderBox.localToGlobal(Offset.zero);
    return offset & renderBox.size;
  }
  int get _completedCount => _allPlaces.where((p) => p.status == TrailStatus.completed).length;

  List<NearbyPlace> get _tabPlaces {
    if (_activeTab == _BottomTab.done) {
      return _filteredPlaces.where((p) => p.status == TrailStatus.completed).toList();
    }
    return _filteredPlaces.where((p) => p.status != TrailStatus.completed).toList();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _service.stop();
    _rewardAnim.dispose();
    _sheetAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildMapArea()),
        _buildBottomPanel(),
      ],
    );
  }
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withOpacity(0.15),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.35)),
            ),
            child: const Center(child: Text('🐾', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cat walks',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(
                _loading
                    ? 'Loading…'
                    : '$_completedCount completed today',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white54, size: 16),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMapArea() {
    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation,
            initialZoom: 14.0,
            keepAlive: true,
            onTap: (_, __) => _closeSheet(),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'app',
            ),
            if (_filteredPlaces.isNotEmpty)
              PolylineLayer(
                polylines: _filteredPlaces.where((p) => p.boundary.length > 1).map((p) =>
                  Polyline(
                    points: p.boundary,
                    color: p.status == TrailStatus.completed
                        ? const Color(0xFFFFD700).withOpacity(0.9)
                        : p.color.withOpacity(_selectedPlace?.id == p.id ? 0.95 : 0.55),
                    strokeWidth: p.status == TrailStatus.completed
                        ? 4.5
                        : _selectedPlace?.id == p.id ? 4.0 : 2.5,
                  ),
                ).toList(),
              ),
            if (_filteredPlaces.isNotEmpty)
              MarkerLayer(
                markers: _filteredPlaces.map((p) => Marker(
                  point: p.center,
                  width: 150, height: 54,
                  child: GestureDetector(
                    onTap: () => _selectPlace(p),
                    child: _PlacePin(place: p, isSelected: _selectedPlace?.id == p.id),
                  ),
                )).toList(),
              ),
            // User + other users
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLocation,
                  width: 44, height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2ECC71).withOpacity(0.18),
                      border: Border.all(color: const Color(0xFF2ECC71), width: 2),
                    ),
                    child: const Center(child: Text('🐱', style: TextStyle(fontSize: 22))),
                  ),
                ),
                ..._otherUsers.map((user) {
                  final lat = (user['lat'] as num?)?.toDouble() ?? 0.0;
                  final lng = (user['lng'] as num?)?.toDouble() ?? 0.0;
                  final name = (user['name'] ?? user['username'] ?? '').toString();
                  return Marker(
                    point: LatLng(lat, lng),
                    width: 58, height: 56,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🐾', style: TextStyle(fontSize: 24)),
                      if (name.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2535).withOpacity(0.92),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(name,
                              style: const TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                        ),
                    ]),
                  );
                }),
              ],
            ),
            RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
          ],
        ),

        // Loading overlay
        if (_loading)
          Container(
            color: const Color(0xFF0D1821).withOpacity(0.88),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(color: Color(0xFF2ECC71), strokeWidth: 2.5),
                const SizedBox(height: 16),
                Text(_loadingMsg, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                const Text('(powered by Geoapify)', style: TextStyle(color: Colors.white24, fontSize: 10)),
              ]),
            ),
          ),

        // Locate button
        if (!_loading)
          Positioned(
            top: 12, left: 12,
            child: GestureDetector(
              onTap: () => _mapController.move(_currentLocation, 14.0),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1821).withOpacity(0.94),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: const Icon(Icons.my_location, color: Color(0xFF2ECC71), size: 18),
              ),
            ),
          ),

        // Distance filter bar
        if (!_loading)
          Positioned(
            top: 12, left: 58, right: 12,
            child: _DistanceFilterBar(
              active: _activeFilter,
              filteredCount: _filteredPlaces.length,
              onSelect: _setFilter,
            ),
          ),

        // Empty state
        if (!_loading && _filteredPlaces.isEmpty)
          Positioned(
            top: 62, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2535).withOpacity(0.97),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                _allPlaces.isEmpty
                    ? 'No trails found nearby.'
                    : 'No ${_activeFilter.label} trails — try a wider filter!',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),

        // Detail sheet (slide up from map bottom)
        if (_selectedPlace != null)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _sheetSlide,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, (1 - _sheetSlide.value) * 340),
                child: child,
              ),
              child: _PlaceDetailSheet(
                place: _selectedPlace!,
                onClose: _closeSheet,
                onComplete: () {
                  _closeSheet();
                  _manualComplete(_selectedPlace!);
                },
              ),
            ),
          ),

        // Reward burst
        if (_showReward)
          Center(
            child: AnimatedBuilder(
              animation: _rewardAnim,
              builder: (_, __) => Opacity(
                opacity: _rewardOpacity.value,
                child: Transform.scale(
                  scale: _rewardScale.value,
                  child: _RewardBurst(
                    item: _rewardItem,
                    placeName: _rewardPlaceName,
                    itemKey: _rewardItemKey,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1821),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tab bar
          Row(
            children: [
              _TabButton(
                label: 'Nearby trails',
                isActive: _activeTab == _BottomTab.nearby,
                onTap: () => setState(() { _activeTab = _BottomTab.nearby; _closeSheet(); }),
              ),
              _TabButton(
                label: 'Done today${_completedCount > 0 ? ' · $_completedCount' : ''}',
                isActive: _activeTab == _BottomTab.done,
                onTap: () => setState(() { _activeTab = _BottomTab.done; _closeSheet(); }),
              ),
            ],
          ),
          // Trail list
          SizedBox(
            height: 172,
            child: _tabPlaces.isEmpty
                ? Center(child: Text(
                    _activeTab == _BottomTab.done
                        ? 'No completed trails yet today 🐱'
                        : 'No nearby trails found',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ))
                : ListView.separated(
                    scrollDirection: Axis.vertical,
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                    itemCount: _tabPlaces.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final place = _tabPlaces[i];
                      return GestureDetector(
                        onTap: () => _selectPlace(place),
                        child: _TrailRow(
                          place: place,
                          isSelected: _selectedPlace?.id == place.id,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF2ECC71) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFF2ECC71) : Colors.white38,
          ),
        ),
      ),
    );
  }
}

class _DistanceFilterBar extends StatelessWidget {
  final DistanceFilter active;
  final int filteredCount;
  final void Function(DistanceFilter) onSelect;

  const _DistanceFilterBar({
    required this.active,
    required this.filteredCount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1821).withOpacity(0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📏', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          ...DistanceFilter.values.map((f) => Padding(
            padding: const EdgeInsets.only(left: 3),
            child: GestureDetector(
              onTap: () => onSelect(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: f == active
                      ? const Color(0xFF2ECC71).withOpacity(0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: f == active ? const Color(0xFF2ECC71) : Colors.white24,
                    width: f == active ? 1.5 : 1,
                  ),
                ),
                child: Text(f.label,
                  style: TextStyle(
                    color: f == active ? const Color(0xFF2ECC71) : Colors.white54,
                    fontSize: 10,
                    fontWeight: f == active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          )),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text('$filteredCount',
              style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// Map pin label shown above each trail centre.
class _PlacePin extends StatelessWidget {
  final NearbyPlace place;
  final bool isSelected;
  const _PlacePin({required this.place, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final isDone  = place.status == TrailStatus.completed;
    final color   = isDone ? const Color(0xFFFFD700) : place.color;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.85),
          borderRadius: BorderRadius.circular(9),
          border: isSelected ? Border.all(color: Colors.white, width: 1.5) : null,
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)]
              : const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (isDone) const Text('✓ ', style: TextStyle(color: Colors.black, fontSize: 9)),
          Flexible(
            child: Text(place.name,
              style: TextStyle(
                color: isDone ? Colors.black : Colors.white,
                fontSize: 9, fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ),
      if (place.rewardItem != null && !isDone)
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2535).withOpacity(0.93),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.5), width: 0.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_tagEmoji(place.rewardItem!.tag), style: const TextStyle(fontSize: 8)),
            const SizedBox(width: 3),
            SizedBox(
              width: 52,
              child: Text(place.rewardItem!.name,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ]),
        ),
    ]);
  }
}

// Compact trail row inside the bottom panel list.
class _TrailRow extends StatelessWidget {
  final NearbyPlace place;
  final bool isSelected;
  const _TrailRow({required this.place, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final isDone  = place.status == TrailStatus.completed;
    final reward  = place.rewardItem;
    final color   = isDone ? const Color(0xFFFFD700) : place.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected
            ? place.color.withOpacity(0.1)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isSelected ? place.color.withOpacity(0.5) : Colors.white.withOpacity(0.07),
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      child: Row(children: [
        // Color bar
        Container(
          width: 3, height: 38,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 10),
        // Info
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(place.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(children: [
              Text(place.type.toUpperCase(),
                style: TextStyle(fontSize: 9, color: color.withOpacity(0.8), letterSpacing: 0.6)),
              const SizedBox(width: 8),
              Text(place.distanceLabel,
                style: const TextStyle(fontSize: 9, color: Colors.white38)),
              const SizedBox(width: 8),
              Text(place.estimatedMinutes < 60
                  ? '${place.estimatedMinutes} min'
                  : '${(place.estimatedMinutes/60).toStringAsFixed(1)} hr',
                style: const TextStyle(fontSize: 9, color: Colors.white38)),
            ]),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: place.walkedFraction,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 2.5,
              ),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        // Right side
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isDone
                  ? const Color(0xFFFFD700).withOpacity(0.12)
                  : place.status == TrailStatus.active
                      ? place.color.withOpacity(0.12)
                      : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: isDone
                    ? const Color(0xFFFFD700).withOpacity(0.4)
                    : place.status == TrailStatus.active
                        ? place.color.withOpacity(0.4)
                        : Colors.white.withOpacity(0.12),
              ),
            ),
            child: Text(
              isDone
                  ? '✓ Done'
                  : place.status == TrailStatus.active
                      ? '${(place.walkedFraction * 100).round()}%'
                      : 'Nearby',
              style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.bold,
                color: isDone
                    ? const Color(0xFFFFD700)
                    : place.status == TrailStatus.active
                        ? place.color : Colors.white54,
              ),
            ),
          ),
          if (reward != null) ...[
            const SizedBox(height: 5),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_tagEmoji(reward.tag), style: const TextStyle(fontSize: 10)),
              const SizedBox(width: 3),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 68),
                child: Text(reward.name,
                  overflow: TextOverflow.ellipsis, maxLines: 1,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
              ),
            ]),
          ],
        ]),
      ]),
    );
  }
}

// Slide-up detail sheet that appears over the map.
class _PlaceDetailSheet extends StatelessWidget {
  final NearbyPlace place;
  final VoidCallback onClose;
  final VoidCallback onComplete;
  const _PlaceDetailSheet({required this.place, required this.onClose, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final isDone  = place.status == TrailStatus.completed;
    final reward  = place.rewardItem;
    final color   = isDone ? const Color(0xFFFFD700) : place.color;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111D2B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.09))),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 2)],
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Handle + close
        Row(children: [
          Expanded(child: Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
            ),
          )),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white38, size: 15),
            ),
          ),
        ]),
        const SizedBox(height: 14),

        // Title row
        Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(place.name,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          if (isDone)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.13),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700)),
              ),
              child: const Text('✓ Done',
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ]),
        const SizedBox(height: 3),
        Text(place.type.toUpperCase(),
          style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: color.withOpacity(0.75))),
        const SizedBox(height: 16),

        // Stats
        Row(children: [
          _StatChip(
            icon: '⏱️', label: 'Est. time',
            value: place.estimatedMinutes < 60
                ? '${place.estimatedMinutes} min'
                : '${(place.estimatedMinutes/60).toStringAsFixed(1)} hr',
            color: color,
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: '👟', label: 'Est. steps',
            value: place.estimatedSteps >= 1000
                ? '~${(place.estimatedSteps/1000).toStringAsFixed(1)}k'
                : '${place.estimatedSteps}',
            color: color,
          ),
          const SizedBox(width: 8),
          _StatChip(icon: '📏', label: 'Distance', value: place.distanceLabel, color: color),
        ]),

        // Progress bar (active only)
        if (!isDone && place.status == TrailStatus.active) ...[
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Progress', style: TextStyle(color: Colors.white54, fontSize: 12)),
            Text('${(place.walkedFraction * 100).round()}%',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: place.walkedFraction,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 7,
            ),
          ),
        ],

        // Reward
        if (reward != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(children: [
              Text(_tagEmoji(reward.tag), style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isDone ? 'Collected!' : 'Reward',
                  style: TextStyle(color: isDone ? const Color(0xFFFFD700) : Colors.white54, fontSize: 10)),
                Text(reward.name,
                  style: TextStyle(
                    color: isDone ? const Color(0xFFFFD700) : Colors.white,
                    fontSize: 14, fontWeight: FontWeight.bold)),
                Text(reward.description,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
            ]),
          ),
        ],

        const SizedBox(height: 16),

        // CTA
        if (isDone)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.07),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.28)),
            ),
            child: const Column(mainAxisSize: MainAxisSize.min, children: [
              Text('🐱', style: TextStyle(fontSize: 28)),
              SizedBox(height: 4),
              Text('Trail done!',
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.bold)),
              SizedBox(height: 1),
              Text('Item added to inventory',
                style: TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
          )
        else
          GestureDetector(
            onTap: onComplete,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: place.color,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: place.color.withOpacity(0.35), blurRadius: 14, offset: const Offset(0,5))],
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('🐾', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Text('I completed this!',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon, label, value;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _RewardBurst extends StatelessWidget {
  final ShopItem? item;
  final String placeName;
  final GlobalKey? itemKey;
  const _RewardBurst({required this.item, required this.placeName, this.itemKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1821),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.3), blurRadius: 28, spreadRadius: 6)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🐱', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 8),
        const Text('Got some steps in 🚶',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(placeName, style: const TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
        const SizedBox(height: 14),
        if (item != null) ...[
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              key: itemKey,
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5CC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _RewardItemVisual(item: item!, size: 30),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item!.name,
                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('added to inventory', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ]),
          ]),
          const SizedBox(height: 10),
        ],
      ]),
    );
  }
}

class _RewardItemVisual extends StatelessWidget {
  final ShopItem item;
  final double size;
  const _RewardItemVisual({required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    final style = _styleForItemTag(item.tag);
    if (item.image != null && item.image!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Image.asset(item.image!, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(style.icon, color: style.accent, size: size)),
      );
    }
    return Icon(style.icon, color: style.accent, size: size);
  }
}

class _ItemTagStyle { final IconData icon; final Color accent; const _ItemTagStyle({required this.icon, required this.accent}); }

const Map<String, _ItemTagStyle> _itemTagStyles = {
  'food':     _ItemTagStyle(icon: Icons.lunch_dining_rounded,    accent: Color(0xFFFF7043)),
  'drinks':   _ItemTagStyle(icon: Icons.local_drink_rounded,     accent: Color(0xFF2196F3)),
  'fun':      _ItemTagStyle(icon: Icons.sports_esports_rounded,  accent: Color(0xFF7E57C2)),
  'medicine': _ItemTagStyle(icon: Icons.medication_rounded,      accent: Color(0xFF26A69A)),
  'cosmetic': _ItemTagStyle(icon: FontAwesomeIcons.glasses,      accent: Color(0xFFE91E8C)),
};

_ItemTagStyle _styleForItemTag(String tag) =>
    _itemTagStyles[tag] ??
    const _ItemTagStyle(icon: Icons.inventory_2_rounded, accent: Color(0xFF78909C));