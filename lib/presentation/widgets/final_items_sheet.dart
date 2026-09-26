import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yb_staff_app/core/constants/app_strings.dart';
import 'package:yb_staff_app/core/theme/app_colors.dart';
import 'package:yb_staff_app/core/theme/app_spacing.dart';
import 'package:yb_staff_app/core/utils/currency_formatter.dart';
import 'package:yb_staff_app/domain/entities/job.dart';
import 'package:yb_staff_app/domain/entities/job_item.dart';
import 'package:yb_staff_app/domain/entities/service_item.dart';
import 'package:yb_staff_app/presentation/providers/catalog_provider.dart';
import 'package:yb_staff_app/core/widgets/app_toast.dart';
import 'package:yb_staff_app/presentation/widgets/confirm_dialog.dart';

typedef FinalItemsSubmitCallback = Future<void> Function(
  List<Map<String, dynamic>> items,
  String? notes,
  String? discountType,
  double discountValue,
  double downPayment,
);

class FinalItemsSheet extends ConsumerStatefulWidget {
  const FinalItemsSheet({
    super.key,
    required this.job,
    required this.onSubmit,
  });

  final Job job;
  final FinalItemsSubmitCallback onSubmit;

  static Future<void> show(
    BuildContext context, {
    required Job job,
    required FinalItemsSubmitCallback onSubmit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FinalItemsSheet(job: job, onSubmit: onSubmit),
    );
  }

  @override
  ConsumerState<FinalItemsSheet> createState() => _FinalItemsSheetState();
}

class _FinalItemsSheetState extends ConsumerState<FinalItemsSheet> {
  late String _selectedServiceType;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<_ItemEntry> _items = [];
  final Set<int> _selectedCatalogIds = {};

  final _notesCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _showPrefilledBanner = true;

  // ── Catalog collapsible ───────────────────────────────────────────────────
  bool _showCatalog = false;

  // ── Discount & DP ─────────────────────────────────────────────────────────
  double _selectedPercent = 0;
  final _discountNominalCtrl = TextEditingController();

  double get _discountAmount =>
      double.tryParse(_discountNominalCtrl.text.replaceAll('.', '')) ?? 0;
  double get _dpAmount => widget.job.minimumPayment ?? widget.job.downPayment;
  double get _finalTotal =>
      (_subtotal - _discountAmount).clamp(0.0, double.infinity);
  double get _outstandingAmount =>
      (_finalTotal - _dpAmount).clamp(0.0, double.infinity);

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
    final sourceItems = widget.job.finalItems.isNotEmpty
        ? widget.job.finalItems
        : widget.job.items;

    for (final item in sourceItems) {
      final entry = _ItemEntry.fromJobItem(item);
      _items.add(entry);
      if (entry.catalogId != null) {
        _selectedCatalogIds.add(entry.catalogId!);
      }
    }
    _selectedServiceType = _resolveDefaultServiceType();

    if (widget.job.finalItems.isNotEmpty) {
      _showPrefilledBanner = false;
    }

    if (widget.job.notes != null && widget.job.notes!.isNotEmpty) {
      _notesCtrl.text = widget.job.notes!;
    }

    // Pre-fill discount and DP from job order
    if (widget.job.discount > 0) {
      _discountNominalCtrl.text = _ThousandSeparatorFormatter._fmt(
          widget.job.discount.toInt().toString());
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _notesCtrl.dispose();
    _discountNominalCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  String _resolveDefaultServiceType() {
    for (final svc in widget.job.services) {
      final normalized = svc.toLowerCase().replaceAll(' ', '_');
      // Exact match dulu (lebih akurat, terutama untuk add_on)
      for (final t in kServiceTypes) {
        if (t.key == normalized || t.key == svc) return t.key;
      }
      // Fallback: partial match
      for (final t in kServiceTypes) {
        if (normalized.contains(t.key) || t.key.contains(normalized)) {
          return t.key;
        }
      }
    }
    return kServiceTypes.first.key;
  }

  void _removeItem(int index) {
    final entry = _items[index];
    final catalogId = entry.catalogId;
    setState(() {
      _items.removeAt(index);
      if (catalogId != null) _selectedCatalogIds.remove(catalogId);
    });
    entry.dispose();
  }

  void _removeFromCatalog(int catalogId, {bool showToast = true}) {
    final index = _items.indexWhere((e) => e.catalogId == catalogId);
    if (index >= 0) {
      _removeItem(index);
      if (showToast && mounted) {
        AppToast.show(context, 'Item dihapus dari list',
            type: ToastType.success);
      }
    }
  }

  void _addFromCatalog(ServiceItem item) {
    if (_selectedCatalogIds.contains(item.id)) return;
    
    showDialog(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: "Konfirmasi Tambah Layanan",
        description: "Apakah item layanan yang Anda tambahkan sudah sesuai?",
        confirmLabel: "Ya, Sesuai",
        customWidget: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF166534))),
              const SizedBox(height: 4),
              Text('${CurrencyFormatter.format(item.price)} / ${item.unit ?? 'item'}', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF15803D))),
            ],
          ),
        ),
        onConfirm: () {
          Navigator.pop(ctx);
          setState(() {
            _selectedCatalogIds.add(item.id);
            _items.add(_ItemEntry(
              catalogId: item.id,
              name: item.name,
              subItemName: null,
              itemDescription: null,
              description: item.category,
              notes: null,
              unitPrice: item.price,
              unit: item.unit,
              serviceType: _selectedServiceType,
              initialQty: 1,
            ));
          });
          AppToast.show(context, 'Item berhasil ditambahkan', type: ToastType.success);
        },
      ),
    );
  }

  double get _subtotal => _items.fold(0.0, (s, e) => s + e.subtotal);

  int get _totalPhysicalItems {
    int total = 0;
    for (final e in _items) {
      final u = e.unit?.toLowerCase() ?? '';
      final isArea = u.contains('m2') ||
          u.contains('m²') ||
          u == 'm' ||
          u.contains('meter') ||
          (e.areaSize != null && e.areaSize! > 0);
      if (isArea) {
        total += 1;
      } else {
        total += e.quantity.toInt();
      }
    }
    return total;
  }

  void _showSubmitConfirmation() {
    final isEditing = widget.job.finalItems.isNotEmpty ||
        widget.job.status == JobStatus.waitingFinalItems ||
        widget.job.status == JobStatus.invoiceGenerated ||
        widget.job.status == JobStatus.completed;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing
                ? 'Konfirmasi Pembaruan'
                : 'Konfirmasi Pengiriman Laporan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing
                    ? 'Final Item akan diperbarui dan otomatis memperbarui data yang telah dikirim ke Admin. Apakah Anda yakin ingin melanjutkan?'
                    : 'Pastikan semua item yang Anda input sudah benar. Laporan yang dikirim akan diproses oleh admin dan digunakan untuk pembuatan invoice tagihan kepada customer.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Item:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$_totalPhysicalItems item',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Tagihan:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(_finalTotal),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
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
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _submit();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isEditing ? 'Ya, Lanjutkan' : 'Kirim Laporan',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_items.isEmpty) return;
    final validItems = _items;

    setState(() => _isSubmitting = true);
    try {
      final payload = validItems.map((e) {
        final u = e.unit?.toLowerCase() ?? '';
        final isArea = u.contains('m2') ||
            u.contains('m²') ||
            u == 'm' ||
            u.contains('meter') ||
            (e.areaSize != null && e.areaSize! > 0);

        final map = <String, dynamic>{
          'service_item_id': e.catalogId ?? e.serviceItemId,
          'service_type': e.serviceType ??
              (widget.job.services.isNotEmpty ? widget.job.services.first : ''),
          'item_name': e.name.trim(),
          'sub_item_name': e.subItemName,
          'description': e.itemDescription,
          'unit': e.unit,
          'unit_price': e.unitPrice,
          'final_price': e.unitPrice,
          'subtotal': e.subtotal,
          'selected': true,
          'notes': e.notes ?? '',
        };

        if (isArea) {
          map['area_size'] = e.quantity;
        } else {
          map['quantity'] = e.quantity.toInt();
        }

        return map;
      }).toList();
      final notes = _notesCtrl.text.trim();
      final discountType = _selectedPercent > 0
          ? 'percentage'
          : (_discountAmount > 0 ? 'nominal' : null);
      final discountValue =
          _selectedPercent > 0 ? _selectedPercent : _discountAmount;

      await widget.onSubmit(
        payload,
        notes.isEmpty ? null : notes,
        discountType,
        discountValue,
        widget.job.minimumPayment ?? widget.job.downPayment,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // Error toast handled by caller
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogItemsProvider(_selectedServiceType));
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.93,
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
                    bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_showPrefilledBanner &&
                          widget.job.items.isNotEmpty) ...[
                        _buildPrefilledBanner(),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // ── Selected items ──────────────────────────────
                      _buildSectionHeader(
                        icon: Icons.shopping_bag_outlined,
                        label: AppStrings.sectionSelectedItems,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildSelectedItems(),

                      // ── Catalog accordion (collapsed by default) ────
                      const SizedBox(height: AppSpacing.md),
                      _buildCatalogAccordion(catalogAsync),

                      // ── Discount ─────────────────────────────────────
                      const SizedBox(height: AppSpacing.lg),
                      _buildDiscountSection(),

                      // ── DP ───────────────────────────────────────────
                      const SizedBox(height: AppSpacing.md),
                      _buildDpSection(),

                      // ── Notes ───────────────────────────────────────
                      const SizedBox(height: AppSpacing.lg),
                      _buildSectionHeader(
                        icon: Icons.notes_rounded,
                        label: AppStrings.sectionAdditionalNotes,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildNotesField(),

                      // ── Pricing ─────────────────────────────────────
                      const SizedBox(height: AppSpacing.lg),
                      _buildPricingSummary(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSubmitButton(),
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
                  AppStrings.finalItemsTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.job.customerName,
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

  // ── Pre-fill banner ───────────────────────────────────────────────────────

  Widget _buildPrefilledBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: const Color(0xFF6EE7B7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: Color(0xFF059669)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${widget.job.items.length} ${AppStrings.prefilledBannerSuffix}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF065F46),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: () => setState(() => _showPrefilledBanner = false),
            child: const Icon(Icons.close_rounded,
                size: 14, color: Color(0xFF059669)),
          ),
        ],
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required IconData icon,
    required String label,
    String? countText,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B8A78)),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B8A78),
            letterSpacing: 0.5,
          ),
        ),
        if (countText != null && countText.isNotEmpty && countText != '0') ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              countText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Service type chips ────────────────────────────────────────────────────

  Widget _buildServiceTypeChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: kServiceTypes.map((t) {
          final isSelected = _selectedServiceType == t.key;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () {
                if (isSelected) return;
                setState(() {
                  _selectedServiceType = t.key;
                  _searchQuery = '';
                  _searchCtrl.clear();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  t.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Widget _buildSearchField() {
    return TextField(
      controller: _searchCtrl,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: AppStrings.searchHint,
        hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13, color: AppColors.textHint),
        prefixIcon: const Icon(Icons.search_rounded,
            size: 18, color: AppColors.textHint),
        suffixIcon: _searchQuery.isNotEmpty
            ? GestureDetector(
                onTap: () => setState(() {
                  _searchQuery = '';
                  _searchCtrl.clear();
                }),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: AppColors.textHint),
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        fillColor: Colors.white,
      ),
      onChanged: (v) => setState(() => _searchQuery = v),
    );
  }

  // ── Catalog ───────────────────────────────────────────────────────────────

  Widget _buildCatalogBody(AsyncValue<List<ServiceItem>> async) {
    return async.when(
      loading: _buildCatalogLoading,
      error: (e, _) => _buildCatalogError(e),
      data: _buildCatalogItems,
    );
  }

  Widget _buildCatalogLoading() {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogError(Object error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 28, color: Color(0xFFEF4444)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.failedLoadCatalog,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            error.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: () =>
                ref.invalidate(catalogItemsProvider(_selectedServiceType)),
            icon: const Icon(Icons.refresh_rounded,
                size: 16, color: AppColors.primary),
            label: Text(
              AppStrings.tryAgain,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogItems(List<ServiceItem> allItems) {
    final q = _searchQuery.toLowerCase().trim();
    final filtered = q.isEmpty
        ? allItems
        : allItems.where((e) {
            return e.name.toLowerCase().contains(q) ||
                (e.category?.toLowerCase().contains(q) ?? false);
          }).toList();

    if (filtered.isEmpty) return _buildEmptyCatalog(q);

    final groups = <String, List<ServiceItem>>{};
    for (final item in filtered) {
      groups
          .putIfAbsent(item.category ?? AppStrings.otherCategory, () => [])
          .add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groups.entries) ...[
          _buildCategoryDivider(entry.key),
          ...entry.value.map(_buildCatalogTile),
        ],
      ],
    );
  }

  Widget _buildEmptyCatalog(String query) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Column(
        children: [
          Icon(
            query.isNotEmpty ? Icons.search_off_rounded : Icons.inbox_rounded,
            size: 32,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            query.isNotEmpty
                ? '${AppStrings.noMatchingItems}\n"$_searchQuery"'
                : AppStrings.noItemsForService,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textHint,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDivider(String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(children: [
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            category,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
      ]),
    );
  }

  Widget _buildCatalogTile(ServiceItem item) {
    final isSelected = _selectedCatalogIds.contains(item.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: GestureDetector(
        onTap: () {
          if (isSelected) {
            _removeFromCatalog(item.id);
          } else {
            _addFromCatalog(item);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF10B981)
                  : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.category != null)
                      Text(
                        item.category!,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                    Text(
                      item.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(item.price),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '/ ${item.unit ?? 'item'}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSelected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('check'),
                        size: 24,
                        color: Color(0xFF10B981),
                      )
                    : Container(
                        key: const ValueKey('add'),
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_rounded,
                            size: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Selected items ────────────────────────────────────────────────────────

  Widget _buildSelectedItems() {
    if (_items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            const Icon(Icons.shopping_bag_outlined,
                size: 32, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.noItemsSelected,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(
        _items.length,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _buildSelectedItemCard(i),
        ),
      ),
    );
  }

  Widget _buildSelectedItemCard(int index) {
    final item = _items[index];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name row + delete ─────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.description != null)
                      Text(
                        item.description!,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                    Text(
                      item.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () => _removeItem(index),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 15, color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Stepper + price + subtotal ────────────────────────────
          Row(
            children: [
              _buildQtyStepper(item, index),
              const SizedBox(width: 8),
              Text('×',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: AppColors.textHint)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  CurrencyFormatter.format(item.unitPrice) +
                      (item.unit != null ? '/${item.unit}' : ''),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Text(
                CurrencyFormatter.format(item.subtotal),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyStepper(_ItemEntry item, int index) {
    final canDecrement = item.quantity > 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepperBtn(
          Icons.remove_rounded,
          canDecrement ? () => setState(() => item.decrement()) : null,
        ),
        SizedBox(
          width: 70,
          child: TextField(
            controller: item.qtyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            textAlign: TextAlign.center,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              border: InputBorder.none,
            ),
          ),
        ),
        _stepperBtn(
          Icons.add_rounded,
          () => setState(() => item.increment()),
        ),
      ],
    );
  }

  Widget _stepperBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
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
          size: 14,
          color: onTap != null ? AppColors.textSecondary : AppColors.textHint,
        ),
      ),
    );
  }

  // ── Catalog accordion ─────────────────────────────────────────────────────

  Widget _buildCatalogAccordion(AsyncValue<List<ServiceItem>> catalogAsync) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showCatalog = !_showCatalog),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.addChangeItems,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.addItemsDesc,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showCatalog
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_showCatalog) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.layananFinal,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildServiceTypeChips(),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSearchField(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 300,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppSpacing.radiusCard),
                  bottomRight: Radius.circular(AppSpacing.radiusCard),
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                  child: _buildCatalogBody(catalogAsync),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Discount section ───────────────────────────────────────────────────────

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

  // ── DP section ────────────────────────────────────────────────────────────

  Widget _buildDpSection() {
    final minimumPayment = widget.job.minimumPayment ?? widget.job.downPayment;
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
            AppStrings.dpLabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F5),
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Text(
              '${AppStrings.rpPrefix} ${CurrencyFormatter.format(minimumPayment).replaceAll('Rp', '').trim()}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Notes ─────────────────────────────────────────────────────────────────

  Widget _buildNotesField() {
    return TextField(
      controller: _notesCtrl,
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
    );
  }

  // ── Pricing summary ───────────────────────────────────────────────────────

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
              AppStrings.subtotalLabel, CurrencyFormatter.format(subtotal)),
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
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: AppColors.textSecondary),
          ),
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

  // ── Submit ────────────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    final canSubmit = _items.isNotEmpty && !_isSubmitting;
    final isEditing = widget.job.finalItems.isNotEmpty ||
        widget.job.status == JobStatus.waitingFinalItems ||
        widget.job.status == JobStatus.invoiceGenerated ||
        widget.job.status == JobStatus.completed;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: canSubmit ? _showSubmitConfirmation : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withAlpha(100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                      isEditing
                          ? Icons.check_circle_outline
                          : Icons.send_rounded,
                      size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isEditing
                        ? 'Update Final Item'
                        : AppStrings.submitFinalReport,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Mutable item entry ────────────────────────────────────────────────────────

class _ItemEntry {
  _ItemEntry({
    this.catalogId,
    this.serviceItemId,
    required this.name,
    this.subItemName,
    this.itemDescription,
    this.description,
    this.notes,
    required this.unitPrice,
    this.unit,
    this.areaSize,
    this.serviceType,
    required double initialQty,
  }) : qtyController = TextEditingController(
          text: initialQty % 1 == 0
              ? initialQty.toInt().toString()
              : initialQty.toString(),
        );

  factory _ItemEntry.fromJobItem(JobItem item) => _ItemEntry(
        catalogId: int.tryParse(item.serviceItemId ?? ''),
        serviceItemId: int.tryParse(item.serviceItemId ?? ''),
        name: item.name,
        subItemName: item.subItemName,
        itemDescription: item.description,
        description: item.notes ?? item.description,
        notes: item.notes,
        unitPrice: item.price,
        unit: item.unit,
        areaSize: item.areaSize,
        serviceType: item.serviceType,
        initialQty: item.quantity,
      );

  final int? catalogId;
  final int? serviceItemId;
  final String name;
  final String? subItemName;
  final String? itemDescription;
  final double unitPrice;
  final String? description;
  final String? notes;
  final String? unit;
  final double? areaSize;
  final String? serviceType;
  final TextEditingController qtyController;

  double get quantity => double.tryParse(qtyController.text) ?? 0;
  double get subtotal => quantity * unitPrice;

  void increment() {
    final q = quantity + 1;
    qtyController.text = q % 1 == 0 ? q.toInt().toString() : q.toString();
  }

  void decrement() {
    final q = (quantity - 1).clamp(0.5, double.infinity);
    qtyController.text = q % 1 == 0 ? q.toInt().toString() : q.toString();
  }

  void dispose() {
    qtyController.dispose();
  }
}

// ── Thousand separator formatter ──────────────────────────────────────────────

class _ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final formatted = _fmt(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _fmt(String digits) {
    final buf = StringBuffer();
    final n = digits.length;
    for (var i = 0; i < n; i++) {
      if (i > 0 && (n - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}
