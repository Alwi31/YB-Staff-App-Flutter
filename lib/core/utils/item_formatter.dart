class ItemFormatter {
  static String formatQuantityLabel({
    required double quantity,
    double? areaSize,
    String? unit,
  }) {
    // 1. Determine the numeric value to display
    // If areaSize is explicitly provided and > 0, we can use it as the number.
    // Otherwise, use the quantity.
    final double valueToDisplay = (areaSize != null && areaSize > 0) ? areaSize : quantity;
    
    // Format quantity: remove .0 if it's a whole number
    final String numberStr = valueToDisplay.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    
    // 2. Determine the unit text
    String displayUnit = 'Item'; // Default
    
    if (unit != null && unit.trim().isNotEmpty) {
      displayUnit = _formatUnitText(unit);
    } else if (areaSize != null && areaSize > 0) {
      displayUnit = 'm²'; // Fallback if backend didn't send unit but sent areaSize
    }
    
    return '$numberStr $displayUnit';
  }

  static String _formatUnitText(String unit) {
    final lower = unit.trim().toLowerCase();
    if (lower == 'unit') return 'Unit';
    if (lower == 'item') return 'Item';
    if (lower == 'm2' || lower == 'm²' || lower == 'sqm') return 'm²';
    if (unit.trim().isEmpty) return 'Item';
    return unit.trim()[0].toUpperCase() + unit.trim().substring(1);
  }
}
