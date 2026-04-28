import 'dart:math' as math;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gossip_app/models/travel_summary.dart';
import 'package:latlong2/latlong.dart';

class TravelService {
  TravelService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const double _estimatedCellAreaKm2 = 1.2;

  Future<void> recordPosition({
    required String userId,
    required LatLng location,
  }) async {
    final profileRef = _firestore.collection('profiles').doc(userId);
    final cellId = _cellId(location.latitude, location.longitude);
    final cellRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('travelCells')
        .doc(cellId);

    await _firestore.runTransaction((transaction) async {
      final profileSnap = await transaction.get(profileRef);
      final profile = profileSnap.data() ?? <String, dynamic>{};

      final prevLat = (profile['lastTravelLat'] as num?)?.toDouble();
      final prevLng = (profile['lastTravelLng'] as num?)?.toDouble();
      var addDistanceKm = 0.0;

      if (prevLat != null && prevLng != null) {
        final meters = _distanceMeters(
          lat1: prevLat,
          lng1: prevLng,
          lat2: location.latitude,
          lng2: location.longitude,
        );
        if (meters >= 15 && meters <= 5000) {
          addDistanceKm = meters / 1000.0;
        }
      }

      final existingCell = await transaction.get(cellRef);
      final isNewCell = !existingCell.exists;

      final currentDistance = (profile['travelDistanceKm'] as num?)?.toDouble() ?? 0;
      final currentVisitedCells = (profile['visitedCellCount'] as num?)?.toInt() ?? 0;
      final countryCode =
          (profile['countryCode'] as String?) ??
          (PlatformDispatcher.instance.locale.countryCode ?? 'US').toUpperCase();

      transaction.set(profileRef, {
        'countryCode': countryCode,
        'travelDistanceKm': currentDistance + addDistanceKm,
        'visitedCellCount': isNewCell ? currentVisitedCells + 1 : currentVisitedCells,
        'lastTravelLat': location.latitude,
        'lastTravelLng': location.longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(cellRef, {
        'lat': location.latitude,
        'lng': location.longitude,
        'visitedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<TravelSummary> getSummary(String userId) async {
    final profileRef = _firestore.collection('profiles').doc(userId);
    final profileSnap = await profileRef.get();
    final profile = profileSnap.data() ?? <String, dynamic>{};

    final countryCode =
        ((profile['countryCode'] as String?) ??
                (PlatformDispatcher.instance.locale.countryCode ?? 'US'))
            .toUpperCase();

    var visitedCells = (profile['visitedCellCount'] as num?)?.toInt() ?? 0;
    final distanceKm = (profile['travelDistanceKm'] as num?)?.toDouble() ?? 0;

    if (visitedCells == 0) {
      final cells = await _firestore
          .collection('users')
          .doc(userId)
          .collection('travelCells')
          .count()
          .get();
      visitedCells = cells.count ?? 0;
      await profileRef.set({'visitedCellCount': visitedCells}, SetOptions(merge: true));
    }

    final countryArea = _countryAreaKm2(countryCode);
    final exploredPercent = ((visitedCells * _estimatedCellAreaKm2) / countryArea) * 100;

    return TravelSummary(
      countryCode: countryCode,
      distanceKm: distanceKm,
      visitedCells: visitedCells,
      exploredPercent: exploredPercent.clamp(0, 100),
    );
  }

  String _cellId(double lat, double lng) {
    final qLat = (lat * 100).floor() / 100.0;
    final qLng = (lng * 100).floor() / 100.0;
    return '${qLat.toStringAsFixed(2)}_${qLng.toStringAsFixed(2)}';
  }

  double _distanceMeters({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  double _countryAreaKm2(String code) {
    const map = <String, double>{
      'US': 9833520,
      'GB': 243610,
      'UK': 243610,
      'CA': 9984670,
      'AU': 7692024,
      'DE': 357588,
      'FR': 551695,
      'IT': 301340,
      'ES': 505990,
      'NL': 41543,
      'IN': 3287263,
      'BR': 8515767,
      'JP': 377975,
      'MX': 1964375,
      'ZA': 1221037,
    };
    return map[code] ?? 500000;
  }
}
