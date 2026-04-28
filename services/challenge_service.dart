import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gossip_app/models/challenge_progress.dart';
import 'package:latlong2/latlong.dart';

class ChallengeService {
  ChallengeService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Set<String>> getClaimedToday({required String userId}) async {
    final dayKey = _dayKey(DateTime.now());
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('challengeClaims')
        .where('dayKey', isEqualTo: dayKey)
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['challengeId'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  List<ChallengeProgress> buildDailyChallenges({
    required LatLng anchor,
    required Set<String> claimedChallengeIds,
  }) {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final rand = math.Random(seed);

    final offsets = <LatLng>[
      LatLng(_offset(rand), _offset(rand)),
      LatLng(_offset(rand), _offset(rand)),
      LatLng(_offset(rand), _offset(rand)),
    ];

    final templates = [
      ('Scout Ping', 'Reach a nearby rumor zone and claim quick XP.', 25, 140.0, 1200.0),
      ('Park Drift', 'Push further and keep your streak alive.', 40, 220.0, 1800.0),
      ('Long Route', 'Go long-range to unlock a premium badge.', 60, 280.0, 2600.0),
    ];

    return List<ChallengeProgress>.generate(3, (index) {
      final id = '${_dayKey(now)}-$index';
      final t = templates[index];
      final target = LatLng(
        anchor.latitude + offsets[index].latitude,
        anchor.longitude + offsets[index].longitude,
      );
      return ChallengeProgress(
        id: id,
        title: t.$1,
        subtitle: t.$2,
        rewardXp: t.$3,
        rewardLabel: '+${t.$3} XP',
        target: target,
        unlockRadiusMeters: t.$4,
        trackRadiusMeters: t.$5,
        claimed: claimedChallengeIds.contains(id),
      );
    });
  }

  Future<bool> claimChallenge({
    required String userId,
    required ChallengeProgress challenge,
  }) async {
    final userRef = _firestore.collection('profiles').doc(userId);
    final claimRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('challengeClaims')
        .doc(challenge.id);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayKey = _dayKey(today);

    return _firestore.runTransaction<bool>((transaction) async {
      final existingClaim = await transaction.get(claimRef);
      if (existingClaim.exists) {
        return false;
      }

      final profileDoc = await transaction.get(userRef);
      final profile = profileDoc.data() ?? <String, dynamic>{};
      final currentXp = (profile['xp'] as num?)?.toInt() ?? 0;
      final currentStreak = (profile['challengeStreak'] as num?)?.toInt() ?? 0;
      final lastClaimTimestamp = profile['lastChallengeClaimAt'] as Timestamp?;
      final lastClaimDate = lastClaimTimestamp?.toDate();

      var nextStreak = 1;
      if (lastClaimDate != null) {
        final last = DateTime(lastClaimDate.year, lastClaimDate.month, lastClaimDate.day);
        final delta = today.difference(last).inDays;
        if (delta == 0) {
          nextStreak = currentStreak;
        } else if (delta == 1) {
          nextStreak = currentStreak + 1;
        }
      }

      transaction.set(claimRef, {
        'challengeId': challenge.id,
        'rewardXp': challenge.rewardXp,
        'dayKey': dayKey,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(userRef, {
        'xp': currentXp + challenge.rewardXp,
        'challengeStreak': nextStreak,
        'lastChallengeClaimAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    });
  }

  Stream<List<Map<String, dynamic>>> streamLeaderboard() {
    return _firestore
        .collection('profiles')
        .orderBy('xp', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {
                  'userId': doc.id,
                  'username': (doc.data()['username'] as String?) ?? 'anon',
                  'xp': (doc.data()['xp'] as num?)?.toInt() ?? 0,
                  'streak': (doc.data()['challengeStreak'] as num?)?.toInt() ?? 0,
                },
              )
              .toList(),
        );
  }

  Future<Map<String, int>> getUserProgress(String userId) async {
    final doc = await _firestore.collection('profiles').doc(userId).get();
    final data = doc.data() ?? <String, dynamic>{};
    return {
      'xp': (data['xp'] as num?)?.toInt() ?? 0,
      'streak': (data['challengeStreak'] as num?)?.toInt() ?? 0,
    };
  }

  String _dayKey(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  double _offset(math.Random rand) {
    return (rand.nextDouble() * 0.008) - 0.004;
  }
}
