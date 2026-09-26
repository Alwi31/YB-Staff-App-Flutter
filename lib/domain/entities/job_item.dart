class JobItem {
  const JobItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.description,
    this.areaSize,
    this.length,
    this.width,
    this.unit,
    this.serviceType,
    this.subItemName,
    this.serviceItemId,
    this.notes,
  });

  final int id;
  final String name;
  final double quantity;
  final double price;
  final double subtotal;
  final String? description;
  final double? areaSize;
  final double? length;
  final double? width;
  final String? unit;
  final String? serviceType;
  final String? subItemName;
  final String? serviceItemId;
  final String? notes;

  JobItem copyWith({
    int? id,
    String? name,
    double? quantity,
    double? price,
    double? subtotal,
    String? description,
    double? areaSize,
    double? length,
    double? width,
    String? unit,
    String? serviceType,
    String? subItemName,
    String? serviceItemId,
    String? notes,
  }) {
    return JobItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      subtotal: subtotal ?? this.subtotal,
      description: description ?? this.description,
      areaSize: areaSize ?? this.areaSize,
      length: length ?? this.length,
      width: width ?? this.width,
      unit: unit ?? this.unit,
      serviceType: serviceType ?? this.serviceType,
      subItemName: subItemName ?? this.subItemName,
      serviceItemId: serviceItemId ?? this.serviceItemId,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          quantity == other.quantity &&
          price == other.price;

  @override
  int get hashCode => Object.hash(id, name, quantity, price);
}
