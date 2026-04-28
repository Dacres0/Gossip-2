class UserReputation {
  const UserReputation({
    required this.trustScore,
    required this.accountAgeDays,
    required this.dailyPostLimit,
    required this.postsLast24h,
    required this.totalPosts,
    required this.totalHits,
    required this.totalDownvotes,
  });

  final int trustScore;
  final int accountAgeDays;
  final int dailyPostLimit;
  final int postsLast24h;
  final int totalPosts;
  final int totalHits;
  final int totalDownvotes;

  bool get canPostNow => postsLast24h < dailyPostLimit;
}
