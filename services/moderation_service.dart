import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gossip_app/services/reputation_service.dart';

class ModerationResult {
  const ModerationResult({
    required this.allowed,
    required this.userMessage,
    this.flagForReview = false,
    this.flags = const <String>[],
  });

  final bool allowed;
  final String userMessage;
  final bool flagForReview;
  final List<String> flags;
}

class ModerationService {
  ModerationService({FirebaseFirestore? firestore, ReputationService? reputationService})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _reputationService = reputationService ?? ReputationService();

  final FirebaseFirestore _firestore;
  final ReputationService _reputationService;

  static const Set<String> _blockedTerms = {
    'slur1',
    'slur2',
    'kill',
    'rape',
  };

  Future<ModerationResult> validateNewBubble({
    required String authorId,
    required String message,
    required String subscriptionTier,
    String bubbleType = 'standard',
  }) async {
    final normalized = message.trim().toLowerCase();

    final isBusinessBubble = bubbleType == 'business_offer';
    if (isBusinessBubble && subscriptionTier != 'business') {
      return const ModerationResult(
        allowed: false,
        userMessage: 'Business offer bubbles require the Business plan.',
      );
    }

    if (normalized.length < 4) {
      return const ModerationResult(
        allowed: false,
        userMessage: 'Message is too short.',
      );
    }

    if (_containsBlockedTerm(normalized)) {
      return const ModerationResult(
        allowed: false,
        userMessage: 'That message violates community rules.',
      );
    }

    if (RegExp(r'(.)\1{7,}').hasMatch(normalized)) {
      return const ModerationResult(
        allowed: false,
        userMessage: 'Message looks like spam.',
      );
    }

    if (subscriptionTier == 'basic' && normalized.length > 180) {
      return const ModerationResult(
        allowed: false,
        userMessage: 'Basic plan supports up to 180 characters per bubble.',
      );
    }

    final reputation = await _reputationService.getReputation(userId: authorId);
    if (!reputation.canPostNow) {
      return ModerationResult(
        allowed: false,
        userMessage:
            'Posting limit reached (${reputation.postsLast24h}/${reputation.dailyPostLimit} in 24h).',
      );
    }

    final duplicate = await _looksDuplicate(authorId: authorId, normalized: normalized);
    if (duplicate) {
      return const ModerationResult(
        allowed: false,
        userMessage: 'Too similar to your recent post. Try a fresh update.',
      );
    }

    final flags = <String>[];
    if (reputation.trustScore < 25) {
      flags.add('low_trust_author');
    }

    return ModerationResult(
      allowed: true,
      userMessage: 'Approved',
      flagForReview: flags.isNotEmpty,
      flags: flags,
    );
  }

  bool _containsBlockedTerm(String normalized) {
    for (final term in _blockedTerms) {
      if (normalized.contains(term)) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _looksDuplicate({
    required String authorId,
    required String normalized,
  }) async {
    final snapshot = await _firestore
        .collection('bubbles')
        .where('authorId', isEqualTo: authorId)
        .limit(40)
        .get();

    final docs = snapshot.docs.toList()
      ..sort((a, b) {
        final aCreated = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        final bCreated = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        return bCreated.compareTo(aCreated);
      });

    for (final doc in docs.take(12)) {
      final existing = (doc.data()['message'] as String?)?.trim().toLowerCase() ?? '';
      if (existing == normalized) {
        return true;
      }
    }

    return false;
  }
}
