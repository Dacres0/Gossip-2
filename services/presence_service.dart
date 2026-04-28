import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gossip_app/models/nearby_player.dart';
import 'package:latlong2/latlong.dart';

class PresenceService {
  PresenceService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> updatePresence({
    required String userId,
    required String displayHandle,
    required String avatar,
    required LatLng location,
  }) async {
    await _firestore.collection('profiles').doc(userId).set({
      'displayHandle': displayHandle,
      'avatar': avatar,
      'lat': location.latitude,
      'lng': location.longitude,
      'lastSeenAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<NearbyPlayer>> streamNearbyPlayers({required String selfUserId}) {
    final cutoff = Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 15)));

    return _firestore
        .collection('profiles')
        .where('lastSeenAt', isGreaterThan: cutoff)
        .orderBy('lastSeenAt', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(NearbyPlayer.fromDoc)
              .where((player) => player.userId != selfUserId)
              .toList(),
        );
  }
}
