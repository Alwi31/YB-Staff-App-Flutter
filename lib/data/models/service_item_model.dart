import 'package:yb_staff_app/domain/entities/service_item.dart';

class ServiceItemModel {
  const ServiceItemModel({
    required this.id,
    required this.name,
    this.category,
    required this.price,
    this.unit,
  });

  final int id;
  final String name;
  final String? category;
  final double price;
  final String? unit;

  /// Parses a single item object nested inside a category.
  ///
  /// Response shape:
  /// ```json
  /// {
  ///   "id": 10,
  ///   "name": "Divan + Headboard Super King (2x2m)",
  ///   "unit_type": "item",
  ///   "price": 250000,
  ///   "prices": [{ "service_type": "leather_revive", "price": 250000 }]
  /// }
  /// ```
  factory ServiceItemModel.fromItemJson(
    Map<String, dynamic> json,
    String categoryName, {
    String? forServiceType,
  }) {
    // Base price
    double price = (json['price'] as num?)?.toDouble() ?? 0.0;

    // Override with service-type specific price if available
    final prices = json['prices'];
    if (prices is List && forServiceType != null && forServiceType.isNotEmpty) {
      for (final p in prices) {
        if (p is Map<String, dynamic> && p['service_type'] == forServiceType) {
          price = (p['price'] as num?)?.toDouble() ?? price;
          break;
        }
      }
    }

    return ServiceItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? json['item_name'] as String? ?? '',
      category: categoryName.isEmpty ? null : categoryName,
      price: price,
      unit: json['unit_type'] as String? ?? json['unit'] as String?,
    );
  }

  ServiceItem toEntity() => ServiceItem(
        id: id,
        name: name,
        category: category,
        price: price,
        unit: unit,
      );
}
