import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationDbService {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(), 
    databaseURL: "https://wyc-2025-default-rtdb.firebaseio.com/",
  );

  late DatabaseReference _userRef;
  StreamSubscription<DatabaseEvent>? _listener;

  Future<void> startLocationSharing({
    required Function(Map data) onNewUserFound,
  }) async {
    Position? position = await GeoService.instance.getCurrentPosition();
    if (position == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    _userRef = _db.ref("active_users").push();
    
    // Automatically delete from DB when app closes/disconnects
    // If it works needs testing
    await _userRef.onDisconnect().remove();

    // Some privacy respect
    await _userRef.set({
      "lat": position.latitude + Random().nextDouble() / 100,
      "lng": position.longitude + Random().nextDouble() / 100,
      "joinedAt": now,
    });

    // Listener object to recieve data
    _listener = _db
        .ref("active_users")
        .orderByChild("joinedAt")
        .startAt(now + 1)
        .onChildAdded
        .listen((event) {
      if (event.snapshot.value != null) {
        onNewUserFound(event.snapshot.value as Map);
      }
    });
  }

  void stop() {
    _userRef.remove();
    _listener?.cancel();
  }
}