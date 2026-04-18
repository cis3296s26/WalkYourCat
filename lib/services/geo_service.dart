import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class GeoService {
  static final GeoService instance = GeoService._init();
  
  Position? _currentPosition;
  Timer? _refreshTimer;
  final StreamController<Position?> _positionController = StreamController<Position?>.broadcast();

  GeoService._init();

  /// Stream of position updates, might be useful for the map?
  Stream<Position?> get positionStream => _positionController.stream;

  /// Current cached position
  Position? get currentPosition => _currentPosition;

  /// Optimized to ensure a single interface for location management
  Future<void> initTracking() async {
    bool hasPermission = await checkLocationPermission();
    if (!hasPermission) return;

    await _updatePosition();

    // Refresh every minute
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) => _updatePosition());
  }

  Future<void> _updatePosition() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      _positionController.add(_currentPosition);
    } catch (e) {
      _positionController.addError(e);
    }
  }

  Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return false;
      }
    }
    return true;
  }

  /// Manually refresh the current position
  Future<Position?> getCurrentPosition() async {
    await _updatePosition();
    return _currentPosition;
  }

  Future<bool> checkActivityRecognitionPermission() async {
    bool granted = await Permission.activityRecognition.isGranted;

    if (!granted) {
      granted = await Permission.activityRecognition.request() ==
          PermissionStatus.granted;
    }

    return granted;
  }

  void dispose() {
    _refreshTimer?.cancel();
    _positionController.close();
  }
}
