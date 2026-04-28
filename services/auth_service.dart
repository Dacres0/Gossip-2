import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumStatus {
  const PremiumStatus({
    required this.isActive,
    required this.tier,
    this.expiresAt,
    this.since,
  });

  final bool isActive;
  final String tier;
  final DateTime? expiresAt;
  final DateTime? since;

  bool get isLifetime => tier == 'lifetime';

  bool get isBasic => tier == 'basic';
  bool get isPremium => tier == 'premium';
  bool get isBusiness => tier == 'business';
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  static const _anonIdKey = 'anon_display_id';
  static const _usernameKey = 'profile_username';
  static const _avatarKey = 'profile_avatar';
  static const _votePrefix = 'bubble_vote_';
  static const _profilesCollection = 'profiles';

  static const String planBasic = 'basic';
  static const String planPremium = 'premium';
  static const String planBusiness = 'business';

  static const int premiumMonthlyPricePence = 1000;
  static const int businessMonthlyPricePence = 12500;
  static const String premiumCheckoutUrl = '';
  static const String businessCheckoutUrl =
      'https://buy.stripe.com/test_4gM00i4NW92x4TmfYx83C00';

  Future<User?> ensureSignedIn() async {
    if (_auth.currentUser != null) {
      return _auth.currentUser;
    }
    final credential = await _auth.signInAnonymously();
    return credential.user;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> linkWithEmail({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user to upgrade.',
      );
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    return user.linkWithCredential(credential);
  }

  Future<void> signOut() => _auth.signOut();

  Future<String> getDisplayId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_anonIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final random = Random();
    final id = '#${1000 + random.nextInt(9000)}';
    await prefs.setString(_anonIdKey, id);
    return id;
  }

  Future<String?> getUsername() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final profile = await _firestore
            .collection(_profilesCollection)
            .doc(user.uid)
            .get();
        final cloudUsername = profile.data()?['username'] as String?;
        final trimmed = cloudUsername?.trim().toLowerCase();
        if (trimmed != null && trimmed.isNotEmpty) {
          return trimmed;
        }
      } catch (_) {
        // Fall back to local cache if cloud read fails.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_usernameKey)?.trim();
    if (username == null || username.isEmpty) {
      return null;
    }
    return username;
  }

  Future<void> saveUsername(String username) async {
    final normalized = username.trim().toLowerCase();
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection(_profilesCollection).doc(user.uid).set({
        'username': normalized,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, normalized);
  }

  Future<String> getAvatar() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final profile = await _firestore
            .collection(_profilesCollection)
            .doc(user.uid)
            .get();
        final cloudAvatar = (profile.data()?['avatar'] as String?)?.trim();
        if (cloudAvatar != null && cloudAvatar.isNotEmpty) {
          return cloudAvatar;
        }
      } catch (_) {
        // Fall back to local cache if cloud read fails.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final avatar = prefs.getString(_avatarKey)?.trim();
    if (avatar == null || avatar.isEmpty) {
      return '🙂';
    }
    return avatar;
  }

  Future<void> saveAvatar(String avatar) async {
    final normalized = avatar.trim();
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection(_profilesCollection).doc(user.uid).set({
        'avatar': normalized,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarKey, normalized);
  }

  Future<String?> getStoredVote(String bubbleId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_votePrefix$bubbleId');
  }

  Future<void> saveVote({required String bubbleId, required bool isHit}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_votePrefix$bubbleId', isHit ? 'hit' : 'downvote');
  }

  Future<void> ensureDefaultPlanAssigned() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    final profileRef = _firestore.collection(_profilesCollection).doc(user.uid);
    final existing = await profileRef.get();
    final data = existing.data() ?? <String, dynamic>{};
    final hasPlan = (data['subscriptionTier'] as String?)?.trim().isNotEmpty ?? false;

    if (hasPlan) {
      return;
    }

    await profileRef.set({
      'subscriptionActive': true,
      'subscriptionTier': planBasic,
      'subscriptionSince': FieldValue.serverTimestamp(),
      'subscriptionExpiresAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<PremiumStatus> getPremiumStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const PremiumStatus(isActive: true, tier: planBasic);
    }

    final profile = await _firestore.collection(_profilesCollection).doc(user.uid).get();
    final data = profile.data() ?? <String, dynamic>{};

    final tier = (data['subscriptionTier'] as String?) ?? planBasic;
    final active = (data['subscriptionActive'] as bool?) ?? true;
    final expiresAt = (data['subscriptionExpiresAt'] as Timestamp?)?.toDate();
    final since = (data['subscriptionSince'] as Timestamp?)?.toDate();

    final hasExpired = expiresAt != null && DateTime.now().isAfter(expiresAt);
    if (hasExpired && tier != planBasic) {
      return const PremiumStatus(isActive: true, tier: planBasic);
    }

    return PremiumStatus(
      isActive: active && !hasExpired,
      tier: tier,
      expiresAt: expiresAt,
      since: since,
    );
  }

  Future<void> purchasePremium({required String tier}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user for subscription purchase.',
      );
    }

    DateTime expiresAt;
    final now = DateTime.now();
    switch (tier) {
      case planPremium:
      case planBusiness:
        expiresAt = now.add(const Duration(days: 30));
        break;
      default:
        throw ArgumentError('Unsupported premium tier: $tier');
    }

    await _firestore.collection(_profilesCollection).doc(user.uid).set({
      'subscriptionActive': true,
      'subscriptionTier': tier,
      'subscriptionSince': FieldValue.serverTimestamp(),
      'subscriptionExpiresAt': Timestamp.fromDate(expiresAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> cancelPremium() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection(_profilesCollection).doc(user.uid).set({
      'subscriptionActive': true,
      'subscriptionTier': planBasic,
      'subscriptionExpiresAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
