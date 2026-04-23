import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:walkyourcat/services/database_service.dart';
import 'package:walkyourcat/services/geo_service.dart';

class LocationDbService {
  FirebaseDatabase? _db;
  DatabaseReference? _userRef; //nullable, may never init if Firebase is broken
  StreamSubscription<DatabaseEvent>? _listener;

  // try to grab the DB instance once; if Firebase isn't configured just leave _db null
    try {
      _db = DatabaseService.instance.firebaseDb;
    } catch (e) {
      _db = null;
      // ignore: avoid_print
      print('[LocationDbService] Firebase unavailable, multiplayer disabled: $e');
    }
  }

  Future<void> startLocationSharing({
    required Function(Map data) onNewUserFound,
  }) async {
    if (_db == null) return;

    Position? position = await GeoService.instance.getCurrentPosition();
    if (position == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      _userRef = _db!.ref("active_users").push();

      // Automatically delete this entry when the app closes/disconnects
      await _userRef!.onDisconnect().remove();

      // Slightly fuzz the position for privacy
      await _userRef!.set({
        "lat": position.latitude  + Random().nextDouble() / 100,
        "lng": position.longitude + Random().nextDouble() / 100,
        "joinedAt": now,
      });

      // Listen for other users who join after us
      _listener = _db!
          .ref("active_users")
          .orderByChild("joinedAt")
          .startAt(now + 1)
          .onChildAdded
          .listen((event) {
        if (event.snapshot.value != null) {
          onNewUserFound(event.snapshot.value as Map);
        }
      });
    } catch (e) {
      // if any Firebase call fails mid-way, clean up what we can nd leave the rest of the map working normally
      print('[LocationDbService] Error during location sharing setup: $e');
      _userRef = null;
    }
  }

  void stop() {
    _listener?.cancel();
    _listener = null;

    //_userRef is nullable now so this won't throw if Firebase never inited
    try {
      _userRef?.remove();
    } catch (_) {}

    _userRef = null;
  }
}
