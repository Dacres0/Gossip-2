import 'package:cloud_firestore/cloud_firestore.dart';

class NearbyPlayer {
  const NearbyPlayer({
    required this.userId,
    required this.displayHandle,
    required this.avatar,
    required this.lat,
    required this.lng,
    required this.lastSeenAt,
  });

  final String userId;
  final String displayHandle;
  final String avatar;
  final double lat;
  final double lng;
  final DateTime lastSeenAt;

  factory NearbyPlayer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return NearbyPlayer(
      userId: doc.id,
      displayHandle: (data['displayHandle'] as String?) ?? '@anon',
      avatar: (data['avatar'] as String?) ?? '🙂',
      lat: (data['lat'] as num?)?.toDouble() ?? 0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0,
      lastSeenAt: (data['lastSeenAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
