import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gossip_app/models/gossip_bubble.dart';

class DuplicateVoteException implements Exception {
  const DuplicateVoteException();
}

class DuplicateReportException implements Exception {
  const DuplicateReportException();
}

class BubbleService {
  BubbleService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('bubbles');

  Stream<List<GossipBubble>> streamRecentBubbles() {
    return _collection
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(GossipBubble.fromDoc).toList());
  }

  Future<void> addBubble(GossipBubble bubble) async {
    await _collection.add(bubble.toMap());
  }

  Future<void> voteOnBubble({
    required String bubbleId,
    required bool isHit,
    required String voterId,
  }) async {
    if (voterId.trim().isEmpty) {
      throw ArgumentError('voterId cannot be empty');
    }

    final field = isHit ? 'hits' : 'downvotes';
    final bubbleRef = _collection.doc(bubbleId);
    final voteRef = bubbleRef.collection('votes').doc(voterId);

    await _firestore.runTransaction((transaction) async {
      final existingVote = await transaction.get(voteRef);
      if (existingVote.exists) {
        throw const DuplicateVoteException();
      }

      transaction.update(bubbleRef, {field: FieldValue.increment(1)});
      transaction.set(voteRef, {
        'isHit': isHit,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> reportBubble({
    required String bubbleId,
    required String reporterId,
    String reason = 'inappropriate',
    String? details,
  }) async {
    if (reporterId.trim().isEmpty) {
      throw ArgumentError('reporterId cannot be empty');
    }

    final bubbleRef = _collection.doc(bubbleId);
    final reportRef = bubbleRef.collection('reports').doc(reporterId);

    await _firestore.runTransaction((transaction) async {
      final existingReport = await transaction.get(reportRef);
      if (existingReport.exists) {
        throw const DuplicateReportException();
      }

      transaction.update(bubbleRef, {
        'reportCount': FieldValue.increment(1),
      });
      transaction.set(reportRef, {
        'reason': reason,
        'details': details,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
