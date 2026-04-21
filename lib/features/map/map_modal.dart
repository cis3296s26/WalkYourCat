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

final _service = LocationDbService();

// trail can be locked (haven't started), active (currently walking it), or completed
enum TrailStatus { locked, active, completed }

// the distance filter options the user can pick from — stored as max miles
// "all" means no cap, just show everything within the 5-mile search radius
enum DistanceFilter {
  half,
  one,
  two,
  five,
  all,
}

extension DistanceFilterX on DistanceFilter {
  double? get maxMiles {
    switch (this) {
      case DistanceFilter.half:
        return 0.5;
      case DistanceFilter.one:
        return 1.0;
      case DistanceFilter.two:
        return 2.0;
      case DistanceFilter.five:
        return 5.0;
      case DistanceFilter.all:
        return null;
    }
  }

  String get label {
    switch (this) {
      case DistanceFilter.half:
        return '½ mi';
      case DistanceFilter.one:
        return '1 mi';
      case DistanceFilter.two:
        return '2 mi';
      case DistanceFilter.five:
        return '5 mi';
      case DistanceFilter.all:
        return 'All';
    }
  }

  bool matches(double perimeterMiles) {
    if (maxMiles == null) return true;
    return perimeterMiles <= maxMiles!;
  }
}

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

class _TrailPersistence {
  static const _kDateKey = 'trail_date';
  static const _kIdsKey = 'trail_completed_ids';
  static const _kRewardPrefix = 'trail_reward_';
  static const _kFilterKey = 'trail_distance_filter';

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static Future<Set<String>> loadCompletedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_kDateKey) ?? '';

    if (savedDate != _today()) {
      await prefs.remove(_kIdsKey);
      await prefs.setString(_kDateKey, _today());
      final staleKeys =
          prefs.getKeys().where((k) => k.startsWith(_kRewardPrefix)).toList();
      for (final k in staleKeys) {
        await prefs.remove(k);
      }
      return {};
    }

    final raw = prefs.getString(_kIdsKey) ?? '';
    if (raw.isEmpty) return {};
    return raw.split(',').toSet();
  }

  static Future<void> markCompleted(String trailId, {int? rewardItemId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDateKey, _today());

    final raw = prefs.getString(_kIdsKey) ?? '';
    final current = raw.isEmpty ? <String>{} : raw.split(',').toSet();
    current.add(trailId);
    await prefs.setString(_kIdsKey, current.join(','));

    if (rewardItemId != null) {
      await prefs.setInt('$_kRewardPrefix$trailId', rewardItemId);
    }
  }

  static Future<int?> getRewardItemId(String trailId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_kRewardPrefix$trailId')
        ? prefs.getInt('$_kRewardPrefix$trailId')
        : null;
  }

  static Future<void> saveFilter(DistanceFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kFilterKey, filter.index);
  }

  static Future<DistanceFilter> loadFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_kFilterKey);
    if (idx == null || idx >= DistanceFilter.values.length)
      return DistanceFilter.all;
    return DistanceFilter.values[idx];
  }
}

const _overpassEndpoints = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass.openstreetmap.ru/api/interpreter',
];

Future<List<NearbyPlace>> fetchNearbyPlaces(LatLng center) async {
  const double radiusMeters = 8000;
  final lat = center.latitude;
  final lon = center.longitude;

  final query = '[out:json][timeout:25];'
      '('
      'way["leisure"~"^(park|nature_reserve|recreation_ground)\$"](around:$radiusMeters,$lat,$lon);'
      'way["highway"~"^(path|footway|cycleway|track)\$"]["name"](around:$radiusMeters,$lat,$lon);'
      'way["route"="hiking"](around:$radiusMeters,$lat,$lon);'
      ');'
      'out geom qt 200;';

  http.Response? response;
  for (final endpoint in _overpassEndpoints) {
    try {
      debugPrint('[map] trying $endpoint');
      response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': query},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 && response.body.startsWith('{')) {
        debugPrint('[map] got a response from $endpoint');
        break;
      }
    } catch (e) {
      debugPrint('[map] $endpoint threw: $e');
      response = null;
    }
  }

  if (response == null || response.statusCode != 200) {
    debugPrint('[map] all endpoints failed');
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

  const colors = [
    Color(0xFF2ECC71),
    Color(0xFF3498DB),
    Color(0xFFE67E22),
    Color(0xFF9B59B6),
    Color(0xFFE74C3C),
    Color(0xFF1ABC9C),
    Color(0xFFF39C12),
    Color(0xFF27AE60),
    Color(0xFF8E44AD),
    Color(0xFFD35400),
  ];

  final List<NearbyPlace> places = [];
  final Set<String> seenIds = {};
  int colorIndex = 0;
  const Distance distCalc = Distance();

  for (final el in elements) {
    if ((el['type'] as String? ?? '') != 'way') continue;

    final String elId = 'way-${el['id']}';
    if (seenIds.contains(elId)) continue;

    final tags = (el['tags'] as Map<String, dynamic>?) ?? {};

    String name = tags['name:en'] as String? ??
        tags['official_name'] as String? ??
        tags['name'] as String? ??
        tags['ref'] as String? ??
        '';

    if (name.isEmpty) {
      final leisure = tags['leisure'] as String?;
      final highway = tags['highway'] as String?;
      final route = tags['route'] as String?;
      final natural = tags['natural'] as String?;
      final landuse = tags['landuse'] as String?;

      if (leisure != null) {
        name = '${_capitalize(leisure.replaceAll('_', ' '))} Park';
      } else if (route != null) {
        name = '${_capitalize(route)} Trail';
      } else if (highway != null) {
        name = '${_capitalize(highway.replaceAll('_', ' '))} Trail';
      } else if (landuse != null || natural != null) {
        name = 'Neighborhood Park';
      } else {
        continue;
      }
    }

    final leisure = tags['leisure'] as String?;
    final highway = tags['highway'] as String?;
    final route = tags['route'] as String?;
    final natural = tags['natural'] as String?;
    final landuse = tags['landuse'] as String?;

    String typeLabel = 'park';
    if (route != null) typeLabel = 'trail';
    if (highway != null) typeLabel = 'path';
    if (leisure != null || natural != null || landuse != null)
      typeLabel = 'park';

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

    double totalMeters = 0;
    for (int i = 0; i < boundary.length - 1; i++) {
      totalMeters +=
          distCalc.as(LengthUnit.Meter, boundary[i], boundary[i + 1]);
    }
    if (totalMeters < 160) continue;

    final avgLat = boundary.map((p) => p.latitude).reduce((a, b) => a + b) /
        boundary.length;
    final avgLon = boundary.map((p) => p.longitude).reduce((a, b) => a + b) /
        boundary.length;
    final placeCenter = LatLng(avgLat, avgLon);

    if (distCalc.as(LengthUnit.Meter, center, placeCenter) > radiusMeters * 1.2)
      continue;

    seenIds.add(elId);
    places.add(
      NearbyPlace(
        id: elId,
        name: name,
        type: typeLabel,
        center: placeCenter,
        boundary: boundary,
        color: colors[colorIndex % colors.length],
      ),
    );

    colorIndex++;
    if (places.length >= 150) break;
  }

  places.sort(
    (a, b) => distCalc
        .as(LengthUnit.Meter, center, a.center)
        .compareTo(distCalc.as(LengthUnit.Meter, center, b.center)),
  );

  return places;
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _tagEmoji(String tag) {
  switch (tag) {
    case 'food':
      return '🍞';
    case 'drinks':
      return '🥤';
    case 'medicine':
      return '💊';
    case 'fun':
      return '🎾';
    case 'cosmetic':
      return '👓';
    default:
      return '📦';
  }
}

void showMapModal(
  BuildContext context, {
  Future<void> Function(GlobalKey)? runAddToCartAnimation,
  GlobalKey? inventoryTargetKey,
}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.fromLTRB(16, 24, 16, 56),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.80,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1923),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white12),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 24, spreadRadius: 4),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🐾 Cat walks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        color: Colors.white54, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: MapModalService(
                runAddToCartAnimation: runAddToCartAnimation,
                inventoryTargetKey: inventoryTargetKey,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
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

class _MapModalServiceState extends State<MapModalService>
    with TickerProviderStateMixin {
  LatLng _currentLocation = const LatLng(39.9812, -75.1554);
  final MapController _mapController = MapController();
  final GlobalKey _rewardItemKey = GlobalKey();
  StreamSubscription<Position>? _positionSubscription;

  List<NearbyPlace> _allPlaces = [];
  List<NearbyPlace> _filteredPlaces = [];
  List<ShopItem> _shopItems = [];

  final List<Map<String, dynamic>> _otherUsers = [];

  bool _loading = true;
  String _loadingMsg = 'Getting your location…';

  DistanceFilter _activeFilter = DistanceFilter.all;

  bool _showReward = false;
  ShopItem? _rewardItem;
  String _rewardPlaceName = '';

  late AnimationController _rewardAnim;
  late Animation<double> _rewardScale;
  late Animation<double> _rewardOpacity;

  @override
  void initState() {
    super.initState();
    _setupRewardAnimation();
    _initApp();
  }

  void _setupRewardAnimation() {
    _rewardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _rewardScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _rewardAnim, curve: Curves.elasticOut),
    );
    _rewardOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _rewardAnim,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  Future<void> _initApp() async {
    _activeFilter = await _TrailPersistence.loadFilter();

    try {
      _shopItems = await ShopService.loadShopAssets();
    } catch (e) {
      debugPrint('[map] shop load failed: $e');
      _shopItems = [];
    }

    await _initLocation();
  }

  void _applyFilter() {
    setState(() {
      _filteredPlaces = _allPlaces
          .where((p) => _activeFilter.matches(p.perimeterMiles))
          .toList();
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

    final tier0 =
        _shopItems.where((i) => i.tag == 'food' || i.tag == 'drinks').toList();
    final tier1 =
        _shopItems.where((i) => i.tag == 'medicine' || i.tag == 'fun').toList();
    final tier2 = _shopItems.where((i) => i.tag == 'cosmetic').toList();

    for (final place in _allPlaces) {
      final miles = place.perimeterMiles;
      List<ShopItem> pool;
      if (miles >= 4.0 && tier2.isNotEmpty) {
        pool = tier2;
      } else if (miles >= 2.0 && tier1.isNotEmpty) {
        pool = tier1;
      } else if (tier0.isNotEmpty) {
        pool = tier0;
      } else {
        pool = _shopItems;
      }

      place.rewardItem = pool[place.id.hashCode.abs() % pool.length];
    }
  }

  void _upsertOtherUser(Map<String, dynamic> userData) {
    final normalized = Map<String, dynamic>.from(userData);

    final id = normalized['id'] ??
        normalized['uid'] ??
        normalized['userId'] ??
        normalized['username'];

    if (id != null) {
      final index = _otherUsers.indexWhere(
        (u) => (u['id'] ?? u['uid'] ?? u['userId'] ?? u['username']) == id,
      );

      if (index >= 0) {
        _otherUsers[index] = normalized;
      } else {
        _otherUsers.add(normalized);
      }
      return;
    }

    final lat = (normalized['lat'] as num?)?.toDouble();
    final lng = (normalized['lng'] as num?)?.toDouble();
    final index = _otherUsers.indexWhere(
      (u) =>
          ((u['lat'] as num?)?.toDouble() == lat) &&
          ((u['lng'] as num?)?.toDouble() == lng),
    );

    if (index < 0) {
      _otherUsers.add(normalized);
    } else {
      _otherUsers[index] = normalized;
    }
  }

  Future<void> _initLocation() async {
    bool hasPermission = await GeoService.instance.checkLocationPermission();
    if (!hasPermission) {
      setState(() {
        _loadingMsg = 'Location permission denied';
        _loading = false;
      });
      return;
    }

    _service.startLocationSharing(
      onNewUserFound: (userData) {
        if (!mounted) return;

        final normalized = Map<String, dynamic>.from(userData);

        setState(() => _upsertOtherUser(normalized));
      },
    );

    Position? position = GeoService.instance.currentPosition;
    if (position == null) {
      position = await GeoService.instance.getCurrentPosition();
    }

    if (!mounted) return;

    final currentPosition = position;
    if (currentPosition != null) {
      setState(() {
        _currentLocation =
            LatLng(currentPosition.latitude, currentPosition.longitude);
        _loadingMsg = 'Finding trails & parks within 5 miles…';
      });
      _mapController.move(_currentLocation, 14.0);
    } else {
      setState(() {
        _loadingMsg = 'Could not get location';
      });
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
            (i) => i.id == savedId,
            orElse: () => _shopItems.first,
          );
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
      final prevStatus = place.status;
      place.checkUserPosition(loc);

      if (place.status == TrailStatus.completed &&
          prevStatus != TrailStatus.completed) {
        _awardItem(place);
      }
    }

    setState(() {});
  }

  Future<void> _awardItem(NearbyPlace place) async {
    await _TrailPersistence.markCompleted(
      place.id,
      rewardItemId: place.rewardItem?.id,
    );

    if (place.rewardItem != null) {
      await InventoryService.instance.addItem(place.rewardItem!);
    }

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
        if (widget.inventoryTargetKey != null) {
          unawaited(_runRewardFlight());
        } else if (runAnimation != null) {
          unawaited(runAnimation(_rewardItemKey));
        }
      });
    }

    _rewardAnim.forward(from: 0).then((_) {
      if (mounted) {
        setState(() => _showReward = false);
      }
    });
  }

  void _manualComplete(NearbyPlace place) {
    if (place.status == TrailStatus.completed) return;
    setState(() {
      place.status = TrailStatus.completed;
      place.walkedFraction = 1.0;
    });
    _awardItem(place);
  }

  Future<void> _runRewardFlight() async {
    final sourceBounds = _globalPaintBounds(_rewardItemKey);
    final targetKey = widget.inventoryTargetKey;
    final targetBounds =
        targetKey == null ? null : _globalPaintBounds(targetKey);
    final item = _rewardItem;
    final overlay = Overlay.of(context, rootOverlay: true);

    if (sourceBounds == null || targetBounds == null || item == null) return;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final rect = Rect.lerp(sourceBounds, targetBounds, animation.value)!;
          final lift = 28 * (1 - (2 * animation.value - 1).abs());

          return Positioned(
            left: rect.left,
            top: rect.top - lift,
            width: rect.width,
            height: rect.height,
            child: IgnorePointer(
              child: Transform.scale(
                scale: 1 - (animation.value * 0.35),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: _RewardItemVisual(item: item, size: 30),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    await controller.forward();
    entry.remove();
    controller.dispose();
  }

  Rect? _globalPaintBounds(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    final translation = renderObject?.getTransformTo(null).getTranslation();
    if (renderObject == null || translation == null) return null;
    return renderObject.paintBounds.shift(
      Offset(translation.x, translation.y),
    );
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
    _service.stop();
    _rewardAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
            if (_filteredPlaces.isNotEmpty)
              PolylineLayer(
                polylines: _filteredPlaces
                    .where((p) => p.boundary.length > 1)
                    .map<Polyline>(
                      (p) => Polyline(
                        points: p.boundary,
                        color: p.color.withOpacity(
                          p.status == TrailStatus.completed ? 1.0 : 0.55,
                        ),
                        strokeWidth:
                            p.status == TrailStatus.completed ? 4.5 : 2.5,
                      ),
                    )
                    .toList(),
              ),
            if (_filteredPlaces.isNotEmpty)
              MarkerLayer(
                markers: _filteredPlaces
                    .map(
                      (p) => Marker(
                        point: p.center,
                        width: 140,
                        height: 52,
                        child: _PlaceLabel(place: p),
                      ),
                    )
                    .toList(),
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLocation,
                  width: 40,
                  height: 40,
                  child: const Text('🐱', style: TextStyle(fontSize: 30)),
                ),
                ..._otherUsers.map((user) {
                  final double lat = (user['lat'] is num)
                      ? (user['lat'] as num).toDouble()
                      : 0.0;
                  final double lng = (user['lng'] is num)
                      ? (user['lng'] as num).toDouble()
                      : 0.0;
                  final String displayName =
                      (user['name'] ?? user['username'] ?? '').toString();

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 56,
                    height: 56,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🐾', style: TextStyle(fontSize: 25)),
                        if (displayName.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2535).withOpacity(0.92),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors')
              ],
            ),
          ],
        ),
        if (_loading)
          Container(
            color: const Color(0xFF0F1923).withOpacity(0.85),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF2ECC71),
                    strokeWidth: 2.5,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _loadingMsg,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '(this may take a few seconds)',
                    style: TextStyle(color: Colors.white30, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        if (!_loading)
          Positioned(
            top: 12,
            left: 56,
            right: 12,
            child: _DistanceFilterBar(
              active: _activeFilter,
              totalCount: _allPlaces.length,
              filteredCount: _filteredPlaces.length,
              onSelect: _setFilter,
            ),
          ),
        if (!_loading && _filteredPlaces.isEmpty && _allPlaces.isNotEmpty)
          Positioned(
            top: 70,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2535).withOpacity(0.97),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                'No ${_activeFilter.label} trails nearby — try a wider filter!',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        if (!_loading && _allPlaces.isEmpty)
          Positioned(
            top: 70,
            left: 16,
            right: 16,
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
                  const Text(
                    'No trails or parks found nearby.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _loading = true;
                        _loadingMsg = 'Retrying…';
                      });
                      fetchNearbyPlaces(_currentLocation).then((places) {
                        if (!mounted) return;
                        _allPlaces = places;
                        _assignRewards();
                        _applyFilter();
                        setState(() => _loading = false);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2ECC71)),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          color: Color(0xFF2ECC71),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          top: 12,
          left: 12,
          child: GestureDetector(
            onTap: () => _mapController.move(_currentLocation, 14.0),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2535).withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.my_location,
                  color: Color(0xFF2ECC71), size: 20),
            ),
          ),
        ),
        if (!_loading && _filteredPlaces.isNotEmpty)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: _PlaceLegend(
              places: _filteredPlaces,
              onTap: (p) {
                _mapController.move(p.center, 15.5);
                _showPlaceDetail(p);
              },
            ),
          ),
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
                    itemKey: _rewardItemKey,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DistanceFilterBar extends StatelessWidget {
  final DistanceFilter active;
  final int totalCount;
  final int filteredCount;
  final void Function(DistanceFilter) onSelect;

  const _DistanceFilterBar({
    required this.active,
    required this.totalCount,
    required this.filteredCount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1923).withOpacity(0.93),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📏', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          ...DistanceFilter.values.map(
            (filter) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: _FilterChip(
                label: filter.label,
                isActive: filter == active,
                onTap: () => onSelect(filter),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$filteredCount',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF2ECC71).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFF2ECC71) : Colors.white24,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF2ECC71) : Colors.white54,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

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
                const Text('✓ ',
                    style: TextStyle(color: Colors.black, fontSize: 9)),
              Flexible(
                child: Text(
                  place.name,
                  style: TextStyle(
                    color: isComplete ? Colors.black : Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
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
                      color: place.color,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
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
            child: const Text(
              '✓ collected',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

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
    final isComplete = place.status == TrailStatus.completed;
    final borderColor = isComplete ? const Color(0xFFFFD700) : place.color;
    final reward = place.rewardItem;

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
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: place.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  place.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                place.type.toUpperCase(),
                style: TextStyle(
                  color: place.color.withOpacity(0.8),
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                place.distanceLabel,
                style: const TextStyle(color: Colors.white38, fontSize: 9),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: place.walkedFraction,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? const Color(0xFFFFD700) : place.color,
              ),
              minHeight: 4,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isComplete
                    ? '✓ Done'
                    : place.status == TrailStatus.active
                        ? '${(place.walkedFraction * 100).round()}%'
                        : 'Nearby',
                style: TextStyle(
                  color: isComplete ? const Color(0xFFFFD700) : Colors.white54,
                  fontSize: 10,
                ),
              ),
              if (reward != null)
                Row(
                  children: [
                    Text(_tagEmoji(reward.tag),
                        style: const TextStyle(fontSize: 10)),
                    const SizedBox(width: 2),
                    Text(
                      reward.name,
                      style: TextStyle(
                        color:
                            isComplete ? const Color(0xFFFFD700) : place.color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceDetailSheet extends StatelessWidget {
  final NearbyPlace place;
  final VoidCallback onComplete;
  const _PlaceDetailSheet({required this.place, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final isComplete = place.status == TrailStatus.completed;
    final reward = place.rewardItem;

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
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: place.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  place.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isComplete)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD700)),
                  ),
                  child: const Text(
                    '✓ Done',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            place.type.toUpperCase(),
            style: TextStyle(
              color: place.color.withOpacity(0.8),
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatChip(
                icon: '⏱️',
                label: 'Est. time',
                value: place.estimatedMinutes < 60
                    ? '${place.estimatedMinutes} min'
                    : '${(place.estimatedMinutes / 60).toStringAsFixed(1)} hr',
                color: place.color,
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: '👟',
                label: 'Est. steps',
                value: place.estimatedSteps >= 1000
                    ? '~${(place.estimatedSteps / 1000).toStringAsFixed(1)}k'
                    : '${place.estimatedSteps}',
                color: place.color,
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: '📏',
                label: 'Distance',
                value: place.distanceLabel,
                color: place.color,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isComplete && place.status == TrailStatus.active) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Progress',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text(
                  '${(place.walkedFraction * 100).round()}%',
                  style: TextStyle(
                    color: place.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                  Text(_tagEmoji(reward.tag),
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isComplete ? 'Collected!' : 'Reward',
                          style: TextStyle(
                            color: isComplete
                                ? const Color(0xFFFFD700)
                                : Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          reward.name,
                          style: TextStyle(
                            color: isComplete
                                ? const Color(0xFFFFD700)
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          reward.description,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (isComplete)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Text('🐱', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 6),
                  Text(
                    'Trail done!',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Item added to inventory',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
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
                  boxShadow: [
                    BoxShadow(
                      color: place.color.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🐾', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 10),
                    Text(
                      'I completed this!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
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
            Text(
              value,
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardBurst extends StatelessWidget {
  final ShopItem? item;
  final String placeName;
  final GlobalKey? itemKey;

  const _RewardBurst({
    required this.item,
    required this.placeName,
    this.itemKey,
  });

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
            blurRadius: 28,
            spreadRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🐱', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 8),
          const Text(
            'Got some steps in 🚶',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            placeName,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          if (item != null) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  key: itemKey,
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5CC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _RewardItemVisual(item: item!, size: 30),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item!.name,
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'added to inventory',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          const Text(
            'Got some steps in 🚶',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RewardItemVisual extends StatelessWidget {
  final ShopItem item;
  final double size;

  const _RewardItemVisual({
    required this.item,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleForItemTag(item.tag);

    if (item.image != null && item.image!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          item.image!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            style.icon,
            color: style.accent,
            size: size,
          ),
        ),
      );
    }

    return Icon(
      style.icon,
      color: style.accent,
      size: size,
    );
  }
}

class _ItemTagStyle {
  final IconData icon;
  final Color accent;

  const _ItemTagStyle({
    required this.icon,
    required this.accent,
  });
}

const Map<String, _ItemTagStyle> _itemTagStyles = {
  'food': _ItemTagStyle(
    icon: Icons.lunch_dining_rounded,
    accent: Color(0xFFFF7043),
  ),
  'drinks': _ItemTagStyle(
    icon: Icons.local_drink_rounded,
    accent: Color(0xFF2196F3),
  ),
  'fun': _ItemTagStyle(
    icon: Icons.sports_esports_rounded,
    accent: Color(0xFF7E57C2),
  ),
  'medicine': _ItemTagStyle(
    icon: Icons.medication_rounded,
    accent: Color(0xFF26A69A),
  ),
  'cosmetic': _ItemTagStyle(
    icon: FontAwesomeIcons.glasses,
    accent: Color(0xFFE91E8C),
  ),
};

_ItemTagStyle _styleForItemTag(String tag) =>
    _itemTagStyles[tag] ??
    const _ItemTagStyle(
      icon: Icons.inventory_2_rounded,
      accent: Color(0xFF78909C),
    );
