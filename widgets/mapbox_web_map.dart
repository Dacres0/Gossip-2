import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gossip_app/config/mapbox_config.dart';
import 'package:gossip_app/models/gossip_bubble.dart';
import 'package:latlong2/latlong.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class MapboxWebMap extends StatefulWidget {
  const MapboxWebMap({
    super.key,
    required this.center,
    required this.zoom,
    required this.bubbles,
    required this.interactionEnabled,
    required this.onCameraChanged,
    this.onBubbleAction,
  });

  final LatLng center;
  final double zoom;
  final List<GossipBubble> bubbles;
  final bool interactionEnabled;
  final ValueChanged<MapCameraState> onCameraChanged;
  final ValueChanged<MapBubbleAction>? onBubbleAction;

  @override
  State<MapboxWebMap> createState() => _MapboxWebMapState();
}

class _MapboxWebMapState extends State<MapboxWebMap> {
  late final WebViewController _controller;
  late final WebViewWidget _webViewWidget;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    final controllerParams = const PlatformWebViewControllerCreationParams();

    _controller =
        WebViewController.fromPlatformCreationParams(controllerParams)
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0xFFE4F1DA))
          ..addJavaScriptChannel(
            'MapReady',
            onMessageReceived: (_) {
              _mapReady = true;
              _syncInteractionState();
              _pushStateToMap();
            },
          )
          ..addJavaScriptChannel(
            'MapEvent',
            onMessageReceived: (message) {
              final data = jsonDecode(message.message) as Map<String, dynamic>;
              widget.onCameraChanged(
                MapCameraState(
                  center: LatLng(
                    (data['lat'] as num).toDouble(),
                    (data['lng'] as num).toDouble(),
                  ),
                  zoom: (data['zoom'] as num).toDouble(),
                ),
              );
            },
          )
          ..addJavaScriptChannel(
            'MapBubbleAction',
            onMessageReceived: (message) {
              final callback = widget.onBubbleAction;
              if (callback == null) {
                return;
              }

              final data = jsonDecode(message.message) as Map<String, dynamic>;
              final action = data['action'] as String?;
              final bubbleId = data['bubbleId'] as String?;

              if (action == null || bubbleId == null || bubbleId.isEmpty) {
                return;
              }

              final parsedAction = _bubbleActionFromWireValue(action);
              if (parsedAction == null) {
                return;
              }

              callback(
                MapBubbleAction(bubbleId: bubbleId, action: parsedAction),
              );
            },
          )
          ..loadHtmlString(_mapHtml);

    PlatformWebViewWidgetCreationParams widgetParams =
        PlatformWebViewWidgetCreationParams(controller: _controller.platform);

    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      widgetParams =
          AndroidWebViewWidgetCreationParams
              .fromPlatformWebViewWidgetCreationParams(
                widgetParams,
                displayWithHybridComposition: true,
              );
    }

    _webViewWidget =
        WebViewWidget.fromPlatformCreationParams(params: widgetParams);
  }

  @override
  void didUpdateWidget(covariant MapboxWebMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_mapReady) return;

    if (oldWidget.interactionEnabled != widget.interactionEnabled) {
      _syncInteractionState();
    }

    if (oldWidget.center != widget.center ||
        oldWidget.zoom != widget.zoom ||
        oldWidget.bubbles != widget.bubbles) {
      _pushStateToMap();
    }
  }

  Future<void> _syncInteractionState() {
    final enabled = widget.interactionEnabled ? 'true' : 'false';
    return _controller.runJavaScript('window.setInteractionEnabled($enabled);');
  }

  Future<void> _pushStateToMap() async {
    final visibleBubbles = widget.bubbles
        .where((bubble) => !bubble.shouldHideForModeration)
        .where((bubble) => bubble.credibilityScore > -6)
        .toList()
      ..sort((a, b) {
        final credibility = b.credibilityScore.compareTo(a.credibilityScore);
        if (credibility != 0) {
          return credibility;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

    final payload = jsonEncode({
      'center': {
        'lat': widget.center.latitude,
        'lng': widget.center.longitude,
      },
      'zoom': widget.zoom,
      'bubbles': visibleBubbles
          .map(
            (bubble) => {
              'id': bubble.id,
              'lat': bubble.lat,
              'lng': bubble.lng,
              'authorLabel': bubble.authorLabel,
              'message': bubble.message,
              'hits': bubble.hits,
              'downvotes': bubble.downvotes,
              'reportCount': bubble.reportCount,
              'credibilityScore': bubble.credibilityScore,
              'bubbleType': bubble.bubbleType,
              'offerHeadline': bubble.offerHeadline,
            },
          )
          .toList(),
    });

    await _controller.runJavaScript('window.updateMapState($payload);');
  }

  @override
  Widget build(BuildContext context) {
    return _webViewWidget;
  }
}

class MapCameraState {
  const MapCameraState({required this.center, required this.zoom});

  final LatLng center;
  final double zoom;
}

enum BubbleActionType { hit, downvote, report }

extension on BubbleActionType {
  String get wireValue {
    switch (this) {
      case BubbleActionType.hit:
        return 'hit';
      case BubbleActionType.downvote:
        return 'downvote';
      case BubbleActionType.report:
        return 'report';
    }
  }

}

BubbleActionType? _bubbleActionFromWireValue(String value) {
  for (final action in BubbleActionType.values) {
    if (action.wireValue == value) {
      return action;
    }
  }
  return null;
}

class MapBubbleAction {
  const MapBubbleAction({required this.bubbleId, required this.action});

  final String bubbleId;
  final BubbleActionType action;
}

const _mapHtml = '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <link
      rel="stylesheet"
      href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
      integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY="
      crossorigin=""
    />
    <style>
      html, body {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
        overflow: hidden;
        background: #e4f1da;
      }
      #map {
        width: 100%;
        height: 100%;
      }
      .bubble-marker {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 4px;
      }
      .bubble-label {
        background: #fff176;
        color: #262626;
        border-radius: 999px;
        border: 2px solid rgba(255,255,255,0.95);
        box-shadow: 0 6px 14px rgba(0,0,0,0.18);
        font: 800 11px/1.2 -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        padding: 6px 10px;
        white-space: nowrap;
      }
      .bubble-meta {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        margin-top: 2px;
        background: rgba(38,38,38,0.85);
        color: white;
        border-radius: 999px;
        padding: 3px 8px;
        font: 700 10px/1.1 -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      }
      .bubble-dot {
        width: 18px;
        height: 18px;
        border-radius: 50%;
        background: #ff7043;
        border: 3px solid white;
        box-sizing: border-box;
      }

      .bubble-popup {
        min-width: 200px;
        max-width: 240px;
        color: #202020;
        font: 500 12px/1.3 -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      }
      .bubble-popup-author {
        font-weight: 800;
        margin-bottom: 6px;
      }
      .bubble-popup-message {
        margin-bottom: 8px;
      }
      .bubble-popup-offer {
        margin-bottom: 8px;
        color: #8a4b00;
        font-weight: 800;
      }
      .bubble-popup-stats {
        margin-bottom: 8px;
        color: #424242;
        font-weight: 700;
      }
      .bubble-popup-actions {
        display: grid;
        grid-template-columns: 1fr 1fr 1fr;
        gap: 6px;
      }
      .bubble-popup-btn {
        border: 0;
        border-radius: 10px;
        padding: 6px;
        cursor: pointer;
        font: 700 11px/1 -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      }
      .bubble-popup-btn.hit {
        background: #c8e6c9;
      }
      .bubble-popup-btn.downvote {
        background: #ffcdd2;
      }
      .bubble-popup-btn.report {
        background: #ffe0b2;
      }
    </style>
  </head>
  <body>
    <div id="map"></div>
    <script
      src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
      integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo="
      crossorigin=""
    ></script>
    <script>
      const map = L.map('map', {
        zoomControl: false,
        attributionControl: false,
        preferCanvas: true,
        zoomAnimation: false,
        fadeAnimation: false,
        markerZoomAnimation: false,
      });

      const tileUrl = 'https://api.mapbox.com/styles/v1/${kMapboxStyleOwner}/${kMapboxStyleId}/tiles/256/{z}/{x}/{y}@2x?access_token=${kMapboxAccessToken}';
      const tiles = L.tileLayer(tileUrl, {
        tileSize: 256,
        zoomOffset: 0,
        minZoom: 1,
        maxZoom: 22,
        crossOrigin: true,
      }).addTo(map);

      map.setView([51.5072, -0.1276], 14, { animate: false });

      let bubbleMarkers = [];
      let applyingState = false;

      function postCamera() {
        if (applyingState) return;
        const center = map.getCenter();
        MapEvent.postMessage(JSON.stringify({
          lat: center.lat,
          lng: center.lng,
          zoom: map.getZoom(),
        }));
      }

      function clearMarkers() {
        for (const marker of bubbleMarkers) {
          marker.remove();
        }
        bubbleMarkers = [];
      }

      function buildBubbleMarker(label) {
        const wrapper = document.createElement('div');
        wrapper.className = 'bubble-marker';

        const labelNode = document.createElement('div');
        labelNode.className = 'bubble-label';
        labelNode.textContent = label;

        const metaNode = document.createElement('div');
        metaNode.className = 'bubble-meta';
        metaNode.textContent = 'Credibility';

        const dotNode = document.createElement('div');
        dotNode.className = 'bubble-dot';

        wrapper.appendChild(labelNode);
        wrapper.appendChild(metaNode);
        wrapper.appendChild(dotNode);
        return wrapper;
      }

      function safeText(value) {
        return String(value ?? '')
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&#39;');
      }

      function buildBubblePopup(bubble) {
        const credibility = Number(bubble.credibilityScore ?? 0).toFixed(1);
        const isBusinessOffer = bubble.bubbleType === 'business_offer';
        const offer = isBusinessOffer
          ? `<div class="bubble-popup-offer">🏪 \${safeText(bubble.offerHeadline ?? 'Business offer')}</div>`
          : '';
        return `
          <div class="bubble-popup" data-bubble-id="\${safeText(bubble.id)}">
            <div class="bubble-popup-author">\${safeText(bubble.authorLabel)}</div>
            <div class="bubble-popup-message">\${safeText(bubble.message)}</div>
            \${offer}
            <div class="bubble-popup-stats">C \${credibility} · ▲ \${bubble.hits ?? 0} · ▼ \${bubble.downvotes ?? 0} · ⚑ \${bubble.reportCount ?? 0}</div>
            <div class="bubble-popup-actions">
              <button class="bubble-popup-btn hit" data-action="hit">▲ Hit</button>
              <button class="bubble-popup-btn downvote" data-action="downvote">▼ Down</button>
              <button class="bubble-popup-btn report" data-action="report">⚑ Report</button>
            </div>
          </div>
        `;
      }

      function notifyBubbleAction(bubbleId, action) {
        MapBubbleAction.postMessage(JSON.stringify({ bubbleId, action }));
      }

      window.setInteractionEnabled = function(enabled) {
        const mode = !!enabled;
        const method = mode ? 'enable' : 'disable';

        if (map.dragging && map.dragging[method]) map.dragging[method]();
        if (map.touchZoom && map.touchZoom[method]) map.touchZoom[method]();
        if (map.doubleClickZoom && map.doubleClickZoom[method]) map.doubleClickZoom[method]();
        if (map.scrollWheelZoom && map.scrollWheelZoom[method]) map.scrollWheelZoom[method]();
        if (map.boxZoom && map.boxZoom[method]) map.boxZoom[method]();
        if (map.keyboard && map.keyboard[method]) map.keyboard[method]();
        if (map.tap && map.tap[method]) map.tap[method]();
      }

      window.updateMapState = function(payload) {
        applyingState = true;
        map.setView([payload.center.lat, payload.center.lng], payload.zoom, { animate: false });

        clearMarkers();
        for (const bubble of payload.bubbles) {
          const markerElement = buildBubbleMarker(bubble.authorLabel);
          const credibilityText = Number(bubble.credibilityScore ?? 0).toFixed(1);
          const meta = markerElement.querySelector('.bubble-meta');
          if (meta) {
            meta.textContent = 'C ' + credibilityText;
          }

          const marker = L.marker([bubble.lat, bubble.lng], {
            interactive: true,
            icon: L.divIcon({
              className: '',
              html: markerElement.outerHTML,
              iconSize: [0, 0],
            }),
          })
            .bindPopup(buildBubblePopup(bubble), { closeButton: false })
            .on('popupopen', (event) => {
              const root = event.popup.getElement();
              if (!root) return;

              const popup = root.querySelector('.bubble-popup');
              if (!popup) return;

              const bubbleId = popup.getAttribute('data-bubble-id');
              if (!bubbleId) return;

              popup.querySelectorAll('.bubble-popup-btn').forEach((button) => {
                button.addEventListener('click', (clickEvent) => {
                  clickEvent.preventDefault();
                  clickEvent.stopPropagation();
                  const action = button.getAttribute('data-action');
                  if (!action) return;
                  notifyBubbleAction(bubbleId, action);
                });
              });
            })
            .addTo(map);
          bubbleMarkers.push(marker);
        }

        applyingState = false;
      };

      tiles.on('load', () => {
        MapReady.postMessage('ready');
        if (window.pendingPayload) {
          window.updateMapState(window.pendingPayload);
          window.pendingPayload = null;
        }
      });

      map.on('moveend', postCamera);
      map.on('zoomend', postCamera);
    </script>
  </body>
</html>
''';