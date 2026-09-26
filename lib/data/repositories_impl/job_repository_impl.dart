import 'package:yb_staff_app/core/network/api_exception.dart';
import 'package:yb_staff_app/core/utils/result.dart';
import 'package:yb_staff_app/data/datasources/job_remote_datasource.dart';
import 'package:yb_staff_app/domain/entities/job.dart';
import 'package:yb_staff_app/domain/repositories/job_repository.dart';

class JobRepositoryImpl implements JobRepository {
  const JobRepositoryImpl({required JobRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final JobRemoteDataSource _dataSource;

  @override
  Future<Result<List<Job>>> getJobsByDate(DateTime date) async {
    try {
      final models = await _dataSource.getJobsByDate(date);
      return Success(models.map((e) => e.toEntity()).toList());
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Gagal memuat data: $e');
    }
  }

  @override
  Future<Result<void>> updateJobStatus(int jobId, JobStatus status) async {
    try {
      await _dataSource.updateJobStatus(jobId, status);
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Gagal memperbarui status pekerjaan.');
    }
  }

  @override
  Future<Result<void>> submitFinalItems(
    int jobId,
    List<Map<String, dynamic>> finalItems, {
    String? notes,
    String? discountType,
    double discountValue = 0,
    double downPayment = 0,
  }) async {
    try {
      await _dataSource.submitFinalItems(
        jobId,
        finalItems,
        notes: notes,
        discountType: discountType,
        discountValue: discountValue,
        downPayment: downPayment,
      );
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Gagal mengirim laporan item akhir.');
    }
  }

  @override
  Future<Result<void>> updateFinalItems(
    int jobId,
    List<Map<String, dynamic>> finalItems, {
    String? notes,
    String? discountType,
    double discountValue = 0,
    double downPayment = 0,
  }) async {
    try {
      await _dataSource.updateFinalItems(
        jobId,
        finalItems,
        notes: notes,
        discountType: discountType,
        discountValue: discountValue,
        downPayment: downPayment,
      );
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Gagal memperbarui laporan item akhir.');
    }
  }

  @override
  Future<Result<void>> submitHourlyReport(
    int jobId,
    double actualDurationHours,
    int actualCleanerCount, {
    String? notes,
  }) async {
    try {
      await _dataSource.submitHourlyReport(
        jobId,
        actualDurationHours,
        actualCleanerCount,
        notes: notes,
      );
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Gagal mengirim laporan jam kerja.');
    }
  }

  @override
  Future<Result<void>> updateHourlyReport(
    int jobId,
    double actualDurationHours,
    int actualCleanerCount, {
    String? notes,
  }) async {
    try {
      await _dataSource.updateHourlyReport(
        jobId,
        actualDurationHours,
        actualCleanerCount,
        notes: notes,
      );
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Gagal memperbarui laporan jam kerja.');
    }
  }
}
