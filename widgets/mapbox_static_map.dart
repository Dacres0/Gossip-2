import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gossip_app/config/mapbox_config.dart';
import 'package:gossip_app/models/gossip_bubble.dart';
import 'package:gossip_app/models/nearby_player.dart';
import 'package:latlong2/latlong.dart';

class MapboxStaticMap extends StatelessWidget {
  const MapboxStaticMap({
    super.key,
    required this.center,
    required this.zoom,
    required this.bubbles,
    required this.players,
    required this.myAvatar,
  });

  final LatLng center;
  final double zoom;
  final List<GossipBubble> bubbles;
  final List<NearbyPlayer> players;
  final String myAvatar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(240.0, 1280.0)
            : 720.0;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight.clamp(240.0, 1280.0)
            : 1280.0;

        final url = _buildStaticMapUrl(
          lng: center.longitude,
          lat: center.latitude,
          zoom: zoom,
          width: width.round(),
          height: height.round(),
        );

        return ColoredBox(
          color: const Color(0xFFE4F1DA),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                key: ValueKey<String>(url),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                frameBuilder: (context, child, frame, _) {
                  if (frame == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return child;
                },
                errorBuilder: (context, _, __) {
                  return const Center(
                    child: Text('Unable to load map tiles.'),
                  );
                },
              ),
              ..._buildBubbleMarkers(width, height),
              ..._buildPlayerMarkers(width, height),
              _buildSelfAvatarDot(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelfAvatarDot() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF4CAF50), width: 2.5),
          ),
          child: Text(myAvatar, style: const TextStyle(fontSize: 14)),
        ),
      ),
    );
  }

  List<Widget> _buildBubbleMarkers(double width, double height) {
    final centerPoint = _projectWebMercator(center.latitude, center.longitude, zoom);

    return bubbles.map((bubble) {
      final bubblePoint = _projectWebMercator(bubble.lat, bubble.lng, zoom);
      final dx = (bubblePoint.dx - centerPoint.dx) + (width / 2);
      final dy = (bubblePoint.dy - centerPoint.dy) + (height / 2);

      if (dx < -40 || dy < -40 || dx > width + 40 || dy > height + 40) {
        return const SizedBox.shrink();
      }

      return Positioned(
        left: dx - 36,
        top: dy - 42,
        child: IgnorePointer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF176),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  bubble.authorLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2A2A2A),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7043),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildPlayerMarkers(double width, double height) {
    final centerPoint = _projectWebMercator(center.latitude, center.longitude, zoom);

    return players.map((player) {
      final p = _projectWebMercator(player.lat, player.lng, zoom);
      final dx = (p.dx - centerPoint.dx) + (width / 2);
      final dy = (p.dy - centerPoint.dy) + (height / 2);

      if (dx < -30 || dy < -30 || dx > width + 30 || dy > height + 30) {
        return const SizedBox.shrink();
      }

      return Positioned(
        left: dx - 24,
        top: dy - 38,
        child: IgnorePointer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                player.displayHandle,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF42A5F5), width: 2),
                ),
                child: Text(player.avatar, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Offset _projectWebMercator(double lat, double lng, double zoom) {
    final tileSize = 256.0;
    final scale = tileSize * (1 << zoom.floor()) * math.pow(2.0, zoom - zoom.floor());
    final x = (lng + 180.0) / 360.0 * scale;

    final latRad = lat * math.pi / 180.0;
    final mercatorY = (1 - (math.log(math.tan(latRad) + (1 / math.cos(latRad))) / math.pi)) / 2;
    final y = mercatorY * scale;

    return Offset(x, y);
  }

  String _buildStaticMapUrl({
    required double lng,
    required double lat,
    required double zoom,
    required int width,
    required int height,
  }) {
    final boundedZoom = zoom.clamp(3.0, 18.0);
    final boundedLat = lat.clamp(-85.0, 85.0);
    final boundedLng = lng.clamp(-180.0, 180.0);

    return 'https://api.mapbox.com/styles/v1/$kMapboxStyleOwner/$kMapboxStyleId/static/'
        '${boundedLng.toStringAsFixed(5)},${boundedLat.toStringAsFixed(5)},${boundedZoom.toStringAsFixed(2)},0/'
        '${width}x$height'
        '?access_token=$kMapboxAccessToken&logo=false&attribution=false';
  }
}
