import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gossip_app/models/user_reputation.dart';
import 'package:gossip_app/services/auth_service.dart';

class ReputationService {
  ReputationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<UserReputation> getReputation({required String userId}) async {
    final now = DateTime.now();
    final createdAt = _auth.currentUser?.metadata.creationTime ?? now;
    final accountAgeDays = math.max(0, now.difference(createdAt).inDays);
    final planTier = await _subscriptionTierFor(userId);

    final bubblesSnapshot = await _firestore
        .collection('bubbles')
        .where('authorId', isEqualTo: userId)
        .limit(250)
        .get();

    var hits = 0;
    var downvotes = 0;
    var postsLast24h = 0;

    for (final doc in bubblesSnapshot.docs) {
      final data = doc.data();
      hits += (data['hits'] as num?)?.toInt() ?? 0;
      downvotes += (data['downvotes'] as num?)?.toInt() ?? 0;
      final created = (data['createdAt'] as Timestamp?)?.toDate();
      if (created != null && now.difference(created).inHours < 24) {
        postsLast24h++;
      }
    }

    final totalPosts = bubblesSnapshot.docs.length;
    final engagementTotal = math.max(1, hits + downvotes);
    final positiveRatio = hits / engagementTotal;
    final ageBonus = math.min(20, accountAgeDays ~/ 3);
    final activityBonus = math.min(10, totalPosts ~/ 4);

    final planBonus = switch (planTier) {
      AuthService.planPremium => 5,
      AuthService.planBusiness => 8,
      _ => 0,
    };
    final trustRaw =
        (40 + (positiveRatio * 35) + ageBonus + activityBonus + planBonus).round();
    final trustScore = trustRaw.clamp(5, 100);

    final dailyPostLimit = _dailyLimitFor(
      trustScore: trustScore,
      accountAgeDays: accountAgeDays,
      subscriptionTier: planTier,
    );

    return UserReputation(
      trustScore: trustScore,
      accountAgeDays: accountAgeDays,
      dailyPostLimit: dailyPostLimit,
      postsLast24h: postsLast24h,
      totalPosts: totalPosts,
      totalHits: hits,
      totalDownvotes: downvotes,
    );
  }

  Future<String> _subscriptionTierFor(String userId) async {
    final profile = await _firestore.collection('profiles').doc(userId).get();
    final tier = (profile.data()?['subscriptionTier'] as String?)?.trim();
    if (tier == null || tier.isEmpty) {
      return AuthService.planBasic;
    }
    return tier;
  }

  int _dailyLimitFor({
    required int trustScore,
    required int accountAgeDays,
    required String subscriptionTier,
  }) {
    if (subscriptionTier == AuthService.planBusiness) {
      return 80;
    }
    if (subscriptionTier == AuthService.planPremium) {
      if (trustScore >= 80) return 36;
      if (trustScore >= 60) return 28;
      return 20;
    }

    if (accountAgeDays <= 1) return 4;
    if (accountAgeDays <= 7) return trustScore >= 60 ? 7 : 5;
    if (trustScore >= 80) return 14;
    if (trustScore >= 60) return 10;
    return 6;
  }
}
