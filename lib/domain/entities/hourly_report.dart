class HourlyReport {
  final int id;
  final double actualDurationHours;
  final int actualCleanerCount;
  final double finalTotalPrice;
  final String? notes;
  final String? submittedByName;
  final DateTime? createdAt;

  const HourlyReport({
    required this.id,
    required this.actualDurationHours,
    required this.actualCleanerCount,
    required this.finalTotalPrice,
    this.notes,
    this.submittedByName,
    this.createdAt,
  });
}
