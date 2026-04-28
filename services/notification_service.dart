import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gossip_app/models/app_notification.dart';

class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collectionForUser(String userId) {
    return _firestore.collection('users').doc(userId).collection('notifications');
  }

  Stream<List<AppNotification>> streamNotifications(String userId) {
    return _collectionForUser(userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AppNotification.fromDoc).toList());
  }

  Future<void> sendVoteNotification({
    required String recipientUserId,
    required String actorHandle,
    required bool isHit,
    required String bubbleId,
  }) async {
    await _collectionForUser(recipientUserId).add({
      'type': 'vote',
      'title': isHit ? 'Your bubble got a hit' : 'Your bubble got a downvote',
      'body': '$actorHandle reacted to one of your bubbles.',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'payload': {'bubbleId': bubbleId, 'isHit': isHit},
    });
  }

  Future<void> sendChallengeNotification({
    required String recipientUserId,
    required String challengeTitle,
    required int rewardXp,
  }) async {
    await _collectionForUser(recipientUserId).add({
      'type': 'challenge',
      'title': 'Challenge completed',
      'body': '$challengeTitle complete. +$rewardXp XP',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'payload': {'rewardXp': rewardXp},
    });
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _collectionForUser(userId).where('isRead', isEqualTo: false).limit(150).get();
    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
