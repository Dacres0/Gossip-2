import 'package:flutter/material.dart';
import 'package:gossip_app/models/gossip_bubble.dart';

class BubbleCard extends StatelessWidget {
  const BubbleCard({
    super.key,
    required this.bubble,
    required this.distanceMeters,
    this.onHit,
    this.onDownvote,
    this.onReport,
    this.isOwnBubble = false,
  });

  final GossipBubble bubble;
  final double distanceMeters;
  final VoidCallback? onHit;
  final VoidCallback? onDownvote;
  final VoidCallback? onReport;
  final bool isOwnBubble;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distanceText = distanceMeters >= 1000
        ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
        : '${distanceMeters.toStringAsFixed(0)} m';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(bubble.authorLabel, style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  distanceText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              bubble.message,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.3),
            ),
            if (bubble.isBusinessOffer) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: Text(
                  bubble.offerHeadline == null || bubble.offerHeadline!.isEmpty
                      ? 'Business offer'
                      : 'Offer: ${bubble.offerHeadline}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade200,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Expires ${_formatExpiry(bubble)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Credibility ${bubble.credibilityScore.toStringAsFixed(1)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (bubble.reportCount > 0) ...[
                  const SizedBox(width: 10),
                  Icon(
                    Icons.flag_outlined,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${bubble.reportCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ReactionChip(
                  icon: Icons.thumb_up_alt_rounded,
                  label: bubble.hits.toString(),
                  color: Colors.greenAccent,
                  onTap: isOwnBubble ? null : onHit,
                ),
                const SizedBox(width: 10),
                _ReactionChip(
                  icon: Icons.thumb_down_alt_rounded,
                  label: bubble.downvotes.toString(),
                  color: Colors.redAccent,
                  onTap: isOwnBubble ? null : onDownvote,
                ),
                const Spacer(),
                if (!isOwnBubble)
                  IconButton(
                    onPressed: onReport,
                    icon: const Icon(Icons.flag_outlined),
                    color: theme.colorScheme.error,
                    tooltip: 'Report bubble',
                  ),
                if (isOwnBubble)
                  Text(
                    'Your bubble',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatExpiry(GossipBubble bubble) {
    final remaining = bubble.expiresAt.difference(DateTime.now());
    if (remaining.inMinutes <= 0) {
      return 'now';
    }
    if (remaining.inHours < 1) {
      return 'in ${remaining.inMinutes} min';
    }
    if (remaining.inHours < 24) {
      return 'in ${remaining.inHours} hr';
    }
    final days = remaining.inDays;
    return 'in ${days} day${days == 1 ? '' : 's'}';
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
