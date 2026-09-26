import 'package:yb_staff_app/domain/entities/hourly_report.dart';

class HourlyReportModel extends HourlyReport {
  const HourlyReportModel({
    required super.id,
    required super.actualDurationHours,
    required super.actualCleanerCount,
    required super.finalTotalPrice,
    super.notes,
    super.submittedByName,
    super.createdAt,
  });

  factory HourlyReportModel.fromJson(Map<String, dynamic> json) {
    return HourlyReportModel(
      id: json['id'] as int? ?? 0,
      actualDurationHours: _parseDouble(json['actual_duration_hours']) ?? 0.0,
      actualCleanerCount: json['actual_cleaner_count'] as int? ?? 1,
      finalTotalPrice: _parseDouble(json['final_total_price']) ?? 0.0,
      notes: json['notes'] as String?,
      submittedByName: json['submitted_by_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  HourlyReport toEntity() => this;
}
