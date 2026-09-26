import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yb_staff_app/core/constants/api_constants.dart';
import 'package:yb_staff_app/data/models/service_item_model.dart';
import 'package:yb_staff_app/domain/entities/service_item.dart';
import 'package:yb_staff_app/presentation/providers/auth_provider.dart';

/// All 4 service types supported by the system.
const kServiceTypes = <({String key, String label})>[
  (key: 'deep_vacuum', label: 'HydroVacuum Plus'),
  (key: 'hydrovacuum', label: 'HydroVacuum'),
  (key: 'premium_dry_wash', label: 'Premium Dry Wash'),
  (key: 'essential_dry_wash', label: 'Essential Dry Wash'),
  (key: 'leather_revive', label: 'Leather Revive'),
  (key: 'disinfeksi', label: 'Disinfeksi'),
  (key: 'general_cleaning', label: 'General Cleaning'),
  (key: 'daily_cleaning', label: 'Daily Cleaning'),
  (key: 'add_on', label: 'Add On'),
];

/// Returns the display label for a service type key.
String serviceTypeLabel(String key) {
  for (final t in kServiceTypes) {
    if (t.key == key) return t.label;
  }
  return key;
}

/// Fetch and flatten catalog items for a given service type key.
///
/// API response shape:
/// ```json
/// { "data": [{ "id": 3, "name": "Headboard / Divan",
///   "items": [{ "id": 10, "name": "...", "unit_type": "item",
///     "price": 250000, "prices": [{ "service_type": "leather_revive", "price": 250000 }]
///   }]
/// }] }
/// ```
final catalogItemsProvider = FutureProvider.autoDispose
    .family<List<ServiceItem>, String>((ref, serviceType) async {
  final client = ref.watch(apiClientProvider);

  final response = await client.get(
    ApiConstants.serviceItems,
    queryParams: {'service_type': serviceType},
  );

  final raw = response['data'];
  final categories = raw is List ? raw : <dynamic>[];

  final result = <ServiceItem>[];
  for (final cat in categories) {
    if (cat is! Map<String, dynamic>) continue;
    final categoryName = cat['name'] as String? ?? '';
    final items = cat['items'];
    if (items is! List) continue;

    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      try {
        result.add(
          ServiceItemModel.fromItemJson(
            item,
            categoryName,
            forServiceType: serviceType,
          ).toEntity(),
        );
      } catch (_) {}
    }
  }
  return result;
});
