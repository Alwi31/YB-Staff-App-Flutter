import 'package:yb_staff_app/domain/entities/invoice_summary.dart';

class InvoiceSummaryModel extends InvoiceSummary {
  const InvoiceSummaryModel({
    super.invoiceCode,
    required super.grandTotal,
    required super.downPayment,
    required super.isPaid,
    required super.outstandingBalance,
    super.waStatus,
  });

  factory InvoiceSummaryModel.fromJson(Map<String, dynamic> json) {
    return InvoiceSummaryModel(
      invoiceCode: json['invoice_code'] as String?,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      downPayment: (json['down_payment'] as num?)?.toDouble() ?? 0.0,
      isPaid: json['is_paid'] as bool? ?? false,
      outstandingBalance:
          (json['outstanding_balance'] as num?)?.toDouble() ?? 0.0,
      waStatus: json['wa_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_code': invoiceCode,
      'grand_total': grandTotal,
      'down_payment': downPayment,
      'is_paid': isPaid,
      'outstanding_balance': outstandingBalance,
      'wa_status': waStatus,
    };
  }

  factory InvoiceSummaryModel.fromEntity(InvoiceSummary entity) {
    return InvoiceSummaryModel(
      invoiceCode: entity.invoiceCode,
      grandTotal: entity.grandTotal,
      downPayment: entity.downPayment,
      isPaid: entity.isPaid,
      outstandingBalance: entity.outstandingBalance,
      waStatus: entity.waStatus,
    );
  }
}
