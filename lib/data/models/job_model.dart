import 'package:yb_staff_app/data/models/job_item_model.dart';
import 'package:yb_staff_app/domain/entities/job.dart';
import 'package:yb_staff_app/data/models/hourly_details_model.dart';
import 'package:yb_staff_app/data/models/hourly_report_model.dart';
import 'package:yb_staff_app/data/models/invoice_summary_model.dart';

class JobModel {
  const JobModel({
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
  final String status;
  final List<JobItemModel> items;
  final List<JobItemModel> finalItems;
  final List<String> services;
  final String? region;
  final String? power;
  final bool siteContactIsOrderer;
  final String? siteContactName;
  final String? siteContactPhone;
  final String? siteContactNormalizedPhone;
  final bool isHourly;
  final HourlyDetailsModel? hourlyDetails;
  final HourlyReportModel? hourlyReport;
  final String? customerStatus;
  final bool finalItemsEditable;
  final String? scheduleTimeLabel;
  final String? scheduleTime;
  final InvoiceSummaryModel? invoiceSummary;
  final double discount;
  final String? discountType;
  final double discountValue;
  final double downPayment;
  final double outstandingBalance;
  final double subtotalPrice;
  final double finalTotalPrice;
  final double? minimumPayment;
  final double grandTotal;
  final List<String> photos;
  final String? notes;
  final String? orderCode;
  final String? mapsLink;
  final String? whatsappUrl;

  factory JobModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    final customerMap =
        customer is Map<String, dynamic> ? customer : <String, dynamic>{};

    return JobModel(
      id: _parseInt(json['id']) ?? 0,
      assignedStaffId: _parseInt(json['assigned_staff_id']),
      assignedStaffName: _parseString(json['assigned_staff_name']),
      orderCode: _parseString(json['order_code']),
      customerName: _parseString(customerMap['name']) ?? '',
      customerPhone: _parseString(customerMap['phone']) ?? '',
      address: _parseString(customerMap['address']) ?? '',
      mapsLink: _parseString(customerMap['maps_link']),
      whatsappUrl: _parseString(customerMap['whatsapp_url']),
      scheduledAt: _parseDate(json['schedule_at']) ?? DateTime.now(),
      status: _parseString(json['status']) ?? 'assigned',
      items: _parseItems(json['estimated_items']),
      finalItems: _parseItems(json['final_items']),
      services: _parseStringList(json['service_types']),
      region: _parseString(json['region']),
      power: _parseString(json['electricity_power']),
      discount: _parseDouble(json['discount_amount']) ?? 0.0,
      discountType: _parseString(json['discount_type']),
      discountValue: _parseDouble(json['discount_value']) ?? 0.0,
      downPayment: _parseDouble(json['down_payment']) ?? 0.0,
      outstandingBalance: _parseDouble(json['outstanding_balance']) ?? 0.0,
      subtotalPrice: _parseDouble(json['subtotal_price']) ?? 0.0,
      finalTotalPrice: _parseDouble(json['final_total_price']) ?? 0.0,
      photos: _parsePhotos(json['photos']),
      notes: _parseString(json['notes']),
      siteContactIsOrderer: _parseBool(json['site_contact_is_orderer']) ?? true,
      siteContactName: _parseString(json['site_contact_name']),
      siteContactPhone: _parseString(json['site_contact_phone']),
      siteContactNormalizedPhone:
          _parseString(json['site_contact_normalized_phone']),
      isHourly: _parseBool(json['is_hourly']) ?? false,
      hourlyDetails: json['hourly_details'] != null
          ? HourlyDetailsModel.fromJson(
              json['hourly_details'] as Map<String, dynamic>)
          : null,
      hourlyReport: json['hourly_report'] != null
          ? HourlyReportModel.fromJson(
              json['hourly_report'] as Map<String, dynamic>)
          : null,
      minimumPayment: _parseDouble(json['minimum_payment']),
      grandTotal: _parseDouble(json['grand_total']) ??
          _parseDouble(json['final_total_price']) ??
          0.0,
      customerStatus: _parseString(customerMap['customer_status']),
      finalItemsEditable: _parseBool(json['final_items_editable']) ?? false,
      scheduleTimeLabel: _parseString(json['schedule_time_label']),
      scheduleTime: _parseString(json['schedule_time']),
      invoiceSummary: json['invoice_summary'] != null
          ? InvoiceSummaryModel.fromJson(json['invoice_summary'] as Map<String, dynamic>)
          : null,
    );
  }

  // ── Defensive parsers ─────────────────────────────────────────────────────

  static String? _parseString(dynamic v) => v is String ? v : v?.toString();

  static bool? _parseBool(dynamic v) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return null;
  }

  static int? _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static List<String> _parseStringList(dynamic v) {
    if (v is! List) return [];
    return v.whereType<String>().toList();
  }

  static List<JobItemModel> _parseItems(dynamic v) {
    if (v is! List) return [];
    final result = <JobItemModel>[];
    for (final e in v) {
      if (e is Map<String, dynamic>) {
        try {
          result.add(JobItemModel.fromJson(e));
        } catch (_) {}
      }
    }
    return result;
  }

  static List<String> _parsePhotos(dynamic v) {
    if (v is! List) return [];
    final result = <String>[];
    for (final e in v) {
      if (e is String && e.isNotEmpty) {
        result.add(e);
      } else if (e is Map<String, dynamic>) {
        final url = e['url'] ?? e['path'] ?? e['file_url'];
        if (url is String && url.isNotEmpty) result.add(url);
      }
    }
    return result;
  }

  // ── To entity ─────────────────────────────────────────────────────────────

  Job toEntity() => Job(
        id: id,
        assignedStaffId: assignedStaffId,
        assignedStaffName: assignedStaffName,
        customerName: customerName,
        customerPhone: customerPhone,
        address: address,
        scheduledAt: scheduledAt,
        status: _parseStatus(status),
        items: items.map((e) => e.toEntity()).toList(),
        finalItems: finalItems.map((e) => e.toEntity()).toList(),
        services: services,
        region: region,
        power: power,
        discount: discount,
        discountType: discountType,
        discountValue: discountValue,
        downPayment: downPayment,
        outstandingBalance: outstandingBalance,
        subtotalPrice: subtotalPrice,
        finalTotalPrice: finalTotalPrice,
        photos: photos,
        notes: notes,
        orderCode: orderCode,
        mapsLink: mapsLink,
        whatsappUrl: whatsappUrl,
        siteContactIsOrderer: siteContactIsOrderer,
        siteContactName: siteContactName,
        siteContactPhone: siteContactPhone,
        siteContactNormalizedPhone: siteContactNormalizedPhone,
        isHourly: isHourly,
        hourlyDetails: hourlyDetails?.toEntity(),
        hourlyReport: hourlyReport?.toEntity(),
        minimumPayment: minimumPayment,
        grandTotal: grandTotal,
        customerStatus: customerStatus,
        finalItemsEditable: finalItemsEditable,
        scheduleTimeLabel: scheduleTimeLabel,
        scheduleTime: scheduleTime,
        invoiceSummary: invoiceSummary,
      );

  static JobStatus _parseStatus(String status) {
    switch (status) {
      case 'started':
      case 'in_progress':
        return JobStatus.inProgress;
      case 'waiting_final_items':
        return JobStatus.waitingFinalItems;
      case 'invoice_generated':
        return JobStatus.invoiceGenerated;
      case 'completed':
        return JobStatus.completed;
      case 'canceled':
      case 'cancelled':
        return JobStatus.canceled;
      default:
        return JobStatus.assigned;
    }
  }
}
