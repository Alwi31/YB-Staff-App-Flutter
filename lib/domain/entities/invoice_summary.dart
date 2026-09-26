class InvoiceSummary {
  final String? invoiceCode;
  final double grandTotal;
  final double downPayment;
  final bool isPaid;
  final double outstandingBalance;
  final String? waStatus;

  const InvoiceSummary({
    this.invoiceCode,
    required this.grandTotal,
    required this.downPayment,
    required this.isPaid,
    required this.outstandingBalance,
    this.waStatus,
  });
}
