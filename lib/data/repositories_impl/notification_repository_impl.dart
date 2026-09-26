import 'package:yb_staff_app/core/network/api_exception.dart';
import 'package:yb_staff_app/core/utils/result.dart';
import 'package:yb_staff_app/data/datasources/notification_remote_datasource.dart';
import 'package:yb_staff_app/domain/entities/app_notification.dart';
import 'package:yb_staff_app/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(
      {required NotificationRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final NotificationRemoteDataSource _dataSource;

  @override
  Future<Result<List<AppNotification>>> getNotifications() async {
    try {
      final models = await _dataSource.getNotifications();
      return Success(models.map((m) => m.toEntity()).toList());
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Gagal memuat notifikasi.');
    }
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    try {
      final count = await _dataSource.getUnreadCount();
      return Success(count);
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Gagal memuat jumlah notifikasi.');
    }
  }

  @override
  Future<Result<AppNotification>> markAsRead(String id) async {
    try {
      final model = await _dataSource.markAsRead(id);
      return Success(model.toEntity());
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Gagal menandai notifikasi.');
    }
  }

  @override
  Future<Result<void>> markAllAsRead() async {
    try {
      await _dataSource.markAllAsRead();
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Gagal menandai semua notifikasi.');
    }
  }

  @override
  Future<Result<void>> registerFcmToken(String token) async {
    try {
      await _dataSource.registerFcmToken(token);
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Gagal mendaftarkan token notifikasi.');
    }
  }

  @override
  Future<Result<void>> revokeFcmToken(String token) async {
    try {
      await _dataSource.revokeFcmToken(token);
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Gagal mencabut token notifikasi.');
    }
  }
}
