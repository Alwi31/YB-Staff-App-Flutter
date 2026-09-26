import 'package:yb_staff_app/domain/entities/job_item.dart';
import 'package:yb_staff_app/domain/entities/hourly_details.dart';
import 'package:yb_staff_app/domain/entities/hourly_report.dart';
import 'package:yb_staff_app/domain/entities/invoice_summary.dart';

enum JobStatus {
  assigned,
  inProgress,
  waitingFinalItems,
  invoiceGenerated,
  completed,
  canceled;

  String get displayName {
    switch (this) {
      case JobStatus.assigned:
        return 'Ditugaskan';
      case JobStatus.inProgress:
        return 'Sedang Dikerjakan';
      case JobStatus.waitingFinalItems:
        return 'Menunggu Verifikasi';
      case JobStatus.invoiceGenerated:
        return 'Invoice Dibuat';
      case JobStatus.completed:
        return 'Selesai';
      case JobStatus.canceled:
        return 'Dibatalkan';
    }
  }

  String get apiValue {
    switch (this) {
      case JobStatus.assigned:
        return 'assigned';
      case JobStatus.inProgress:
        return 'started';
      case JobStatus.waitingFinalItems:
        return 'waiting_final_items';
      case JobStatus.invoiceGenerated:
        return 'invoice_generated';
      case JobStatus.completed:
        return 'completed';
      case JobStatus.canceled:
        return 'canceled';
    }
  }
}

class Job {
  const Job({
    required this.id,
    this.assignedStaffId,
    this.assignedStaffName,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.scheduledAt,
    required this.status,
    required this.items,
    this.finalItems = const [],
    this.services = const [],
    this.region,
    this.power,
    this.discount = 0.0,
    this.discountType,
    this.discountValue = 0.0,
    this.downPayment = 0.0,
    this.outstandingBalance = 0.0,
    this.subtotalPrice = 0.0,
    this.finalTotalPrice = 0.0,
    this.photos = const [],
    this.notes,
    this.orderCode,
    this.mapsLink,
    this.whatsappUrl,
    this.siteContactIsOrderer = true,
    this.siteContactName,
    this.siteContactPhone,
    this.siteContactNormalizedPhone,
    this.isHourly = false,
    this.hourlyDetails,
    this.hourlyReport,
    this.minimumPayment,
    this.grandTotal = 0.0,
    this.customerStatus,
    this.finalItemsEditable = false,
    this.scheduleTimeLabel,
    this.scheduleTime,
    this.invoiceSummary,
  });

  final int id;
  final int? assignedStaffId;
  final String? assignedStaffName;
  final String customerName;
  final String customerPhone;
  final String address;
  final DateTime scheduledAt;
  final JobStatus status;
  final List<JobItem> items;
  final List<JobItem> finalItems;
  final List<String> services;
  final String? region;
  final String? power;

  // ── Site contact (orang di lokasi) ──────────────────────────────────────────
  final bool siteContactIsOrderer;
  final String? siteContactName;
  final String? siteContactPhone;
  final String? siteContactNormalizedPhone;

  // ── Hourly ────────────────────────────────────────────────────────────────
  final bool isHourly;
  final HourlyDetails? hourlyDetails;
  final HourlyReport? hourlyReport;

  // ── Extras ────────────────────────────────────────────────────────────────
  final String? customerStatus;
  final bool finalItemsEditable;
  final String? scheduleTimeLabel;
  final String? scheduleTime;
  final InvoiceSummary? invoiceSummary;

  // ── Pricing ───────────────────────────────────────────────────────────────
  final double discount; // discount_amount (Rp)
  final String? discountType; // 'percentage' | 'fixed' | null
  final double discountValue; // raw value: e.g. 10 for 10% or 50000 for fixed
  final double downPayment; // down_payment
  final double outstandingBalance; // outstanding_balance
  final double subtotalPrice; // subtotal_price from API
  final double finalTotalPrice; // final_total_price from API
  final double? minimumPayment;
  final double grandTotal;

  final List<String> photos;
  final String? notes;
  final String? orderCode;
  final String? mapsLink;
  final String? whatsappUrl;

  double get estimatedTotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get finalItemsTotal =>
      finalItems.fold(0.0, (sum, item) => sum + item.subtotal);

  Job copyWith({
    int? id,
    int? assignedStaffId,
    String? assignedStaffName,
    String? customerName,
    String? customerPhone,
    String? address,
    DateTime? scheduledAt,
    JobStatus? status,
    List<JobItem>? items,
    List<JobItem>? finalItems,
    List<String>? services,
    String? region,
    String? power,
    double? discount,
    String? discountType,
    double? discountValue,
    double? downPayment,
    double? outstandingBalance,
    double? subtotalPrice,
    double? finalTotalPrice,
    List<String>? photos,
    String? notes,
    String? orderCode,
    String? mapsLink,
    String? whatsappUrl,
    bool? siteContactIsOrderer,
    String? siteContactName,
    String? siteContactPhone,
    String? siteContactNormalizedPhone,
    bool? isHourly,
    HourlyDetails? hourlyDetails,
    HourlyReport? hourlyReport,
    double? minimumPayment,
    double? grandTotal,
    String? customerStatus,
    bool? finalItemsEditable,
    String? scheduleTimeLabel,
    String? scheduleTime,
    InvoiceSummary? invoiceSummary,
  }) {
    return Job(
      id: id ?? this.id,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      address: address ?? this.address,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      items: items ?? this.items,
      finalItems: finalItems ?? this.finalItems,
      services: services ?? this.services,
      region: region ?? this.region,
      power: power ?? this.power,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      downPayment: downPayment ?? this.downPayment,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      subtotalPrice: subtotalPrice ?? this.subtotalPrice,
      finalTotalPrice: finalTotalPrice ?? this.finalTotalPrice,
      photos: photos ?? this.photos,
      notes: notes ?? this.notes,
      orderCode: orderCode ?? this.orderCode,
      mapsLink: mapsLink ?? this.mapsLink,
      whatsappUrl: whatsappUrl ?? this.whatsappUrl,
      siteContactIsOrderer: siteContactIsOrderer ?? this.siteContactIsOrderer,
      siteContactName: siteContactName ?? this.siteContactName,
      siteContactPhone: siteContactPhone ?? this.siteContactPhone,
      siteContactNormalizedPhone:
          siteContactNormalizedPhone ?? this.siteContactNormalizedPhone,
      isHourly: isHourly ?? this.isHourly,
      hourlyDetails: hourlyDetails ?? this.hourlyDetails,
      hourlyReport: hourlyReport ?? this.hourlyReport,
      minimumPayment: minimumPayment ?? this.minimumPayment,
      grandTotal: grandTotal ?? this.grandTotal,
      customerStatus: customerStatus ?? this.customerStatus,
      finalItemsEditable: finalItemsEditable ?? this.finalItemsEditable,
      scheduleTimeLabel: scheduleTimeLabel ?? this.scheduleTimeLabel,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      invoiceSummary: invoiceSummary ?? this.invoiceSummary,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Job &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, status);
}
