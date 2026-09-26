import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yb_staff_app/core/providers/app_lifecycle_provider.dart';
import 'package:yb_staff_app/core/utils/result.dart';
import 'package:yb_staff_app/data/datasources/job_remote_datasource.dart';
import 'package:yb_staff_app/data/mock/mock_job_repository.dart';
import 'package:yb_staff_app/data/repositories_impl/job_repository_impl.dart';
import 'package:yb_staff_app/domain/entities/job.dart';
import 'package:yb_staff_app/domain/repositories/job_repository.dart';
import 'package:yb_staff_app/domain/entities/job_item.dart';
import 'package:yb_staff_app/presentation/providers/auth_provider.dart';

// Toggle to run with mock data (no backend needed)
const bool useMockData = false;

// Background polling interval when app is in foreground
const _kPollingInterval = Duration(seconds: 30);

// ── Infrastructure ────────────────────────────────────────────────────────────

final jobRemoteDataSourceProvider = Provider<JobRemoteDataSource>((ref) {
  return JobRemoteDataSource(apiClient: ref.watch(apiClientProvider));
});

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  if (useMockData) return MockJobRepository();
  return JobRepositoryImpl(
    dataSource: ref.watch(jobRemoteDataSourceProvider),
  );
});

// ── Selected date ─────────────────────────────────────────────────────────────

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

final selectedDateProvider = StateProvider<DateTime>((_) => _today());

// ── Jobs list (family by date) ────────────────────────────────────────────────

class JobsNotifier extends AutoDisposeFamilyAsyncNotifier<List<Job>, DateTime> {
  Timer? _pollingTimer;

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_kPollingInterval, (_) {
      // Skip if already loading to avoid stacking requests
      if (!state.isLoading) ref.invalidateSelf();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  Future<List<Job>> build(DateTime arg) async {
    // Lifecycle-aware: pause polling when backgrounded, refresh on resume
    ref.listen<AppLifecycleState>(appLifecycleProvider, (_, next) {
      if (next == AppLifecycleState.resumed) {
        // Immediate refresh when user returns to app, then resume polling
        if (!state.isLoading) ref.invalidateSelf();
        _startPolling();
      } else if (next == AppLifecycleState.paused ||
          next == AppLifecycleState.hidden) {
        _stopPolling();
      }
    });

    _startPolling();
    ref.onDispose(_stopPolling);

    final result = await ref.watch(jobRepositoryProvider).getJobsByDate(arg);
    switch (result) {
      case Success<List<Job>>(:final data):
        return data;
      case Failure<List<Job>>(:final message):
        throw Exception(message);
    }
  }

  Future<void> updateStatus(int jobId, JobStatus status) async {
    final current = state.valueOrNull ?? [];
    // Optimistic update
    state = AsyncData(
      current
          .map((j) => j.id == jobId ? j.copyWith(status: status) : j)
          .toList(),
    );

    final result =
        await ref.read(jobRepositoryProvider).updateJobStatus(jobId, status);

    if (result is Failure<void>) {
      // Roll back and propagate error so caller can show toast
      state = AsyncData(current);
      throw Exception(result.message);
    }
  }

  Future<void> submitFinalItems(
    int jobId,
    List<Map<String, dynamic>> finalItems, {
    String? notes,
    String? discountType,
    double discountValue = 0,
    double downPayment = 0,
    bool isUpdate = false,
  }) async {
    final repo = ref.read(jobRepositoryProvider);
    final result = isUpdate
        ? await repo.updateFinalItems(
            jobId,
            finalItems,
            notes: notes,
            discountType: discountType,
            discountValue: discountValue,
            downPayment: downPayment,
          )
        : await repo.submitFinalItems(
            jobId,
            finalItems,
            notes: notes,
            discountType: discountType,
            discountValue: discountValue,
            downPayment: downPayment,
          );

    switch (result) {
      case Success<void>():
        final updatedFinalItems = finalItems.map((map) {
          final isArea = map.containsKey('area_size') && map['area_size'] != null;
          final qty = (map['quantity'] as num?)?.toDouble() ?? 1.0;
          final area = (map['area_size'] as num?)?.toDouble();
          
          return JobItem(
            id: DateTime.now().millisecondsSinceEpoch % 100000 + (map['service_item_id'] as int? ?? 0),
            name: map['item_name'] as String? ?? 'Unknown Item',
            description: map['description'] as String?,
            quantity: isArea ? 1.0 : qty,
            areaSize: area,
            price: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
            subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
            unit: map['unit'] as String?,
            serviceType: map['service_type'] as String?,
            subItemName: map['sub_item_name'] as String?,
            serviceItemId: map['service_item_id']?.toString(),
            notes: map['notes'] as String?,
          );
        }).toList();

        final subtotalPrice = updatedFinalItems.fold(0.0, (sum, item) => sum + item.subtotal);
        double finalTotalPrice = subtotalPrice;
        if (discountType == 'percentage') {
          finalTotalPrice = subtotalPrice - (subtotalPrice * discountValue / 100);
        } else if (discountType == 'nominal') {
          finalTotalPrice = subtotalPrice - discountValue;
        }
        if (finalTotalPrice < 0) finalTotalPrice = 0.0;

        // Optimistic: status → waitingFinalItems and apply finalItems
        final current = state.valueOrNull ?? [];
        state = AsyncData(
          current
              .map((j) => j.id == jobId
                  ? j.copyWith(
                      status: JobStatus.waitingFinalItems,
                      finalItems: updatedFinalItems,
                      subtotalPrice: subtotalPrice,
                      finalTotalPrice: finalTotalPrice,
                      notes: notes ?? j.notes,
                      discountType: discountType ?? j.discountType,
                      discountValue: discountValue,
                    )
                  : j)
              .toList(),
        );
        ref.invalidateSelf();
      case Failure<void>():
        throw Exception(result.message);
    }
  }

  Future<void> submitHourlyReport(
    int jobId,
    double actualDurationHours,
    int actualCleanerCount, {
    String? notes,
    bool isUpdate = false,
  }) async {
    final repo = ref.read(jobRepositoryProvider);
    final result = isUpdate
        ? await repo.updateHourlyReport(
            jobId,
            actualDurationHours,
            actualCleanerCount,
            notes: notes,
          )
        : await repo.submitHourlyReport(
            jobId,
            actualDurationHours,
            actualCleanerCount,
            notes: notes,
          );

    switch (result) {
      case Success<void>():
        // Optimistic: status → waitingFinalItems
        final current = state.valueOrNull ?? [];
        state = AsyncData(
          current
              .map((j) => j.id == jobId
                  ? j.copyWith(status: JobStatus.waitingFinalItems)
                  : j)
              .toList(),
        );
        ref.invalidateSelf();
      case Failure<void>():
        throw Exception(result.message);
    }
  }
}

final jobsByDateProvider = AsyncNotifierProvider.autoDispose
    .family<JobsNotifier, List<Job>, DateTime>(JobsNotifier.new);
