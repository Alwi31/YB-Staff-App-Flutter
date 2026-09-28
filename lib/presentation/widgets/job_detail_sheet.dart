import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yb_staff_app/core/constants/app_strings.dart';
import 'package:yb_staff_app/core/theme/app_colors.dart';
import 'package:yb_staff_app/core/theme/app_spacing.dart';
import 'package:yb_staff_app/core/utils/currency_formatter.dart';
import 'package:yb_staff_app/core/utils/date_formatter.dart';
import 'package:yb_staff_app/core/utils/item_formatter.dart';
import 'package:yb_staff_app/domain/entities/job.dart';
import 'package:yb_staff_app/domain/entities/job_item.dart';

class JobDetailSheet extends StatefulWidget {
  const JobDetailSheet({super.key, required this.job});

  final Job job;

  static Future<void> show(BuildContext context, Job job) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobDetailSheet(job: job),
    );
  }

  @override
  State<JobDetailSheet> createState() => _JobDetailSheetState();
}

class _JobDetailSheetState extends State<JobDetailSheet> {
  late bool _isEstimasiExpanded;

  @override
  void initState() {
    super.initState();
    _isEstimasiExpanded = widget.job.finalItems.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSheet),
            ),
          ),
          child: Column(
            children: [
              // ── Drag handle ───────────────────────────────────────────
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, 0, AppSpacing.md, AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.jobDetailTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          )
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textSecondary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              // ── Scrollable body ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrdererSection(context),
                      _buildSiteContactSection(context),
                      _buildLocationSection(),
                      _buildStatusSection(),
                      _buildNotesSection(),
                      _buildPhotosSection(),
                      _buildPricingSection(),
                      const SizedBox(height: AppSpacing.xxl),
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

  // ── Section builders ──────────────────────────────────────────────────────

  Widget _buildOrdererSection(BuildContext context) {
    return _section(
      title: AppStrings.sectionOrderer,
      children: [
        _ordererInfoRow(AppStrings.labelOrderer, widget.job.customerName,
            widget.job.customerStatus),
        _phoneRow(
            context, AppStrings.labelOrdererPhone, widget.job.customerPhone),
      ],
    );
  }

  Widget _buildSiteContactSection(BuildContext context) {
    final contactName = (widget.job.siteContactName != null &&
            widget.job.siteContactName!.trim().isNotEmpty)
        ? widget.job.siteContactName!.trim()
        : widget.job.customerName;
    final contactPhone = (widget.job.siteContactPhone != null &&
            widget.job.siteContactPhone!.trim().isNotEmpty)
        ? widget.job.siteContactPhone!.trim()
        : widget.job.customerPhone;
    final normalizedPhone =
        widget.job.siteContactNormalizedPhone ?? widget.job.customerPhone;

    return _section(
      title: AppStrings.sectionSiteContact,
      children: [
        _infoRow(AppStrings.labelSiteContactName, contactName),
        _phoneRow(
          context,
          AppStrings.labelSiteContactPhone,
          contactPhone,
          normalizedPhone: normalizedPhone,
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return _section(
      title: AppStrings.sectionLocation,
      children: [
        if (widget.job.region != null)
          _infoRow(AppStrings.labelRegion, widget.job.region!),
        _infoRow(AppStrings.labelAddress, widget.job.address),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: InkWell(
            onTap: _openMaps,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 1.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.openNavigation,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.open_in_new_rounded,
                      size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openMaps() async {
    final link = widget.job.mapsLink;
    final uri = link != null && link.isNotEmpty
        ? Uri.parse(link)
        : Uri.parse(
            'https://maps.google.com/?q=${Uri.encodeComponent(widget.job.address)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildStatusSection() {
    final hour = widget.job.scheduledAt.hour;
    final session = widget.job.scheduleTimeLabel ??
        (hour < 12
            ? AppStrings.sessionPagi
            : hour < 15
                ? AppStrings.sessionSiang
                : AppStrings.sessionSore);
    final scheduleText =
        '${DateFormatter.toFull(widget.job.scheduledAt)} - ${widget.job.scheduleTime ?? DateFormatter.toTime(widget.job.scheduledAt)} WIB - $session';

    return _section(
      title: AppStrings.sectionStatusSchedule,
      children: [
        _infoRow(AppStrings.labelSchedule, scheduleText),
        _infoRow(AppStrings.labelStatus, widget.job.status.displayName),
        if (widget.job.power != null)
          _infoRow(AppStrings.labelPower, widget.job.power!),
        _infoRow('Staff', widget.job.assignedStaffName ?? '-'),
      ],
    );
  }

  Widget _buildNotesSection() {
    final hasHourlyNotes = widget.job.isHourly &&
        widget.job.hourlyReport?.notes != null &&
        widget.job.hourlyReport!.notes!.isNotEmpty;
    final hasGeneralNotes =
        widget.job.notes != null && widget.job.notes!.isNotEmpty;

    return _section(
      title: AppStrings.sectionNotes,
      children: [
        if (hasHourlyNotes) ...[
          Text(
            widget.job.hourlyReport!.notes!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
          if (hasGeneralNotes) const SizedBox(height: 12),
        ],
        if (hasGeneralNotes) ...[
          Text(
            widget.job.notes!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
        ],
        if (!hasHourlyNotes && !hasGeneralNotes)
          Text(
            AppStrings.noNotes,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textHint,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    if (widget.job.photos.isEmpty) {
      return const SizedBox.shrink();
    }
    return _section(
      title: AppStrings.sectionPhotos,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemCount: widget.job.photos.length,
          itemBuilder: (_, i) => ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            child: Image.network(
              widget.job.photos[i],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFF3F4F6),
                child: const Icon(Icons.broken_image_outlined,
                    color: AppColors.textHint),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    final job = widget.job;

    final hasFinalItems = job.finalItems.isNotEmpty &&
        (job.status == JobStatus.waitingFinalItems ||
            job.status == JobStatus.invoiceGenerated ||
            job.status == JobStatus.completed);

    final subtotal = job.subtotalPrice > 0
        ? job.subtotalPrice
        : (hasFinalItems ? job.finalItems : job.items)
            .fold(0.0, (s, i) => s + i.subtotal);
    final discount = job.discount;
    final total =
        job.finalTotalPrice > 0 ? job.finalTotalPrice : subtotal - discount;
    final downPayment = job.downPayment;
    final outstanding = job.outstandingBalance;

    final discountLabel = _discountLabel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (job.isHourly && job.hourlyDetails != null) _buildHourlySummary(),

        // ── 1. Estimasi Item ───────────────────────────────────────────────
        if (job.items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F5),
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              ),
              child: job.finalItems.isNotEmpty
                  ? Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(
                          'Estimasi Item',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6B8A78),
                            letterSpacing: 0.5,
                          ),
                        ),
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl),
                        childrenPadding: const EdgeInsets.only(
                            left: AppSpacing.xl,
                            right: AppSpacing.xl,
                            bottom: AppSpacing.xl),
                        initiallyExpanded: _isEstimasiExpanded,
                        onExpansionChanged: (val) =>
                            setState(() => _isEstimasiExpanded = val),
                        children: job.items.isEmpty
                            ? [
                                Text(
                                  AppStrings.noItems,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppColors.textHint,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              ]
                            : job.items.map((item) => _itemRow(item)).toList(),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimasi Item',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6B8A78),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (job.items.isEmpty)
                            Text(
                              AppStrings.noItems,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.textHint,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            ...job.items.map((item) => _itemRow(item)),
                        ],
                      ),
                    ),
            ),
          ),

        // ── 2. Final Item (Hanya jika staff sudah input final item) ───────
        if (hasFinalItems)
          _section(
            title: 'Final Item',
            children: [
              ...job.finalItems.map((item) => _itemRow(item)),
            ],
          ),

        // ── 3. Total Invoice ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F9F6),
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Invoice',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B8A78),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _priceRow(AppStrings.subtotalLabel,
                    CurrencyFormatter.format(subtotal)),
                _priceRow(discountLabel, CurrencyFormatter.format(discount),
                    isDiscount: true),
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1, color: Color(0xFFDDE7E1)),
                const SizedBox(height: AppSpacing.md),
                // Total akhir
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.totalFinal,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    Text(CurrencyFormatter.format(total),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ],
                ),
                if (downPayment > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _priceRow(AppStrings.downPaymentLabel,
                      CurrencyFormatter.format(downPayment)),
                ],
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: Color(0xFFDDE7E1)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.remainingBill,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      outstanding > 0
                          ? CurrencyFormatter.format(outstanding)
                          : AppStrings.lunas,
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
          ),
        ),
      ],
    );
  }

  String _discountLabel() {
    if (widget.job.discountType == 'percentage' &&
        widget.job.discountValue > 0) {
      return '${AppStrings.discountLabel} (${widget.job.discountValue.toStringAsFixed(widget.job.discountValue % 1 == 0 ? 0 : 1)}%)';
    }
    return AppStrings.discountLabel;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _section({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B8A78),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {double labelWidth = 80}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textHint,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ordererInfoRow(String label, String value, String? status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textHint,
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (status != null && status.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: status.toUpperCase() == 'NEW'
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _phoneRow(
    BuildContext context,
    String label,
    String phone, {
    String? normalizedPhone,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textHint,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _showContactOptions(context, phone, normalizedPhone),
              child: Text(
                phone,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Contact actions (WhatsApp / call) ───────────────────────────────────────

  void _showContactOptions(
    BuildContext context,
    String phone,
    String? normalizedPhone,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading:
                    const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                title: Text(
                  AppStrings.chatWhatsapp,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _launchWhatsApp(phone, normalizedPhone);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.call_rounded, color: AppColors.primary),
                title: Text(
                  AppStrings.callPhone,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _launchPhoneCall(phone);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchWhatsApp(String phone, String? normalizedPhone) async {
    final target = normalizedPhone ?? _normalizePhone(phone);
    final appUri = Uri.parse('whatsapp://send?phone=$target');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
      return;
    }
    final webUri = Uri.parse('https://wa.me/$target');
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchPhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static String _normalizePhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    }
    return digits;
  }

  Widget _itemRow(JobItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.description != null)
                  Text(
                    '${item.description} - ${ItemFormatter.formatQuantityLabel(quantity: item.quantity, areaSize: item.areaSize, unit: item.unit)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            CurrencyFormatter.format(item.subtotal),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B8A78),
            ),
          ),
          Text(
            isDiscount ? '- $amount' : amount,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlySummary() {
    final job = widget.job;
    final hourly = job.hourlyDetails!;
    final report = job.hourlyReport;
    final tarif = hourly.hourlyRateSnapshot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          title: 'Estimasi Jam Kerja',
          children: [
            _infoRow(
                'Tarif', '${CurrencyFormatter.format(tarif)} / jam / cleaner',
                labelWidth: 130),
            const SizedBox(height: AppSpacing.sm),
            _infoRow('Durasi', '${hourly.plannedDurationHours} Jam',
                labelWidth: 130),
            _infoRow('Cleaner', '${hourly.plannedCleanerCount} Orang',
                labelWidth: 130),
            const Divider(height: AppSpacing.xl, color: Color(0xFFE5E7EB)),
            if (report != null) ...[
              Text(
                'FINAL LAPORAN CLEANING',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B8A78),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _infoRow('Durasi Aktual', '${report.actualDurationHours} Jam',
                  labelWidth: 130),
              _infoRow('Cleaner Aktual', '${report.actualCleanerCount} Orang',
                  labelWidth: 130),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Aktual',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(report.finalTotalPrice),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Estimasi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(hourly.estimatedTotal),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
        if (report == null && job.status != JobStatus.completed)
          Padding(
            padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.xs)
                .copyWith(bottom: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Laporan jam kerja aktual belum dikirimkan oleh Staff pengerjaan.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
