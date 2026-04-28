import 'package:flutter/material.dart';
import 'package:gossip_app/models/gossip_bubble.dart';
import 'package:gossip_app/models/travel_summary.dart';
import 'package:gossip_app/models/user_reputation.dart';
import 'package:gossip_app/services/challenge_service.dart';
import 'package:gossip_app/services/reputation_service.dart';
import 'package:gossip_app/services/travel_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.authorKey,
    required this.displayHandle,
    required this.username,
    required this.bubbleStream,
    required this.onSaveUsername,
    required this.avatar,
    required this.onSaveAvatar,
    required this.onSignOut,
    required this.isAnonymous,
    required this.onUpgradeAccount,
    required this.subscriptionTier,
    required this.subscriptionActive,
    required this.subscriptionExpiresAt,
    required this.onPurchasePlan,
    required this.onDowngradeToBasic,
    required this.premiumCheckoutUrl,
    required this.businessCheckoutUrl,
  });

  final String authorKey;
  final String displayHandle;
  final String? username;
  final Stream<List<GossipBubble>> bubbleStream;
  final Future<void> Function(String username) onSaveUsername;
  final String avatar;
  final Future<void> Function(String avatar) onSaveAvatar;
  final Future<void> Function() onSignOut;
  final bool isAnonymous;
  final Future<void> Function() onUpgradeAccount;
  final String subscriptionTier;
  final bool subscriptionActive;
  final DateTime? subscriptionExpiresAt;
  final Future<void> Function(String planTier) onPurchasePlan;
  final Future<void> Function() onDowngradeToBasic;
  final String premiumCheckoutUrl;
  final String businessCheckoutUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF11111D), Color(0xFF17152A), Color(0xFF251330)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<GossipBubble>>(
            stream: bubbleStream,
            builder: (context, snapshot) {
              final allBubbles = snapshot.data ?? const <GossipBubble>[];
              final myBubbles =
                  allBubbles
                      .where((bubble) => bubble.authorId == authorKey)
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              final hits = myBubbles.fold<int>(
                0,
                (sum, bubble) => sum + bubble.hits,
              );
              final downvotes = myBubbles.fold<int>(
                0,
                (sum, bubble) => sum + bubble.downvotes,
              );

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Profile',
                                style: theme.textTheme.headlineMedium,
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => _showUsernameSheet(context),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit username',
                              ),
                              IconButton(
                                onPressed: () async {
                                  await onSignOut();
                                },
                                icon: const Icon(Icons.logout),
                                tooltip: 'Sign out',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _ProfileHero(
                            displayHandle: displayHandle,
                            avatar: avatar,
                            bubbles: myBubbles.length,
                            hits: hits,
                            downvotes: downvotes,
                            onEditUsername: () => _showUsernameSheet(context),
                            onEditAvatar: () => _showAvatarSheet(context),
                            isAnonymous: isAnonymous,
                            onUpgradeAccount: onUpgradeAccount,
                          ),
                          const SizedBox(height: 16),
                          _ProgressInsights(userId: authorKey),
                          const SizedBox(height: 16),
                          _CountryTravelInsights(userId: authorKey),
                          const SizedBox(height: 16),
                          _SubscriptionPanel(
                            tier: subscriptionTier,
                            active: subscriptionActive,
                            expiresAt: subscriptionExpiresAt,
                            onPurchasePlan: onPurchasePlan,
                            onDowngradeToBasic: onDowngradeToBasic,
                            premiumCheckoutUrl: premiumCheckoutUrl,
                            businessCheckoutUrl: businessCheckoutUrl,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Only usernames are public. Keep it handle-only: letters, numbers, underscores.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Text(
                                'Recent bubbles',
                                style: theme.textTheme.titleLarge,
                              ),
                              const Spacer(),
                              Text(
                                '${myBubbles.length} posts',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  if (myBubbles.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No bubbles yet. Drop one from the map and your profile grid will fill in here.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _BubbleTile(bubble: myBubbles[index]),
                          childCount: myBubbles.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.94,
                            ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showUsernameSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: username ?? '');
    String? errorMessage;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose a username', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Use 3-18 characters: letters, numbers, underscores.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLength: 18,
                    decoration: const InputDecoration(
                      hintText: 'nightowl',
                      prefixText: '@',
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final candidate = controller.text.trim().toLowerCase();
                        final usernamePattern = RegExp(r'^[a-z0-9_]{3,18}$');
                        if (!usernamePattern.hasMatch(candidate)) {
                          setModalState(() {
                            errorMessage =
                                'Pick a handle with only letters, numbers, or underscores.';
                          });
                          return;
                        }
                        await onSaveUsername(candidate);
                        if (context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                      child: const Text('Save username'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Username updated.')));
    }
  }

  Future<void> _showAvatarSheet(BuildContext context) async {
    const choices = <String>['🙂', '😎', '🕵️', '🧠', '🦊', '🐼', '🐙', '🐧', '🐯', '🦄'];
    final theme = Theme.of(context);

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: choices
                .map(
                  (item) => InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.of(context).pop(item),
                    child: Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(item, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );

    if (selected == null || selected.isEmpty) {
      return;
    }
    await onSaveAvatar(selected);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated.')),
      );
    }
  }
}

class _ProgressInsights extends StatelessWidget {
  const _ProgressInsights({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reputationService = ReputationService();
    final challengeService = ChallengeService();

    return FutureBuilder(
      future: Future.wait<dynamic>([
        reputationService.getReputation(userId: userId),
        challengeService.getUserProgress(userId),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator(minHeight: 2);
        }

        final reputation = snapshot.data![0] as UserReputation;
        final progress = snapshot.data![1] as Map<String, int>;
        final xp = progress['xp'] ?? 0;
        final streak = progress['streak'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trust & Progress', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SmallBadge(label: 'Trust ${reputation.trustScore}'),
                  _SmallBadge(
                    label:
                        'Posts ${reputation.postsLast24h}/${reputation.dailyPostLimit} today',
                  ),
                  _SmallBadge(label: '$xp XP'),
                  _SmallBadge(label: '🔥 $streak streak'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}

class _CountryTravelInsights extends StatelessWidget {
  const _CountryTravelInsights({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final travelService = TravelService();

    return FutureBuilder<TravelSummary>(
      future: travelService.getSummary(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator(minHeight: 2);
        }

        final data = snapshot.data!;
        final progress = (data.exploredPercent / 100).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Country travel', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Estimated exploration in ${data.countryCode}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: progress,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SmallBadge(label: '${data.distanceKm.toStringAsFixed(1)} km travelled'),
                  _SmallBadge(label: '${data.visitedCells} zones visited'),
                  _SmallBadge(label: '${data.exploredPercent.toStringAsFixed(3)}% explored'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SubscriptionPanel extends StatelessWidget {
  const _SubscriptionPanel({
    required this.tier,
    required this.active,
    required this.expiresAt,
    required this.onPurchasePlan,
    required this.onDowngradeToBasic,
    required this.premiumCheckoutUrl,
    required this.businessCheckoutUrl,
  });

  final String tier;
  final bool active;
  final DateTime? expiresAt;
  final Future<void> Function(String planTier) onPurchasePlan;
  final Future<void> Function() onDowngradeToBasic;
  final String premiumCheckoutUrl;
  final String businessCheckoutUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String statusText;
    if (!active) {
      statusText = 'Inactive';
    } else if (tier == 'basic') {
      statusText = 'Basic plan active';
    } else if (expiresAt != null) {
      final month = expiresAt!.month.toString().padLeft(2, '0');
      final day = expiresAt!.day.toString().padLeft(2, '0');
      statusText = 'Renews on $month/$day';
    } else {
      statusText = 'Active';
    }

    Future<void> purchase(String nextTier) async {
      await onPurchasePlan(nextTier);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$nextTier plan activated.')),
        );
      }
    }

    Future<void> checkoutBusiness() async {
      if (businessCheckoutUrl.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business checkout is not configured.')),
        );
        return;
      }

      final uri = Uri.tryParse(businessCheckoutUrl);
      if (uri == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business checkout URL is invalid.')),
        );
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Activate Business plan?'),
            content: const Text(
              'After completing Stripe checkout, tap confirm to activate the Business package in-app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Not yet'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('I completed payment'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        await purchase('business');
      }
    }

    Future<void> checkoutPremium() async {
      if (premiumCheckoutUrl.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium checkout is not configured.')),
        );
        return;
      }

      final uri = Uri.tryParse(premiumCheckoutUrl);
      if (uri == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium checkout URL is invalid.')),
        );
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Activate Premium plan?'),
            content: const Text(
              'After completing Stripe checkout, tap confirm to activate Premium in-app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Not yet'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('I completed payment'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        await purchase('premium');
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Plans & Subscription', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Current: ${tier.toUpperCase()} · $statusText',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 12),
          _PlanTile(
            title: 'Basic',
            priceLabel: '£0 / month',
            isCurrent: tier == 'basic',
            features: const [
              'Daily bubble limit applies',
              'Standard gossip bubbles',
              'Core reactions and reporting',
            ],
            actionLabel: 'Use Basic',
            onTap: tier == 'basic'
                ? null
                : () async {
                    await onDowngradeToBasic();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Switched to Basic.')),
                      );
                    }
                  },
          ),
          const SizedBox(height: 10),
          _PlanTile(
            title: 'Premium',
            priceLabel: '£10 / month',
            isCurrent: tier == 'premium',
            features: const [
              'Higher daily bubble cap',
              'Longer bubble expiry options',
              'Richer posting privileges',
            ],
            actionLabel: 'Upgrade to Premium',
            onTap: tier == 'premium' ? null : checkoutPremium,
          ),
          const SizedBox(height: 10),
          _PlanTile(
            title: 'Business',
            priceLabel: '£125 / month',
            isCurrent: tier == 'business',
            features: const [
              'Post business offer bubbles',
              'Offer headline + boosted placement',
              'Highest daily posting allowance',
            ],
            actionLabel: 'Upgrade to Business',
            onTap: tier == 'business' ? null : checkoutBusiness,
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.title,
    required this.priceLabel,
    required this.features,
    required this.actionLabel,
    required this.isCurrent,
    required this.onTap,
  });

  final String title;
  final String priceLabel;
  final List<String> features;
  final String actionLabel;
  final bool isCurrent;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent
            ? theme.colorScheme.primary.withOpacity(0.16)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? theme.colorScheme.primary.withOpacity(0.55)
              : Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const Spacer(),
              Text(
                priceLabel,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $feature', style: theme.textTheme.bodySmall),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap == null
                  ? null
                  : () async {
                      await onTap!();
                    },
              child: Text(isCurrent ? 'Current plan' : actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.displayHandle,
    required this.avatar,
    required this.bubbles,
    required this.hits,
    required this.downvotes,
    required this.onEditUsername,
    required this.onEditAvatar,
    required this.isAnonymous,
    required this.onUpgradeAccount,
  });

  final String displayHandle;
  final String avatar;
  final int bubbles;
  final int hits;
  final int downvotes;
  final VoidCallback onEditUsername;
  final VoidCallback onEditAvatar;
  final bool isAnonymous;
  final Future<void> Function() onUpgradeAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.28),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                child: Text(avatar, style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayHandle, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(
                      'Anonymous only. Handle-based identity, no real names.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Bubbles',
                  value: bubbles.toString(),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Hits',
                  value: hits.toString(),
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Downvotes',
                  value: downvotes.toString(),
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onEditUsername,
            icon: const Icon(Icons.alternate_email),
            label: const Text('Edit username'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onEditAvatar,
            icon: const Icon(Icons.face_retouching_natural),
            label: const Text('Edit avatar'),
          ),
          if (isAnonymous) ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                await onUpgradeAccount();
              },
              icon: const Icon(Icons.lock_open_outlined),
              label: const Text('Add email & password'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

class _BubbleTile extends StatelessWidget {
  const _BubbleTile({required this.bubble});

  final GossipBubble bubble;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatDate(bubble.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
              Icon(
                Icons.thumb_up_alt_outlined,
                size: 16,
                color: Colors.greenAccent.shade100,
              ),
              const SizedBox(width: 4),
              Text('${bubble.hits}', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              bubble.message,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.thumb_down_alt_outlined,
                size: 16,
                color: Colors.redAccent.shade100,
              ),
              const SizedBox(width: 4),
              Text('${bubble.downvotes}', style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day';
  }
}
