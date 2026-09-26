import 'package:flutter/material.dart';
import 'package:yb_staff_app/core/theme/app_spacing.dart';

/// Skeleton placeholder that matches the visual structure of [JobCard].
/// Uses a shimmer-like gradient sweep animation for a polished loading state.
class JobCardSkeleton extends StatefulWidget {
  const JobCardSkeleton({super.key});

  @override
  State<JobCardSkeleton> createState() => _JobCardSkeletonState();
}

class _JobCardSkeletonState extends State<JobCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _shimmerAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, __) {
        final shimmerColor = Color.lerp(
          const Color(0xFFE8EAED),
          const Color(0xFFF5F6F8),
          _shimmerAnim.value,
        )!;
        final shimmerDark = Color.lerp(
          const Color(0xFFDDE0E4),
          const Color(0xFFECEEF0),
          _shimmerAnim.value,
        )!;
        return _SkeletonCard(
          shimmerColor: shimmerColor,
          shimmerDark: shimmerDark,
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({
    required this.shimmerColor,
    required this.shimmerDark,
  });

  final Color shimmerColor;
  final Color shimmerDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Accent bar
            Container(height: 3, color: shimmerDark),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges row + status badge
                  Row(
                    children: [
                      _box(shimmerColor, width: 80, height: 22, radius: 20),
                      const SizedBox(width: AppSpacing.xs),
                      _box(shimmerColor, width: 70, height: 22, radius: 20),
                      const Spacer(),
                      _box(shimmerColor, width: 90, height: 22, radius: 20),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Customer name
                  _box(shimmerColor, width: 180, height: 18),
                  const SizedBox(height: AppSpacing.sm),
                  // Schedule row
                  Row(
                    children: [
                      _box(shimmerDark, width: 14, height: 14, radius: 7),
                      const SizedBox(width: AppSpacing.xs),
                      _box(shimmerColor, width: 200, height: 12),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Address row
                  Row(
                    children: [
                      _box(shimmerDark, width: 14, height: 14, radius: 7),
                      const SizedBox(width: AppSpacing.xs),
                      _box(shimmerColor, width: 220, height: 12),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Nav button placeholder
                  _box(shimmerColor,
                      width: double.infinity,
                      height: 44,
                      radius: AppSpacing.radiusButton),
                  const SizedBox(height: AppSpacing.sm),
                  // Action button placeholder
                  _box(shimmerDark,
                      width: double.infinity,
                      height: 44,
                      radius: AppSpacing.radiusButton),
                  const SizedBox(height: AppSpacing.sm),
                  // Detail button placeholder
                  _box(shimmerColor,
                      width: double.infinity,
                      height: 44,
                      radius: AppSpacing.radiusButton),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(
    Color color, {
    required double width,
    required double height,
    double radius = AppSpacing.sm,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
