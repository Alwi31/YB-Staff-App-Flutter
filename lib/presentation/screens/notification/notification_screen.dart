import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yb_staff_app/core/constants/app_strings.dart';
import 'package:yb_staff_app/core/theme/app_colors.dart';
import 'package:yb_staff_app/core/theme/app_spacing.dart';
import 'package:yb_staff_app/core/utils/date_formatter.dart';
import 'package:yb_staff_app/core/widgets/app_toast.dart';
import 'package:yb_staff_app/data/datasources/job_remote_datasource.dart';
import 'package:yb_staff_app/domain/entities/app_notification.dart';
import 'package:yb_staff_app/presentation/providers/auth_provider.dart';
import 'package:yb_staff_app/presentation/providers/notification_provider.dart';
import 'package:yb_staff_app/presentation/widgets/job_detail_sheet.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadNotifications();
    });
  }

  Future<void> _markAllAsRead() async {
    final ok = await ref.read(notificationProvider.notifier).markAllAsRead();
    if (!mounted) return;
    AppToast.show(
      context,
      ok ? AppStrings.allNotifRead : AppStrings.failedMarkAllNotif,
      type: ok ? ToastType.success : ToastType.error,
    );
  }

  Future<void> _onTapNotification(AppNotification notif) async {
    // Mark as read
    if (!notif.isRead) {
      await ref.read(notificationProvider.notifier).markAsRead(notif.id);
    }

    if (!mounted) return;

    // Navigate to job detail if notification has jobId
    if (notif.jobId != null) {
      await _openJobDetail(notif.jobId!);
    }
  }

  Future<void> _openJobDetail(int jobId) async {
    try {
      final ds = JobRemoteDataSource(apiClient: ref.read(apiClientProvider));
      final model = await ds.getJobById(jobId);
      final job = model.toEntity();
      if (!mounted) return;
      await JobDetailSheet.show(context, job);
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        context,
        AppStrings.failedLoadJobDetail,
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              topPadding + AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusCard),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    AppStrings.notificationsTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (state.notifications.any((n) => !n.isRead))
                  TextButton(
                    onPressed: state.isLoading ? null : _markAllAsRead,
                    child: Text(
                      AppStrings.markAllRead,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withAlpha(210),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () =>
                  ref.read(notificationProvider.notifier).loadNotifications(),
              child: state.isLoading && state.notifications.isEmpty
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    )
                  : state.error != null && state.notifications.isEmpty
                      ? _ErrorView(
                          message: state.error!,
                          onRetry: () => ref
                              .read(notificationProvider.notifier)
                              .loadNotifications(),
                        )
                      : state.notifications.isEmpty
                          ? const _EmptyView()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md),
                              itemCount: state.notifications.length,
                              itemBuilder: (_, i) => _NotificationTile(
                                notification: state.notifications[i],
                                onTap: () =>
                                    _onTapNotification(state.notifications[i]),
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  IconData get _icon {
    final type = notification.type.toLowerCase();
    if (type.contains('assign')) return Icons.assignment_ind_rounded;
    if (type.contains('status') || type.contains('job')) {
      return Icons.work_history_rounded;
    }
    if (type.contains('invoice')) return Icons.receipt_long_rounded;
    if (type.contains('cancel')) return Icons.cancel_rounded;
    return Icons.notifications_rounded;
  }

  Color get _iconColor {
    final type = notification.type.toLowerCase();
    if (type.contains('cancel')) return const Color(0xFFEF4444);
    if (type.contains('invoice') || type.contains('complete')) {
      return const Color(0xFF10B981);
    }
    return AppColors.primary;
  }

  Color get _iconBg {
    final type = notification.type.toLowerCase();
    if (type.contains('cancel')) return const Color(0xFFFEF2F2);
    if (type.contains('invoice') || type.contains('complete')) {
      return const Color(0xFFD1FAE5);
    }
    return AppColors.badgeBg;
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color:
              isUnread ? AppColors.primary.withAlpha(10) : Colors.transparent,
          border: const Border(
            bottom: BorderSide(
              color: Color(0xFFE5E7EB),
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              ),
              child: Icon(_icon, size: 20, color: _iconColor),
            ),
            const SizedBox(width: AppSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6, top: 2),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        DateFormatter.toRelative(notification.createdAt),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                      if (notification.jobId != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          AppStrings.viewJob,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty & error states ──────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.badgeBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_outlined,
                size: 38, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppStrings.noNotifications,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.noNotificationsDesc,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(AppStrings.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
