import 'package:yb_staff_app/core/config/env.dart';

abstract final class ApiConstants {
  static const String baseUrl = Env.baseUrl;

  // ── Auth — Public (FSD §11.1) ─────────────────────────────────────────────
  /// POST  — login staff/admin, returns { token, user }
  static const String login = '/api/auth/login';

  /// POST  — invalidate current Sanctum token (requires auth)
  static const String logout = '/api/auth/logout';

  /// GET   — profil user yang sedang login (requires auth)
  static const String me = '/api/auth/me';

  // ── Staff — Jobs (FSD §11.4) ──────────────────────────────────────────────
  /// GET   — daftar job milik staff pada tanggal tertentu
  ///         query: ?date=YYYY-MM-DD
  static const String myJobs = '/api/my-jobs';

  /// POST  — mulai mengerjakan order (ubah status → in_progress)
  static String myJobStart(int orderId) => '/api/my-jobs/$orderId/start';

  /// POST  — submit final item & tandai pekerjaan selesai
  ///         body: { items: [ { name, qty, price } ] }
  static String myJobFinalItems(int orderId) =>
      '/api/my-jobs/$orderId/final-items';

  /// POST/PUT — submit/update laporan jam aktual (hourly)
  static String myJobHourlyReport(int orderId) =>
      '/api/my-jobs/$orderId/hourly-report';

  // ── Staff — Order Detail (FSD §11.4) ─────────────────────────────────────
  /// GET   — detail lengkap satu order (customer, items, foto, dll.)
  static String staffOrderDetail(int orderId) => '/api/staff/orders/$orderId';

  // ── Staff — Foto Item (FSD §11.4) ─────────────────────────────────────────
  /// POST  — upload foto item pekerjaan (multipart/form-data)
  ///         field: file = image file
  static String uploadItemPhoto(int orderId) => '/api/my-jobs/$orderId/photos';

  /// DELETE — hapus foto item yang sudah diupload
  static String deleteItemPhoto(int orderId, int photoId) =>
      '/api/my-jobs/$orderId/photos/$photoId';

  // ── Katalog Harga (FSD §11.3) ────────────────────────────────────────────
  /// GET   — katalog item berdasarkan tipe layanan
  ///         query: ?service_type=<service_type>
  static const String serviceItems = '/api/service-items';

  // ── Auth — Profile & Password (FSD §11.2) ────────────────────────────────
  /// PUT — update nama + nomor (requires auth)
  ///        body: { name, phone }
  static const String updateProfile = '/api/profile';

  /// POST  — upload foto profil (multipart/form-data, requires auth)
  ///         field: avatar = image file
  static const String updateAvatar = '/api/profile/avatar';

  /// POST  — ubah kata sandi (requires auth)
  ///         body: { old_password, password, password_confirmation }
  static const String changePassword = '/api/profile/password';

  // ── Staff — Notifikasi & Device Token (FSD §11.5) ────────────────────────
  /// POST  — daftarkan/perbarui FCM token perangkat (requires auth)
  static const String registerDeviceToken = '/api/fcm-token';

  /// DELETE — cabut FCM token saat logout
  static const String revokeDeviceToken = '/api/fcm-token';

  // ── Notifications ─────────────────────────────────────────────────────────
  /// GET   — daftar notifikasi milik user
  static const String notifications = '/api/notifications';

  /// GET   — jumlah notifikasi belum dibaca
  static const String notificationsUnreadCount =
      '/api/notifications/unread-count';

  /// PATCH — tandai satu notifikasi sebagai sudah dibaca
  static String notificationRead(String id) => '/api/notifications/$id/read';

  /// PATCH — tandai semua notifikasi sebagai sudah dibaca
  static const String notificationsReadAll = '/api/notifications/read-all';
}
