import 'package:latlong2/latlong.dart';

class ChallengeProgress {
  const ChallengeProgress({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.rewardXp,
    required this.rewardLabel,
    required this.target,
    required this.unlockRadiusMeters,
    required this.trackRadiusMeters,
    required this.claimed,
  });

  final String id;
  final String title;
  final String subtitle;
  final int rewardXp;
  final String rewardLabel;
  final LatLng target;
  final double unlockRadiusMeters;
  final double trackRadiusMeters;
  final bool claimed;

  ChallengeProgress copyWith({bool? claimed}) {
    return ChallengeProgress(
      id: id,
      title: title,
      subtitle: subtitle,
      rewardXp: rewardXp,
      rewardLabel: rewardLabel,
      target: target,
      unlockRadiusMeters: unlockRadiusMeters,
      trackRadiusMeters: trackRadiusMeters,
      claimed: claimed ?? this.claimed,
    );
  }
}
