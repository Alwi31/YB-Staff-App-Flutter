import 'package:yb_staff_app/core/utils/result.dart';
import 'package:yb_staff_app/domain/entities/job.dart';

abstract interface class JobRepository {
  Future<Result<List<Job>>> getJobsByDate(DateTime date);
  Future<Result<void>> updateJobStatus(int jobId, JobStatus status);
  Future<Result<void>> submitFinalItems(
    int jobId,
    List<Map<String, dynamic>> finalItems, {
    String? notes,
    String? discountType,
    double discountValue = 0,
    double downPayment = 0,
  });

  Future<Result<void>> updateFinalItems(
    int jobId,
    List<Map<String, dynamic>> finalItems, {
    String? notes,
    String? discountType,
    double discountValue = 0,
    double downPayment = 0,
  });

  Future<Result<void>> submitHourlyReport(
    int jobId,
    double actualDurationHours,
    int actualCleanerCount, {
    String? notes,
  });

  Future<Result<void>> updateHourlyReport(
    int jobId,
    double actualDurationHours,
    int actualCleanerCount, {
    String? notes,
  });
}
