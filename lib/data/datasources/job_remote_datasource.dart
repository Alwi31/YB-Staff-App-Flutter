import 'package:yb_staff_app/core/constants/api_constants.dart';
import 'package:yb_staff_app/core/network/api_client.dart';
import 'package:yb_staff_app/core/utils/date_formatter.dart';
import 'package:yb_staff_app/data/models/job_model.dart';
import 'package:yb_staff_app/domain/entities/job.dart';

class JobRemoteDataSource {
  const JobRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// GET /api/my-jobs?date=YYYY-MM-DD
  Future<List<JobModel>> getJobsByDate(DateTime date) async {
    final response = await _apiClient.get(
      ApiConstants.myJobs,
      queryParams: {'date': DateFormatter.toApi(date)},
    );

    final list = response['data'] as List<dynamic>? ?? [];
    final result = <JobModel>[];

    for (var i = 0; i < list.length; i++) {
      try {
        final item = list[i];
        if (item is! Map<String, dynamic>) continue;
        result.add(JobModel.fromJson(item));
      } catch (_) {}
    }

    return result;
  }

  /// GET /api/staff/orders/{id} — detail satu order berdasarkan ID
  Future<JobModel> getJobById(int jobId) async {
    final response = await _apiClient.get(ApiConstants.staffOrderDetail(jobId));
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
    return JobModel.fromJson(data);
  }

  /// POST /start — assigned → inProgress
  Future<void> updateJobStatus(int jobId, JobStatus status) async {
    switch (status) {
      case JobStatus.inProgress:
        await _apiClient.post(
          ApiConstants.myJobStart(jobId),
          requiresAuth: true,
        );
      default:
        break;
    }
  }

  /// POST /final-items — submit item akhir & tandai pekerjaan selesai
  Future<void> submitFinalItems(
    int jobId,
    List<Map<String, dynamic>> finalItems, {
    String? notes,
    String? discountType,
    double discountValue = 0,
    double downPayment = 0,
  }) async {
    final body = <String, dynamic>{
      'final_items': finalItems,
      'items': finalItems,
    };
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    if (discountType != null) body['discount_type'] = discountType;
    if (discountValue > 0) body['discount_value'] = discountValue.toInt();
    if (downPayment >= 0) body['down_payment'] = downPayment.toInt();
    await _apiClient.post(
      ApiConstants.myJobFinalItems(jobId),
      body: body,
      requiresAuth: true,
    );
  }

  /// PUT /final-items — update final item
  Future<void> updateFinalItems(
    int jobId,
    List<Map<String, dynamic>> finalItems, {
    String? notes,
    String? discountType,
    double discountValue = 0,
    double downPayment = 0,
  }) async {
    final body = <String, dynamic>{
      'final_items': finalItems,
      'items': finalItems,
    };
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    if (discountType != null) body['discount_type'] = discountType;
    if (discountValue > 0) body['discount_value'] = discountValue.toInt();
    if (downPayment >= 0) body['down_payment'] = downPayment.toInt();
    await _apiClient.put(
      ApiConstants.myJobFinalItems(jobId),
      body: body,
    );
  }

  /// POST /hourly-report — submit laporan jam
  Future<void> submitHourlyReport(
    int jobId,
    double actualDurationHours,
    int actualCleanerCount, {
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'actual_duration_hours': actualDurationHours,
      'actual_cleaner_count': actualCleanerCount,
    };
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    await _apiClient.post(
      ApiConstants.myJobHourlyReport(jobId),
      body: body,
      requiresAuth: true,
    );
  }

  /// PUT /hourly-report — update laporan jam
  Future<void> updateHourlyReport(
    int jobId,
    double actualDurationHours,
    int actualCleanerCount, {
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'actual_duration_hours': actualDurationHours,
      'actual_cleaner_count': actualCleanerCount,
    };
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    await _apiClient.put(
      ApiConstants.myJobHourlyReport(jobId),
      body: body,
    );
  }
}
