import 'package:cloud_firestore/cloud_firestore.dart';

class GossipBubble {
  GossipBubble({
    required this.id,
    required this.message,
    required this.lat,
    required this.lng,
    required this.createdAt,
    required this.expiresAt,
    required this.authorId,
    required this.authorLabel,
    required this.hits,
    required this.downvotes,
    this.reportCount = 0,
    this.bubbleType = 'standard',
    this.offerHeadline,
    this.isBoosted = false,
    this.moderationFlags = const <String>[],
  });

  final String id;
  final String message;
  final double lat;
  final double lng;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String authorId;
  final String authorLabel;
  final int hits;
  final int downvotes;
  final int reportCount;
  final String bubbleType;
  final String? offerHeadline;
  final bool isBoosted;
  final List<String> moderationFlags;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  double get credibilityScore {
    final interaction = (hits * 2.0) - (downvotes * 1.5) - (reportCount * 2.0);
    final ageHours = DateTime.now().difference(createdAt).inMinutes / 60;
    final freshnessBoost = ageHours < 6 ? (6 - ageHours) * 0.25 : 0.0;
    return interaction + freshnessBoost;
  }

  bool get shouldHideForModeration => reportCount >= 5;

  bool get isBusinessOffer => bubbleType == 'business_offer';

  factory GossipBubble.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return GossipBubble(
      id: doc.id,
      message: (data['message'] as String?) ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      authorId: (data['authorId'] as String?) ?? 'anon',
      authorLabel:
          (data['authorLabel'] as String?) ??
          (data['authorId'] as String?) ??
          'anon',
      hits: (data['hits'] as num?)?.toInt() ?? 0,
      downvotes: (data['downvotes'] as num?)?.toInt() ?? 0,
      reportCount: (data['reportCount'] as num?)?.toInt() ?? 0,
      bubbleType: (data['bubbleType'] as String?) ?? 'standard',
      offerHeadline: (data['offerHeadline'] as String?)?.trim(),
      isBoosted: (data['isBoosted'] as bool?) ?? false,
      moderationFlags: ((data['moderationFlags'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'lat': lat,
      'lng': lng,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'authorId': authorId,
      'authorLabel': authorLabel,
      'hits': hits,
      'downvotes': downvotes,
      'reportCount': reportCount,
      'bubbleType': bubbleType,
      'offerHeadline': offerHeadline,
      'isBoosted': isBoosted,
      'moderationFlags': moderationFlags,
    };
  }
}
