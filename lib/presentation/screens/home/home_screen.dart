import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yb_staff_app/core/constants/app_strings.dart';
import 'package:yb_staff_app/core/network/http_inspector.dart';
import 'package:yb_staff_app/core/providers/app_lifecycle_provider.dart';
import 'package:yb_staff_app/core/theme/app_colors.dart';
import 'package:yb_staff_app/core/theme/app_spacing.dart';
import 'package:yb_staff_app/core/theme/app_typography.dart';
import 'package:yb_staff_app/core/utils/date_formatter.dart';
import 'package:yb_staff_app/core/widgets/app_toast.dart';
import 'package:yb_staff_app/domain/entities/job.dart';
import 'package:yb_staff_app/domain/entities/user.dart';
import 'package:yb_staff_app/presentation/providers/auth_provider.dart';
import 'package:yb_staff_app/presentation/providers/jobs_provider.dart';
import 'package:yb_staff_app/presentation/providers/notification_provider.dart';
import 'package:yb_staff_app/presentation/widgets/change_password_sheet.dart';
import 'package:yb_staff_app/presentation/widgets/empty_jobs.dart';
import 'package:yb_staff_app/presentation/widgets/confirm_dialog.dart';
import 'package:yb_staff_app/presentation/widgets/job_card.dart';
import 'package:yb_staff_app/presentation/widgets/job_card_skeleton.dart';
import 'package:yb_staff_app/presentation/widgets/job_detail_sheet.dart';
import 'package:yb_staff_app/presentation/widgets/profile_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static Future<void> _confirmLogout(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ConfirmDialog(
        title: "Konfirmasi Keluar",
        description: "Apakah Anda yakin ingin keluar dari akun Anda?",
        confirmLabel: "Ya, Keluar",
        isDanger: true,
        onConfirm: () => Navigator.of(_).pop(true),
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    await ref.read(authProvider.notifier).logout();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appLifecycleProvider);
    ref.listen(appLifecycleProvider, (_, next) {
      if (next == AppLifecycleState.resumed) {
        ref.read(notificationProvider.notifier).refreshUnreadCount();
      }
    });

    final selectedDate = ref.watch(selectedDateProvider);
    final currentUser = ref.watch(currentUserProvider);
    final jobsAsync = ref.watch(jobsByDateProvider(selectedDate));
    final unreadCount = ref.watch(unreadCountProvider);

    final jobs = jobsAsync.valueOrNull ?? [];
    final completedCount =
        jobs.where((j) => j.status == JobStatus.invoiceGenerated).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Green header area ────────────────────────────────────────────
          _HomeHeader(
            user: currentUser,
            date: selectedDate,
            unreadCount: unreadCount,
            onLogout: () => _confirmLogout(context, ref),
            onInspectorTap: httpInspector != null
                ? () => httpInspector!.showInspector()
                : null,
            onProfileTap: () => ProfileSheet.show(context),
            onChangePasswordTap: () => ChangePasswordSheet.show(context),
            onNotificationTap: () =>
                Navigator.of(context).pushNamed('/notifications').then((_) {
              ref.read(notificationProvider.notifier).refreshUnreadCount();
            }),
          ),
          _DateNavigator(
            selectedDate: selectedDate,
            onChanged: (date) => ref.read(selectedDateProvider.notifier).state =
                DateTime(date.year, date.month, date.day),
          ),
          _SummaryBar(
            totalJobs: jobs.length,
            completedJobs: completedCount,
            selectedDate: selectedDate,
          ),
          // ── Scrollable body ───────────────────────────────────────────────
          Expanded(
            child: jobsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (_, __) => const JobCardSkeleton(),
              ),
              error: (err, _) => RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () =>
                    ref.refresh(jobsByDateProvider(selectedDate).future),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: 400,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              size: 48,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              AppStrings.failedLoadData,
                              style: AppTypography.headingLarge
                                  .copyWith(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              err.toString().replaceFirst('Exception: ', ''),
                              style: AppTypography.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            ElevatedButton.icon(
                              onPressed: () => ref
                                  .invalidate(jobsByDateProvider(selectedDate)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusButton),
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text(AppStrings.tryAgain),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              data: (jobs) => RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () =>
                    ref.refresh(jobsByDateProvider(selectedDate).future),
                child: jobs.isEmpty
                    ? const SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: 400,
                          child: EmptyJobs(),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        itemCount: jobs.length,
                        itemBuilder: (context, index) {
                          final job = jobs[index];
                          final notifier = ref
                              .read(jobsByDateProvider(selectedDate).notifier);
                          return JobCard(
                            job: job,
                            onStatusUpdate: (newStatus) async {
                              try {
                                await notifier.updateStatus(job.id, newStatus);
                                if (context.mounted) {
                                  AppToast.show(
                                    context,
                                    AppStrings.statusUpdated,
                                    type: ToastType.success,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  AppToast.show(
                                    context,
                                    e
                                        .toString()
                                        .replaceFirst('Exception: ', ''),
                                    type: ToastType.error,
                                  );
                                }
                                rethrow;
                              }
                            },
                            onFinalItemsSubmit: (items, notes, discountType,
                                discountValue, downPayment) async {
                              final isUpdate = job.finalItems.isNotEmpty ||
                                  job.status == JobStatus.waitingFinalItems ||
                                  job.status == JobStatus.invoiceGenerated ||
                                  job.status == JobStatus.completed;

                              try {
                                await notifier.submitFinalItems(
                                  job.id,
                                  items,
                                  notes: notes,
                                  discountType: discountType,
                                  discountValue: discountValue,
                                  downPayment: downPayment,
                                  isUpdate: isUpdate,
                                );
                                if (context.mounted) {
                                  AppToast.show(
                                    context,
                                    AppStrings.finalItemsSent,
                                    type: ToastType.success,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  AppToast.show(
                                    context,
                                    e
                                        .toString()
                                        .replaceFirst('Exception: ', ''),
                                    type: ToastType.error,
                                  );
                                }
                                rethrow;
                              }
                            },
                            onDetailTap: () =>
                                JobDetailSheet.show(context, job),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.user,
    required this.date,
    required this.unreadCount,
    required this.onLogout,
    required this.onProfileTap,
    required this.onChangePasswordTap,
    required this.onNotificationTap,
    this.onInspectorTap,
  });

  final User? user;
  final DateTime date;
  final int unreadCount;
  final VoidCallback onLogout;
  final VoidCallback onProfileTap;
  final VoidCallback onChangePasswordTap;
  final VoidCallback onNotificationTap;
  final VoidCallback? onInspectorTap;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topPadding + AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: greeting + name + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.greeting,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withAlpha(179),
                  ),
                ),
                Text(
                  user?.name ?? AppStrings.defaultStaffName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.toFull(date),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
          // Bell notification icon with unread badge
          GestureDetector(
            onTap: onNotificationTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Right: avatar + chevron with logout menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') onProfileTap();
              if (value == 'change_password') onChangePasswordTap();
              if (value == 'inspector') onInspectorTap?.call();
              if (value == 'logout') onLogout();
            },
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            itemBuilder: (_) => [
              _menuItem('profile', Icons.person_outline_rounded,
                  AppStrings.menuEditProfile, AppColors.primary),
              _menuItem('change_password', Icons.lock_outline_rounded,
                  AppStrings.menuChangePassword, AppColors.primary),
              if (onInspectorTap != null)
                _menuItem('inspector', Icons.bug_report_outlined,
                    AppStrings.menuHttpInspector, AppColors.primary),
              _menuItem('logout', Icons.logout_rounded, AppStrings.menuLogout,
                  AppColors.error),
            ],
            child: Container(
              padding:
                  const EdgeInsets.only(left: 4, right: 8, top: 4, bottom: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Builder(builder: (_) {
                    final url = user?.avatarUrl;
                    final hasAvatar = url != null && url.isNotEmpty;
                    final isMitra = user?.isMitra ?? false;
                    final bgColor = isMitra
                        ? const Color(0xFFF97316)
                        : const Color(0xFF154D2E);

                    return Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        image: hasAvatar
                            ? DecorationImage(
                                image: NetworkImage(url),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: hasAvatar
                          ? null
                          : Text(
                              _initials(user?.name),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    );
                  }),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'S';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date Navigator ────────────────────────────────────────────────────────────

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.selectedDate,
    required this.onChanged,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF52B788),
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        child: Row(
          children: [
            _NavArrow(
              icon: Icons.chevron_left_rounded,
              onTap: () => onChanged(
                selectedDate.subtract(const Duration(days: 1)),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.primaryLight,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) onChanged(picked);
                },
                child: Text(
                  DateFormatter.toDisplay(selectedDate),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            _NavArrow(
              icon: Icons.chevron_right_rounded,
              onTap: () => onChanged(
                selectedDate.add(const Duration(days: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ── Summary Bar ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.totalJobs,
    required this.completedJobs,
    required this.selectedDate,
  });

  final int totalJobs;
  final int completedJobs;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    final dateLabel =
        isToday ? 'pekerjaan hari ini' : 'pekerjaan di tanggal ini';

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$totalJobs $dateLabel',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withAlpha(204),
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 14,
                color: Colors.white.withAlpha(153),
              ),
              const SizedBox(width: 4),
              Text(
                '$completedJobs ${AppStrings.jobsCompleted}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withAlpha(153),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
