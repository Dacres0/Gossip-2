import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gossip_app/models/gossip_bubble.dart';
import 'package:gossip_app/models/nearby_player.dart';
import 'package:gossip_app/screens/challenges_screen.dart';
import 'package:gossip_app/screens/notifications_screen.dart';
import 'package:gossip_app/screens/profile_screen.dart';
import 'package:gossip_app/services/auth_service.dart';
import 'package:gossip_app/services/bubble_service.dart';
import 'package:gossip_app/services/location_service.dart';
import 'package:gossip_app/services/moderation_service.dart';
import 'package:gossip_app/services/notification_service.dart';
import 'package:gossip_app/services/presence_service.dart';
import 'package:gossip_app/services/travel_service.dart';
import 'package:gossip_app/widgets/bubble_card.dart';
import 'package:gossip_app/widgets/mapbox_web_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _authService = AuthService();
  final _bubbleService = BubbleService();
  final _locationService = LocationService();
  final _moderationService = ModerationService();
  final _notificationService = NotificationService();
  final _presenceService = PresenceService();
  final _travelService = TravelService();
  final _pageController = PageController(initialPage: 1);
  final _mapViewportRevision = ValueNotifier<int>(0);
  final _recentBubblesNotifier = ValueNotifier<List<GossipBubble>>(<GossipBubble>[]);
  final _nearbyPlayersNotifier = ValueNotifier<List<NearbyPlayer>>(<NearbyPlayer>[]);
  List<NearbyPlayer> _activePlayers = const <NearbyPlayer>[];
  StreamSubscription<List<GossipBubble>>? _bubbleSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription<List<NearbyPlayer>>? _presenceSubscription;

  LatLng _mapCenter = const LatLng(51.5072, -0.1276);
  LatLng? _challengeAnchor;
  LatLng? _userLocation;
  String _anonId = '#----';
  String? _username;
  String _avatar = '🙂';
  String _authorKey = 'anon';
  String _subscriptionTier = AuthService.planBasic;
  bool _subscriptionActive = true;
  DateTime? _subscriptionExpiresAt;
  bool _loadingLocation = true;
  bool _mapInteractionEnabled = false;
  bool _followUser = true;
  String? _errorMessage;
  int _currentPage = 1;
  double _mapZoom = 14;

  String get _displayHandle =>
      _username == null || _username!.isEmpty ? _anonId : '@${_username!}';

  @override
  void initState() {
    super.initState();
    _listenToBubbles();
    _initialize();
  }

  @override
  void dispose() {
    _bubbleSubscription?.cancel();
    _positionSubscription?.cancel();
    _presenceSubscription?.cancel();
    _pageController.dispose();
    _mapViewportRevision.dispose();
    _recentBubblesNotifier.dispose();
    _nearbyPlayersNotifier.dispose();
    super.dispose();
  }

  void _listenToBubbles() {
    _bubbleSubscription?.cancel();
    _bubbleSubscription = _bubbleService.streamRecentBubbles().listen(
      (bubbles) {
        if (!mounted) return;
        _recentBubblesNotifier.value = _rankAndFilterBubbles(
          bubbles.where((bubble) => !bubble.isExpired),
        );
      },
      onError: (_) {
        if (!mounted) return;
      },
    );
  }

  Future<void> _initialize() async {
    try {
      _anonId = await _authService.getDisplayId();
      _username = await _authService.getUsername();
      _avatar = await _authService.getAvatar();
      _authorKey = FirebaseAuth.instance.currentUser?.uid ?? _anonId;
      await _authService.ensureDefaultPlanAssigned();
      await _loadSubscriptionStatus();

      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        _userLocation = LatLng(position.latitude, position.longitude);
        _mapCenter = _userLocation!;
        await _presenceService.updatePresence(
          userId: _authorKey,
          displayHandle: _displayHandle,
          avatar: _avatar,
          location: _userLocation!,
        );
        await _travelService.recordPosition(
          userId: _authorKey,
          location: _userLocation!,
        );
      }
      _challengeAnchor = _mapCenter;
      _startLiveLocation();
      _listenNearbyPlayers();
    } catch (_) {
      _errorMessage = 'Unable to initialize services.';
      _challengeAnchor ??= _mapCenter;
    }

    if (mounted) {
      setState(() {
        _loadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: _mapInteractionEnabled
          ? const NeverScrollableScrollPhysics()
          : const PageScrollPhysics(),
      onPageChanged: (page) {
        if (!mounted) return;
        setState(() {
          _currentPage = page;
          if (_currentPage != 1) {
            _mapInteractionEnabled = false;
          }
        });
      },
      children: [
        ChallengesScreen(
          anchor: _challengeAnchor ?? _mapCenter,
          currentCenter: _userLocation ?? _mapCenter,
          displayHandle: _displayHandle,
          userId: _authorKey,
          onOpenMap: () => _animateToPage(1),
        ),
        _buildMapPage(context),
        ProfileScreen(
          authorKey: _authorKey,
          displayHandle: _displayHandle,
          username: _username,
          bubbleStream: _bubbleService.streamRecentBubbles(),
          onSaveUsername: _saveUsername,
          avatar: _avatar,
          onSaveAvatar: _saveAvatar,
          onSignOut: _authService.signOut,
          isAnonymous: FirebaseAuth.instance.currentUser?.isAnonymous ?? true,
          onUpgradeAccount: _showUpgradeAccount,
          subscriptionTier: _subscriptionTier,
          subscriptionActive: _subscriptionActive,
          subscriptionExpiresAt: _subscriptionExpiresAt,
          onPurchasePlan: _purchasePlan,
          onDowngradeToBasic: _downgradeToBasic,
          premiumCheckoutUrl: AuthService.premiumCheckoutUrl,
          businessCheckoutUrl: AuthService.businessCheckoutUrl,
        ),
      ],
    );
  }

  Widget _buildMapPage(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildCartoonMap(),
          ),
          _buildTopBar(theme),
          _buildMapInteractionToggle(theme),
          _buildCenterPin(theme),
          _buildMapGradientOverlay(),
          _buildBottomTabDock(theme),
          _buildBottomPanel(theme),
          if (_loadingLocation) const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 140,
              child: _ErrorBanner(message: _errorMessage!),
            ),
        ],
      ),
    );
  }

  Widget _buildCartoonMap() {
    return Stack(
      fit: StackFit.expand,
      children: [
        MapboxWebMap(
          center: _mapCenter,
          zoom: _mapZoom,
          bubbles: _recentBubblesNotifier.value,
          interactionEnabled: _mapInteractionEnabled,
          onCameraChanged: (state) {
            if (!_mapInteractionEnabled) {
              return;
            }
            if (!mounted) return;
            setState(() {
              _mapCenter = state.center;
              _mapZoom = state.zoom;
              _followUser = false;
            });
            _mapViewportRevision.value++;
          },
          onBubbleAction: _handleMapBubbleAction,
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0x22FFF59D),
                  const Color(0x11FFFFFF),
                  const Color(0x22B2FF59),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapInteractionToggle(ThemeData theme) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 78),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: _mapInteractionEnabled
                  ? theme.colorScheme.primary.withOpacity(0.92)
                  : theme.colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                setState(() {
                  _mapInteractionEnabled = !_mapInteractionEnabled;
                  if (_mapInteractionEnabled) {
                    _followUser = false;
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _mapInteractionEnabled
                          ? Icons.pan_tool_alt_rounded
                          : Icons.swipe_rounded,
                      size: 18,
                      color:
                          _mapInteractionEnabled ? Colors.white : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _mapInteractionEnabled
                          ? 'Free map mode (challenges use GPS only)'
                          : 'Enable free map mode',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color:
                            _mapInteractionEnabled ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleMapBubbleAction(MapBubbleAction action) {
    GossipBubble? bubble;
    for (final candidate in _recentBubblesNotifier.value) {
      if (candidate.id == action.bubbleId) {
        bubble = candidate;
        break;
      }
    }

    if (bubble == null) {
      _showSnack('That bubble is no longer available.');
      return;
    }

    switch (action.action) {
      case BubbleActionType.hit:
        _castVote(bubble, isHit: true);
        break;
      case BubbleActionType.downvote:
        _castVote(bubble, isHit: false);
        break;
      case BubbleActionType.report:
        _showReportBubbleSheet(bubble);
        break;
    }
  }

  Widget _buildCenterPin(ThemeData theme) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.55)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_location_alt_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return SafeArea(
      child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xCC151515),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.map_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nearby',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _displayHandle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _subscriptionTier.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _showUpgradeAccount,
                icon: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 20),
                tooltip: 'Upgrade account',
              ),
              IconButton(
                onPressed: _recenterOnUser,
                icon: Icon(
                  _followUser ? Icons.my_location : Icons.location_searching,
                  color: Colors.white,
                  size: 20,
                ),
                tooltip: 'Follow my location',
              ),
              IconButton(
                onPressed: _openNotifications,
                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                tooltip: 'Notifications',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapGradientOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.12),
                Colors.transparent,
                Colors.black.withOpacity(0.08),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomTabDock(ThemeData theme) {
    return Positioned(
      left: 18,
      right: 18,
      bottom: 228,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.94),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _PageDockButton(
                label: 'Challenges',
                icon: Icons.emoji_events_outlined,
                selected: _currentPage == 0,
                onTap: () => _animateToPage(0),
              ),
            ),
            Expanded(
              child: _PageDockButton(
                label: 'Map',
                icon: Icons.map_outlined,
                selected: _currentPage == 1,
                onTap: () => _animateToPage(1),
              ),
            ),
            Expanded(
              child: _PageDockButton(
                label: 'Profile',
                icon: Icons.person_outline,
                selected: _currentPage == 2,
                onTap: () => _animateToPage(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(ThemeData theme) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, -12),
            ),
          ],
        ),
        child: SizedBox(
          height: 218,
          child: ValueListenableBuilder<int>(
            valueListenable: _mapViewportRevision,
            builder: (context, _, __) => ValueListenableBuilder<List<GossipBubble>>(
              valueListenable: _recentBubblesNotifier,
              builder: (context, recentBubbles, _) {
                final nearby = recentBubbles
                    .map(
                      (bubble) => _BubbleDistance(
                        bubble,
                        _locationService.distanceInMeters(
                          lat1: (_userLocation ?? _mapCenter).latitude,
                          lng1: (_userLocation ?? _mapCenter).longitude,
                          lat2: bubble.lat,
                          lng2: bubble.lng,
                        ),
                      ),
                    )
                    .where((item) => item.distanceMeters <= 3000)
                    .toList()
                  ..sort((a, b) {
                    final credibility =
                        _rankingScore(b.bubble).compareTo(_rankingScore(a.bubble));
                    if (credibility != 0) {
                      return credibility;
                    }
                    return a.distanceMeters.compareTo(b.distanceMeters);
                  });

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${nearby.length} nearby bubbles · ▲ upvote  ▼ downvote',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _showCreateBubble,
                            icon: const Icon(Icons.add_comment_outlined, size: 18),
                            label: Text(
                              _subscriptionTier == AuthService.planBusiness
                                  ? 'Post offer'
                                  : 'Drop bubble',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: nearby.isEmpty
                          ? Center(
                              child: Text(
                                'No gossip nearby. Drop the first bubble!',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: nearby.length,
                              itemBuilder: (context, index) {
                                final item = nearby[index];
                                final isOwnBubble = item.bubble.authorId == _authorKey;
                                return BubbleCard(
                                  bubble: item.bubble,
                                  distanceMeters: item.distanceMeters,
                                  isOwnBubble: isOwnBubble,
                                  onHit: () => _castVote(item.bubble, isHit: true),
                                  onDownvote: () => _castVote(item.bubble, isHit: false),
                                  onReport: isOwnBubble
                                      ? null
                                      : () => _showReportBubbleSheet(item.bubble),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveUsername(String username) async {
    await _authService.saveUsername(username);
    if (_userLocation != null) {
      await _presenceService.updatePresence(
        userId: _authorKey,
        displayHandle: _displayHandle,
        avatar: _avatar,
        location: _userLocation!,
      );
    }
    if (!mounted) return;
    setState(() {
      _username = username;
    });
  }

  Future<void> _saveAvatar(String avatar) async {
    await _authService.saveAvatar(avatar);
    if (!mounted) return;
    setState(() {
      _avatar = avatar;
    });
    if (_userLocation != null) {
      await _presenceService.updatePresence(
        userId: _authorKey,
        displayHandle: _displayHandle,
        avatar: _avatar,
        location: _userLocation!,
      );
    }
  }

  Future<void> _castVote(GossipBubble bubble, {required bool isHit}) async {
    if (bubble.authorId == _authorKey) {
      _showSnack('You cannot react to your own bubble.');
      return;
    }

    try {
      await _bubbleService.voteOnBubble(
        bubbleId: bubble.id,
        isHit: isHit,
        voterId: _authorKey,
      );
      if (bubble.authorId != _authorKey) {
        await _notificationService.sendVoteNotification(
          recipientUserId: bubble.authorId,
          actorHandle: _displayHandle,
          isHit: isHit,
          bubbleId: bubble.id,
        );
      }
      _showSnack(isHit ? 'Bubble hit recorded.' : 'Downvote recorded.');
    } on DuplicateVoteException {
      _showSnack('You already reacted to this bubble.');
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message ?? 'Unable to react right now.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to react right now.';
      });
    }
  }

  Future<void> _showReportBubbleSheet(GossipBubble bubble) async {
    final detailsController = TextEditingController();
    const reasons = <String>[
      'harassment',
      'hate_speech',
      'spam',
      'misinformation',
      'explicit_content',
      'other',
    ];
    var selectedReason = reasons.first;

    final shouldReport = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Report bubble', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Help keep the map safe by reporting inappropriate gossip.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: reasons.map((reason) {
                      return ChoiceChip(
                        selected: selectedReason == reason,
                        label: Text(reason.replaceAll('_', ' ')),
                        onSelected: (_) {
                          setModalState(() {
                            selectedReason = reason;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailsController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      hintText: 'Optional details',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Submit report'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (shouldReport != true) {
      return;
    }

    await _reportBubble(
      bubble,
      reason: selectedReason,
      details: detailsController.text.trim().isEmpty
          ? null
          : detailsController.text.trim(),
    );
  }

  Future<void> _reportBubble(
    GossipBubble bubble, {
    required String reason,
    String? details,
  }) async {
    if (bubble.authorId == _authorKey) {
      _showSnack('You cannot report your own bubble.');
      return;
    }

    try {
      await _bubbleService.reportBubble(
        bubbleId: bubble.id,
        reporterId: _authorKey,
        reason: reason,
        details: details,
      );
      _showSnack('Report submitted. Thank you.');
    } on DuplicateReportException {
      _showSnack('You already reported this bubble.');
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message ?? 'Unable to submit report right now.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to submit report right now.';
      });
    }
  }

  Future<void> _showCreateBubble() async {
    final controller = TextEditingController();
    final isPremium = _subscriptionTier == AuthService.planPremium;
    final isBusiness = _subscriptionTier == AuthService.planBusiness;
    final durations = <Duration>[
      const Duration(hours: 1),
      const Duration(hours: 6),
      const Duration(hours: 24),
      if (isPremium || isBusiness) const Duration(hours: 48),
      if (isBusiness) const Duration(hours: 72),
    ];
    var selected = durations.first;
    var postAsBusinessOffer = isBusiness;
    final offerController = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Drop a gossip bubble', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      hintText: 'Whisper something happening nearby...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isBusiness) ...[
                    SwitchListTile.adaptive(
                      value: postAsBusinessOffer,
                      onChanged: (value) {
                        setModalState(() {
                          postAsBusinessOffer = value;
                        });
                      },
                      title: const Text('Post as business offer'),
                      subtitle: const Text('Promote today\'s deal to nearby users.'),
                    ),
                    if (postAsBusinessOffer) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: offerController,
                        maxLength: 60,
                        decoration: const InputDecoration(
                          hintText: 'Offer headline (e.g. 2 for 1 today)',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                  Text('Expires in', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: durations.map((duration) {
                      final selectedChip = selected == duration;
                      return ChoiceChip(
                        selected: selectedChip,
                        label: Text(_formatDuration(duration)),
                        onSelected: (_) {
                          setModalState(() {
                            selected = duration;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: const Text('Release bubble'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      final message = controller.text.trim();
      if (message.isEmpty) {
        _showSnack('Add a message before sending.');
        return;
      }

      final bubbleType = postAsBusinessOffer ? 'business_offer' : 'standard';
      final offerHeadline = offerController.text.trim();
      if (postAsBusinessOffer && offerHeadline.isEmpty) {
        _showSnack('Add an offer headline for business bubbles.');
        return;
      }

      final maxLength = isPremium || isBusiness ? 260 : 180;
      if (message.length > maxLength) {
        _showSnack('Message too long for your plan (max $maxLength chars).');
        return;
      }

      if (postAsBusinessOffer && !isBusiness) {
        _showSnack('Business offers are available on the Business plan only.');
        return;
      }

      ModerationResult moderation;
      try {
        moderation = await _moderationService.validateNewBubble(
          authorId: _authorKey,
          message: message,
          subscriptionTier: _subscriptionTier,
          bubbleType: bubbleType,
        );
      } on FirebaseException catch (error) {
        _showSnack(error.message ?? 'Moderation check failed. Please try again.');
        return;
      } catch (_) {
        _showSnack('Moderation check failed. Please try again.');
        return;
      }

      if (!moderation.allowed) {
        _showSnack(moderation.userMessage);
        return;
      }

      final bubble = GossipBubble(
        id: '',
        message: message,
        lat: (_userLocation ?? _mapCenter).latitude,
        lng: (_userLocation ?? _mapCenter).longitude,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(selected),
        authorId: _authorKey,
        authorLabel: _displayHandle,
        hits: 0,
        downvotes: 0,
        bubbleType: bubbleType,
        offerHeadline: offerHeadline.isEmpty ? null : offerHeadline,
        isBoosted: postAsBusinessOffer,
        moderationFlags: moderation.flags,
      );

      try {
        await _bubbleService.addBubble(bubble);
        _showSnack('Bubble released nearby.');
      } on FirebaseException catch (error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = error.message ?? 'Unable to post bubble.';
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Unable to post bubble.';
        });
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showUpgradeAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('You are not signed in.');
      return;
    }
    if (!user.isAnonymous) {
      _showSnack('Account already upgraded.');
      return;
    }

    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String? errorMessage;
    var isLoading = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upgrade account', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Link an email and password to keep your anonymous profile.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
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
                      onPressed: isLoading
                          ? null
                          : () async {
                              final email = emailController.text.trim();
                              final password = passwordController.text.trim();
                              if (email.isEmpty || password.isEmpty) {
                                setModalState(() {
                                  errorMessage = 'Enter email and password.';
                                });
                                return;
                              }
                              setModalState(() {
                                isLoading = true;
                                errorMessage = null;
                              });
                              try {
                                await _authService.linkWithEmail(
                                  email: email,
                                  password: password,
                                );
                                if (context.mounted) {
                                  Navigator.of(context).pop(true);
                                }
                              } on FirebaseAuthException catch (error) {
                                setModalState(() {
                                  errorMessage = error.message ?? 'Upgrade failed.';
                                });
                              } finally {
                                if (context.mounted) {
                                  setModalState(() {
                                    isLoading = false;
                                  });
                                }
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Upgrade account'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      _showSnack('Account upgraded successfully.');
    }
  }

  Future<void> _loadSubscriptionStatus() async {
    final status = await _authService.getPremiumStatus();
    if (!mounted) return;
    setState(() {
      _subscriptionTier = status.tier;
      _subscriptionActive = status.isActive;
      _subscriptionExpiresAt = status.expiresAt;
    });
  }

  Future<void> _purchasePlan(String planTier) async {
    await _authService.purchasePremium(tier: planTier);
    await _loadSubscriptionStatus();
    if (planTier == AuthService.planPremium) {
      _showSnack('Premium activated: £10/month.');
      return;
    }
    if (planTier == AuthService.planBusiness) {
      _showSnack('Business activated: £125/month.');
      return;
    }
    _showSnack('Plan updated.');
  }

  Future<void> _downgradeToBasic() async {
    await _authService.cancelPremium();
    await _loadSubscriptionStatus();
    _showSnack('Switched to Basic plan.');
  }

  Future<void> _animateToPage(int page) {
    return _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openNotifications() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(
          userId: _authorKey,
          notificationService: _notificationService,
        ),
      ),
    );
  }

  void _startLiveLocation() async {
    final granted = await _locationService.ensurePermission();
    if (!granted) {
      return;
    }

    _positionSubscription?.cancel();
    _positionSubscription = _locationService.watchPosition().listen((position) async {
      final next = LatLng(position.latitude, position.longitude);
      if (!mounted) return;

      setState(() {
        _userLocation = next;
        if (_followUser) {
          _mapCenter = next;
        }
      });
      _refreshNearbyPlayers();
      _mapViewportRevision.value++;

      await _presenceService.updatePresence(
        userId: _authorKey,
        displayHandle: _displayHandle,
        avatar: _avatar,
        location: next,
      );
      await _travelService.recordPosition(userId: _authorKey, location: next);
    });
  }

  void _listenNearbyPlayers() {
    _presenceSubscription?.cancel();
    _presenceSubscription = _presenceService
        .streamNearbyPlayers(
          selfUserId: _authorKey,
        )
        .listen((players) {
          if (!mounted) return;
          _activePlayers = players;
          _refreshNearbyPlayers();
        });
  }

  void _refreshNearbyPlayers() {
    final center = _userLocation ?? _mapCenter;
    final filtered = _activePlayers.where((player) {
      final distance = _locationService.distanceInMeters(
        lat1: center.latitude,
        lng1: center.longitude,
        lat2: player.lat,
        lng2: player.lng,
      );
      return distance <= 2000;
    }).toList();
    _nearbyPlayersNotifier.value = filtered;
  }

  void _recenterOnUser() {
    final location = _userLocation;
    if (location == null) {
      _showSnack('Live location unavailable.');
      return;
    }
    setState(() {
      _followUser = true;
      _mapInteractionEnabled = false;
      _mapCenter = location;
    });
    _mapViewportRevision.value++;
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours < 2) {
      return '1 hour';
    }
    if (duration.inHours < 24) {
      return '${duration.inHours} hours';
    }
    return '${duration.inDays} day';
  }

  List<GossipBubble> _rankAndFilterBubbles(Iterable<GossipBubble> bubbles) {
    final visible = bubbles.where((bubble) {
      if (bubble.shouldHideForModeration) {
        return false;
      }
      return bubble.credibilityScore > -6;
    }).toList();

    visible.sort((a, b) {
      final score = _rankingScore(b).compareTo(_rankingScore(a));
      if (score != 0) {
        return score;
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    return visible;
  }

  double _rankingScore(GossipBubble bubble) {
    final boost = bubble.isBoosted ? 3.0 : 0.0;
    return bubble.credibilityScore + boost;
  }
}

class _BubbleDistance {
  _BubbleDistance(this.bubble, this.distanceMeters);

  final GossipBubble bubble;
  final double distanceMeters;
}

class _PageDockButton extends StatelessWidget {
  const _PageDockButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? theme.colorScheme.primary.withOpacity(0.16)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.72),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.72),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}


