import 'package:yb_staff_app/core/utils/result.dart';
import 'package:yb_staff_app/domain/entities/job.dart';
import 'package:yb_staff_app/domain/entities/job_item.dart';
import 'package:yb_staff_app/domain/repositories/job_repository.dart';

class MockJobRepository implements JobRepository {
  @override
  Future<Result<List<Job>>> getJobsByDate(DateTime date) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return Success(_buildMockJobs(date));
  }

  @override
  Future<Result<void>> updateJobStatus(int jobId, JobStatus status) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return const Success(null);
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
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const Success(null);
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
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const Success(null);
  }

  @override
  Future<Result<void>> submitHourlyReport(
    int jobId,
    double actualDurationHours,
    int actualCleanerCount, {
    String? notes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const Success(null);
  }

  @override
  Future<Result<void>> updateHourlyReport(
    int jobId,
    double actualDurationHours,
    int actualCleanerCount, {
    String? notes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const Success(null);
  }

  // Data struktur mengikuti response GET /api/my-jobs?date=YYYY-MM-DD (FSD §11.4)
  List<Job> _buildMockJobs(DateTime date) => [
        Job(
          id: 1,
          assignedStaffId: 5,
          assignedStaffName: 'Parjo',
          customerName: 'Stephen',
          customerPhone: '081234567890',
          address: 'Jl. Senen Raya No. 88',
          scheduledAt: date.copyWith(hour: 9, minute: 0),
          status: JobStatus.assigned,
          services: const ['Cuci Dry Wash'],
          region: 'Jakarta Pusat',
          power: '2200 VA',
          discount: 0,
          photos: const [],
          items: const [
            JobItem(
              id: 1,
              name: 'Queen (1.4×2m) / (1.6×2m)',
              description: 'Matras - Cuci Dry Wash',
              quantity: 2,
              price: 350000,
              subtotal: 700000,
            ),
          ],
          notes: null,
        ),
        Job(
          id: 2,
          customerName: 'Rehan',
          customerPhone: '085353236463',
          address: 'Jl. Condet Raya No. 156',
          scheduledAt: date.copyWith(hour: 13, minute: 0),
          status: JobStatus.invoiceGenerated,
          services: const ['Cuci Dry Wash', 'Deep Vacuum'],
          region: 'Jakarta Timur',
          power: '2200 VA',
          discount: 0,
          photos: const [],
          items: const [
            JobItem(
              id: 2,
              name: 'Single (1×2m) / (1.2×2m)',
              description: 'Matras - Cuci Dry Wash',
              quantity: 1,
              price: 300000,
              subtotal: 300000,
            ),
            JobItem(
              id: 3,
              name: 'King (1.8×2m)',
              description: 'Matras - Deep Vacuum',
              quantity: 1,
              price: 200000,
              subtotal: 200000,
            ),
          ],
          notes: 'Pastikan bawa cairan pembersih ekstra.',
          assignedStaffId: 5,
          assignedStaffName: 'Parjo',
        ),
        Job(
          id: 3,
          customerName: 'Siti Rahayu',
          customerPhone: '089876543210',
          address: 'Jl. Anggrek Raya No. 5, Cimahi',
          scheduledAt: date.copyWith(hour: 15, minute: 30),
          status: JobStatus.completed,
          services: const ['Cuci Kasur'],
          region: 'Bandung Barat',
          power: '1300 VA',
          discount: 50000,
          photos: const [],
          items: const [
            JobItem(
              id: 4,
              name: 'Single (1×2m)',
              description: 'Kasur - Cuci Kering',
              quantity: 2,
              price: 120000,
              subtotal: 240000,
            ),
          ],
          notes: null,
        ),
      ];
}
