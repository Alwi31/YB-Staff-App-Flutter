class HourlyDetails {
  final int? serviceAreaId;
  final String? serviceAreaName;
  final double minHours;
  final double plannedDurationHours;
  final int plannedCleanerCount;
  final double hourlyRateSnapshot;
  final double estimatedTotal;

  const HourlyDetails({
    this.serviceAreaId,
    this.serviceAreaName,
    this.minHours = 1.0,
    this.plannedDurationHours = 1.0,
    this.plannedCleanerCount = 1,
    this.hourlyRateSnapshot = 0.0,
    this.estimatedTotal = 0.0,
  });
}
