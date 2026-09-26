import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yb_staff_app/core/utils/result.dart';
import 'package:yb_staff_app/data/datasources/notification_remote_datasource.dart';
import 'package:yb_staff_app/data/repositories_impl/notification_repository_impl.dart';
import 'package:yb_staff_app/domain/entities/app_notification.dart';
import 'package:yb_staff_app/domain/repositories/notification_repository.dart';
import 'package:yb_staff_app/presentation/providers/auth_provider.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final notificationDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource(apiClient: ref.watch(apiClientProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    dataSource: ref.watch(notificationDataSourceProvider),
  );
});

// ── State ─────────────────────────────────────────────────────────────────────

class NotificationState {
  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) =>
      NotificationState(
        notifications: notifications ?? this.notifications,
        unreadCount: unreadCount ?? this.unreadCount,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() => const NotificationState();

  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repo.getNotifications();
    switch (result) {
      case Success(:final data):
        final unread = data.where((n) => !n.isRead).length;
        state = state.copyWith(
          notifications: data,
          unreadCount: unread,
          isLoading: false,
        );
      case Failure(:final message):
        state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<void> refreshUnreadCount() async {
    final result = await _repo.getUnreadCount();
    if (result case Success(:final data)) {
      state = state.copyWith(unreadCount: data);
    }
  }

  void incrementUnreadCount() {
    state = state.copyWith(unreadCount: state.unreadCount + 1);
  }

  Future<bool> markAsRead(String id) async {
    final result = await _repo.markAsRead(id);
    switch (result) {
      case Success(:final data):
        final updated =
            state.notifications.map((n) => n.id == id ? data : n).toList();
        final unread = updated.where((n) => !n.isRead).length;
        state = state.copyWith(notifications: updated, unreadCount: unread);
        return true;
      case Failure():
        return false;
    }
  }

  Future<bool> markAllAsRead() async {
    final result = await _repo.markAllAsRead();
    switch (result) {
      case Success():
        final updated =
            state.notifications.map((n) => n.copyWith(isRead: true)).toList();
        state = state.copyWith(notifications: updated, unreadCount: 0);
        return true;
      case Failure():
        return false;
    }
  }

  Future<void> registerFcmToken(String token) async {
    await _repo.registerFcmToken(token);
  }

  Future<void> revokeFcmToken(String token) async {
    await _repo.revokeFcmToken(token);
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
        NotificationNotifier.new);

// ── Derived: unread count only (used by home screen badge) ───────────────────

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});
