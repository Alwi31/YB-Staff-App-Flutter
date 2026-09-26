import 'dart:io';

import 'package:yb_staff_app/core/constants/api_constants.dart';
import 'package:yb_staff_app/core/network/api_client.dart';
import 'package:yb_staff_app/data/models/notification_model.dart';

class NotificationRemoteDataSource {
  const NotificationRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _apiClient.get(ApiConstants.notifications);
    final list = _extractList(response);
    return list
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response =
        await _apiClient.get(ApiConstants.notificationsUnreadCount);
    return _extractCount(response);
  }

  Future<NotificationModel> markAsRead(String id) async {
    final response = await _apiClient.patch(ApiConstants.notificationRead(id));
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
    return NotificationModel.fromJson(data);
  }

  Future<void> markAllAsRead() async {
    await _apiClient.patch(ApiConstants.notificationsReadAll);
  }

  Future<void> registerFcmToken(String token) async {
    await _apiClient.post(
      ApiConstants.registerDeviceToken,
      body: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      },
      requiresAuth: true,
    );
  }

  Future<void> revokeFcmToken(String token) async {
    await _apiClient.delete(
      ApiConstants.revokeDeviceToken,
      body: {'token': token},
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Extracts a List from various Laravel response shapes:
  ///   { "data": [...] }
  ///   { "data": { "data": [...], "total": n } }   ← paginated
  ///   { "notifications": [...] }
  ///   [ ... ]                                      ← bare array
  List<dynamic> _extractList(Map<String, dynamic> response) {
    final raw = response['data'];

    // Simple list under "data"
    if (raw is List) return raw;

    // Paginated: "data" contains a nested object with its own "data" list
    if (raw is Map<String, dynamic>) {
      final nested = raw['data'];
      if (nested is List) return nested;
    }

    // Some APIs return the array at a different key
    for (final key in ['notifications', 'items', 'results']) {
      final val = response[key];
      if (val is List) return val;
    }

    return [];
  }

  /// Extracts an int count from various response shapes:
  ///   { "data": { "count": 3 } }
  ///   { "data": { "unread_count": 3 } }
  ///   { "data": 3 }
  ///   { "count": 3 }
  ///   { "unread_count": 3 }
  int _extractCount(Map<String, dynamic> response) {
    final raw = response['data'];

    if (raw is int) return raw;
    if (raw is num) return raw.toInt();

    if (raw is Map<String, dynamic>) {
      for (final key in ['count', 'unread_count', 'unread', 'total']) {
        final val = raw[key];
        if (val is num) return val.toInt();
      }
    }

    for (final key in ['count', 'unread_count', 'unread', 'total']) {
      final val = response[key];
      if (val is num) return val.toInt();
    }

    return 0;
  }
}
