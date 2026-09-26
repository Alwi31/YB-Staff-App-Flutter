import 'package:yb_staff_app/domain/entities/hourly_details.dart';

class HourlyDetailsModel extends HourlyDetails {
  const HourlyDetailsModel({
    super.serviceAreaId,
    super.serviceAreaName,
    super.minHours,
    super.plannedDurationHours,
    super.plannedCleanerCount,
    super.hourlyRateSnapshot,
    super.estimatedTotal,
  });

  factory HourlyDetailsModel.fromJson(Map<String, dynamic> json) {
    return HourlyDetailsModel(
      serviceAreaId: json['service_area_id'] as int?,
      serviceAreaName: json['service_area_name'] as String?,
      minHours: _parseDouble(json['min_hours']) ?? 1.0,
      plannedDurationHours: _parseDouble(json['planned_duration_hours']) ?? 1.0,
      plannedCleanerCount: json['planned_cleaner_count'] as int? ?? 1,
      hourlyRateSnapshot: _parseDouble(json['hourly_rate_snapshot']) ?? 0.0,
      estimatedTotal: _parseDouble(json['estimated_total']) ?? 0.0,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  HourlyDetails toEntity() => this;
}
