class TravelSummary {
  const TravelSummary({
    required this.countryCode,
    required this.distanceKm,
    required this.visitedCells,
    required this.exploredPercent,
  });

  final String countryCode;
  final double distanceKm;
  final int visitedCells;
  final double exploredPercent;
}
