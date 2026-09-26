import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yb_staff_app/core/constants/app_strings.dart';
import 'package:yb_staff_app/core/theme/app_colors.dart';
import 'package:yb_staff_app/core/theme/app_spacing.dart';
import 'package:yb_staff_app/domain/entities/job.dart';
import 'package:yb_staff_app/domain/entities/hourly_details.dart';
import 'package:yb_staff_app/presentation/providers/jobs_provider.dart';
import 'package:yb_staff_app/core/widgets/app_toast.dart';
import 'package:yb_staff_app/core/utils/currency_formatter.dart';
import 'package:yb_staff_app/presentation/widgets/confirm_dialog.dart';

class _ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final intValue = int.tryParse(newValue.text.replaceAll('.', ''));
    if (intValue == null) return oldValue;

    final newString = _fmt(intValue.toString());
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }

  static String _fmt(String s) {
    return s.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}

class HourlyReportSheet extends ConsumerStatefulWidget {
  const HourlyReportSheet({
    super.key,
    required this.job,
  });

  final Job job;

  static Future<void> show(
    BuildContext context, {
    required Job job,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HourlyReportSheet(job: job),
    );
  }

  @override
  ConsumerState<HourlyReportSheet> createState() => _HourlyReportSheetState();
}

class _HourlyReportSheetState extends ConsumerState<HourlyReportSheet> {
  late double _actualDurationHours;
  late int _actualCleanerCount;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  // Discount state
  double _selectedPercent = 0;
  final _discountNominalCtrl = TextEditingController();

  double get _discountAmount =>
      double.tryParse(_discountNominalCtrl.text.replaceAll('.', '')) ?? 0;
  double get _dpAmount => widget.job.minimumPayment ?? widget.job.downPayment;

  double get _snapshotRate => widget.job.hourlyDetails?.hourlyRateSnapshot ?? 0.0;

  double get _subtotal => _actualDurationHours * _actualCleanerCount * _snapshotRate;

  double get _finalTotal =>
      (_subtotal - _discountAmount).clamp(0.0, double.infinity);
  
  double get _outstandingAmount =>
      (_finalTotal - _dpAmount).clamp(0.0, double.infinity);

  bool get _isDurationValid {
    final minHours = widget.job.hourlyDetails?.minHours ?? 0.5;
    return _actualDurationHours >= minHours;
  }

  void _selectPercent(double percent) {
    final amount = (_subtotal * percent / 100).round();
    setState(() {
      _selectedPercent = percent;
      _discountNominalCtrl.text =
          amount > 0 ? _ThousandSeparatorFormatter._fmt(amount.toString()) : '';
    });
  }

  @override
  void initState() {
    super.initState();
    final hourly = widget.job.hourlyDetails;
    final report = widget.job.hourlyReport;
    _actualDurationHours = report?.actualDurationHours ??
        hourly?.plannedDurationHours ??
        hourly?.minHours ??
        1.0;
    _actualCleanerCount = report?.actualCleanerCount ?? hourly?.plannedCleanerCount ?? 1;
    if (widget.job.notes != null) {
      _notesController.text = widget.job.notes!;
    }

    if (widget.job.discount > 0) {
      _discountNominalCtrl.text = _ThousandSeparatorFormatter._fmt(
          widget.job.discount.toInt().toString());
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _discountNominalCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final isEditing = widget.job.status == JobStatus.waitingFinalItems ||
        widget.job.status == JobStatus.invoiceGenerated ||
        widget.job.status == JobStatus.completed;

    showDialog(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: isEditing ? "Konfirmasi Pembaruan" : "Konfirmasi Pengiriman Laporan",
        description: isEditing 
            ? "Laporan Jam Kerja akan diperbarui dan otomatis memperbarui data yang telah dikirim ke Admin. Apakah Anda yakin ingin melanjutkan?"
            : "Pastikan durasi aktual dan jumlah cleaner sudah sesuai pengerjaan lapangan. Laporan ini akan digunakan untuk pembuatan invoice oleh admin.",
        confirmLabel: isEditing ? "Ya, Lanjutkan" : "Kirim Laporan",
        onConfirm: () {
          Navigator.pop(ctx);
          _executeSubmit();
        },
      ),
    );
  }

  Future<void> _executeSubmit() async {
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(jobsByDateProvider(widget.job.scheduledAt).notifier)
          .submitHourlyReport(
            widget.job.id,
            _actualDurationHours,
            _actualCleanerCount,
            notes: _notesController.text.trim(),
            isUpdate: widget.job.status ==
                JobStatus.waitingFinalItems, // or depending on flow
          );

      if (mounted) {
        Navigator.pop(context);
        AppToast.show(context, 'Laporan jam kerja berhasil dikirim',
            type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hourly = widget.job.hourlyDetails;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSheet),
            ),
          ),
          child: Column(
            children: [
              _buildDragHandle(),
              _buildHeader(),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    bottomInset + 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hourly != null) _buildEstimasiAwal(hourly),
                      const SizedBox(height: AppSpacing.lg),
                      _buildAktualInputs(hourly),
                      const SizedBox(height: AppSpacing.xl),
                      _buildDiscountSection(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildNotesField(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildPricingSummary(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFD1D5DB),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.md, AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Laporan Jam Kerja',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Order Customer ${widget.job.customerName}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon:
                const Icon(Icons.close_rounded, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimasiAwal(HourlyDetails hourly) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estimasi Awal',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF16A34A))),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Durasi:', style: GoogleFonts.plusJakartaSans(fontSize: 14)),
              Text('${hourly.plannedDurationHours} Jam',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cleaner:', style: GoogleFonts.plusJakartaSans(fontSize: 14)),
              Text('${hourly.plannedCleanerCount} Orang',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAktualInputs(HourlyDetails? hourly) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // Durasi Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Durasi Aktual',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    if (hourly?.minHours != null)
                      Text(
                        'Min. ${hourly!.minHours} jam',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: AppColors.textHint),
                      ),
                  ],
                ),
              ),
              _stepper(
                value: _actualDurationHours.toString(),
                onDecrement: _actualDurationHours > (hourly?.minHours ?? 1.0)
                    ? () => setState(() {
                          _actualDurationHours -= 0.5;
                          _selectedPercent = 0; // reset discount on qty change
                        })
                    : null,
                onIncrement: () => setState(() {
                  _actualDurationHours += 0.5;
                  _selectedPercent = 0; // reset discount on qty change
                }),
              ),
            ],
          ),
          if (!_isDurationValid) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: Color(0xFFEF4444)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Durasi minimal ${hourly?.minHours ?? 0.5} jam untuk wilayah ${widget.job.region ?? 'ini'}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: const Color(0xFFEF4444)),
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
          // Cleaner Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jumlah Cleaner',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Orang',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              _stepper(
                value: _actualCleanerCount.toString(),
                onDecrement: _actualCleanerCount > 1
                    ? () => setState(() {
                          _actualCleanerCount -= 1;
                          _selectedPercent = 0;
                        })
                    : null,
                onIncrement: () => setState(() {
                  _actualCleanerCount += 1;
                  _selectedPercent = 0;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepper({
    required String value,
    VoidCallback? onDecrement,
    VoidCallback? onIncrement,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepperBtn(Icons.remove_rounded, onDecrement),
        SizedBox(
          width: 44,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _stepperBtn(Icons.add_rounded, onIncrement),
      ],
    );
  }

  Widget _stepperBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(
            color: onTap != null
                ? const Color(0xFFD1D5DB)
                : const Color(0xFFEEEEEE),
          ),
          borderRadius: BorderRadius.circular(6),
          color:
              onTap != null ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? AppColors.textSecondary : AppColors.textHint,
        ),
      ),
    );
  }

  Widget _buildDiscountSection() {
    const percentOptions = [5.0, 10.0, 15.0, 20.0];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.discountLabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: percentOptions.map((p) {
              final isSelected = _selectedPercent == p;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => _selectPercent(isSelected ? 0 : p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFFF3F4F6),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusButton),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${p.toInt()}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.discountNominalLabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _discountNominalCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [_ThousandSeparatorFormatter()],
            onChanged: (_) => setState(() => _selectedPercent = 0),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixText: AppStrings.rpPrefix,
              prefixStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppColors.textSecondary),
              hintText: '0',
              hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppColors.textHint),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: const Color(0xFFF7F7F5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catatan Pengerjaan (Opsional)',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: AppStrings.additionalNotesHint,
            hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: AppColors.textHint),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: const Color(0xFFF7F7F5),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSummary() {
    final subtotal = _subtotal;
    final discount = _discountAmount;
    final total = _finalTotal;
    final dp = _dpAmount;
    final outstanding = _outstandingAmount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        children: [
          _summaryRow(
              'Subtotal ($_actualDurationHours Jam × $_actualCleanerCount Staff)',
              CurrencyFormatter.format(subtotal)),
          _summaryRow(
            _discountLabel(),
            '- ${CurrencyFormatter.format(discount)}',
            valueColor: const Color(0xFFEF4444),
          ),
          const Divider(height: AppSpacing.lg, color: Color(0xFFBBF7D0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.totalFinal,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text(CurrencyFormatter.format(total),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ],
          ),
          if (dp > 0) ...[
            const Divider(height: AppSpacing.xl, color: Color(0xFFBBF7D0)),
            _summaryRow(
              AppStrings.downPaymentLabel,
              CurrencyFormatter.format(dp),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: outstanding > 0
                    ? const Color(0xFFFFF7ED)
                    : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(
                  color: outstanding > 0
                      ? const Color(0xFFFED7AA)
                      : const Color(0xFF6EE7B7),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(
                      outstanding > 0
                          ? Icons.pending_outlined
                          : Icons.check_circle_outline,
                      size: 14,
                      color: outstanding > 0
                          ? const Color(0xFFD97706)
                          : const Color(0xFF059669),
                    ),
                    const SizedBox(width: 6),
                    Text(AppStrings.remainingBill,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: outstanding > 0
                              ? const Color(0xFFD97706)
                              : const Color(0xFF059669),
                        )),
                  ]),
                  Text(
                    outstanding > 0
                        ? CurrencyFormatter.format(outstanding)
                        : AppStrings.lunas,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: outstanding > 0
                          ? const Color(0xFFD97706)
                          : const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _discountLabel() {
    if (_selectedPercent > 0) {
      return '${AppStrings.discountLabel} (${_selectedPercent.toStringAsFixed(_selectedPercent % 1 == 0 ? 0 : 1)}%)';
    }
    return AppStrings.discountLabel;
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.inputBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: (_isSubmitting || !_isDurationValid) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(
                    'Kirim Laporan',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
