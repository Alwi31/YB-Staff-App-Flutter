import 'package:yb_staff_app/domain/entities/app_notification.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.jobId,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final int? jobId;
  final bool isRead;
  final DateTime createdAt;

  /// API response structure:
  /// { id(int), type, title, message, data: {order_id?}, is_read(bool), read_at, created_at }
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // id can be int or string
    final rawId = json['id'];
    final id = rawId is int ? rawId.toString() : (rawId as String? ?? '');

    // title and message are at top level
    final title = json['title'] as String? ?? 'Notifikasi';
    final body = json['message'] as String? ?? json['body'] as String? ?? '';
    final type = json['type'] as String? ?? '';

    // order/job id is inside the nested data object
    final nested = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};
    final rawJobId = nested['order_id'] ?? nested['job_id'];
    final jobId = rawJobId is int
        ? rawJobId
        : rawJobId is String
            ? int.tryParse(rawJobId)
            : null;

    // is_read is a direct boolean field
    final isRead = json['is_read'] as bool? ?? json['read_at'] != null;

    return NotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      jobId: jobId,
      isRead: isRead,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  AppNotification toEntity() => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        createdAt: createdAt,
        jobId: jobId,
        isRead: isRead,
      );
}
