import 'package:flutter/material.dart';
import 'package:gossip_app/models/challenge_progress.dart';
import 'package:gossip_app/services/challenge_service.dart';
import 'package:gossip_app/services/location_service.dart';
import 'package:gossip_app/services/notification_service.dart';
import 'package:latlong2/latlong.dart';

class ChallengesScreen extends StatefulWidget {
  ChallengesScreen({
    super.key,
    required this.anchor,
    required this.currentCenter,
    required this.displayHandle,
    required this.userId,
    required this.onOpenMap,
  });

  final LatLng anchor;
  final LatLng currentCenter;
  final String displayHandle;
  final String userId;
  final VoidCallback onOpenMap;

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final LocationService _locationService = LocationService();
  final ChallengeService _challengeService = ChallengeService();
  final NotificationService _notificationService = NotificationService();

  Set<String> _claimedToday = <String>{};
  int _xp = 0;
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final claimed = await _challengeService.getClaimedToday(userId: widget.userId);
      final progress = await _challengeService.getUserProgress(widget.userId);
      if (!mounted) return;
      setState(() {
        _claimedToday = claimed;
        _xp = progress['xp'] ?? 0;
        _streak = progress['streak'] ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final challenges = _challengeService.buildDailyChallenges(
      anchor: widget.anchor,
      claimedChallengeIds: _claimedToday,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1220), Color(0xFF121B34), Color(0xFF1A1028)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Text('Challenges', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Rotate daily challenges for ${widget.displayHandle}. Earn XP, streaks, and leaderboard rank.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 20),
              _OverviewCard(
                onOpenMap: widget.onOpenMap,
                xp: _xp,
                streak: _streak,
                loading: _loading,
              ),
              const SizedBox(height: 20),
              ...challenges.map((challenge) {
                final distance = _locationService.distanceInMeters(
                  lat1: widget.currentCenter.latitude,
                  lng1: widget.currentCenter.longitude,
                  lat2: challenge.target.latitude,
                  lng2: challenge.target.longitude,
                );
                final unlocked = distance <= challenge.unlockRadiusMeters;
                final progress =
                    (1 -
                            ((distance - challenge.unlockRadiusMeters) /
                                challenge.trackRadiusMeters))
                        .clamp(0.0, 1.0)
                        .toDouble();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ChallengeCard(
                    challenge: challenge,
                    distanceMeters: distance,
                    unlocked: unlocked,
                    progress: progress,
                    onClaim: unlocked && !challenge.claimed
                        ? () => _claimChallenge(challenge)
                        : null,
                  ),
                );
              }),
              const SizedBox(height: 6),
              Text('Leaderboard', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _challengeService.streamLeaderboard(),
                builder: (context, snapshot) {
                  final leaders = snapshot.data ?? const <Map<String, dynamic>>[];
                  if (leaders.isEmpty) {
                    return Text(
                      'No leaderboard data yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                    );
                  }

                  return Column(
                    children: List<Widget>.generate(leaders.take(5).length, (index) {
                      final leader = leaders[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Row(
                          children: [
                            Text('#${index + 1}', style: theme.textTheme.titleMedium),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('@${leader['username']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            Text('${leader['xp']} XP', style: theme.textTheme.bodyMedium),
                            const SizedBox(width: 10),
                            Text('🔥 ${leader['streak']}', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _claimChallenge(ChallengeProgress challenge) async {
    final ok = await _challengeService.claimChallenge(userId: widget.userId, challenge: challenge);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already claimed.')),
      );
      return;
    }

    await _notificationService.sendChallengeNotification(
      recipientUserId: widget.userId,
      challengeTitle: challenge.title,
      rewardXp: challenge.rewardXp,
    );
    await _loadProgress();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Claimed ${challenge.rewardLabel} from ${challenge.title}.')),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.onOpenMap,
    required this.xp,
    required this.streak,
    required this.loading,
  });

  final VoidCallback onOpenMap;
  final int xp;
  final int streak;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How it works', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            'Walk in real life toward each target zone. Challenges unlock from your live GPS position only.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Chip(label: loading ? '...' : '$xp XP'),
              const SizedBox(width: 8),
              _Chip(label: loading ? '...' : '🔥 $streak streak'),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onOpenMap,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Back to map'),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.distanceMeters,
    required this.unlocked,
    required this.progress,
    required this.onClaim,
  });

  final ChallengeProgress challenge;
  final double distanceMeters;
  final bool unlocked;
  final double progress;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = unlocked ? Colors.greenAccent : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  challenge.claimed ? 'Claimed' : (unlocked ? 'Unlocked' : 'In range soon'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _distanceText(distanceMeters),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(challenge.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            challenge.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.workspace_premium_outlined, color: accent),
              const SizedBox(width: 8),
              Text(
                challenge.rewardLabel,
                style: theme.textTheme.bodyMedium?.copyWith(color: accent),
              ),
              const Spacer(),
              TextButton(
                onPressed: onClaim,
                child: Text(challenge.claimed ? 'Done' : 'Claim'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _distanceText(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km away';
    }
    return '${meters.toStringAsFixed(0)} m away';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}
