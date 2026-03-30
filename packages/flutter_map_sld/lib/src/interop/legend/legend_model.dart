import '../../model/color_map.dart';

/// A single legend entry derived from a [ColorMap].
class LegendEntry {
  const LegendEntry({
    required this.colorArgb,
    required this.quantity,
    required this.opacity,
    this.label,
  });

  /// Color as ARGB integer.
  final int colorArgb;

  /// The data value this entry represents.
  final double quantity;

  /// Opacity from 0.0 to 1.0.
  final double opacity;

  /// Human-readable label, if available.
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegendEntry &&
          colorArgb == other.colorArgb &&
          quantity == other.quantity &&
          opacity == other.opacity &&
          label == other.label;

  @override
  int get hashCode => Object.hash(colorArgb, quantity, opacity, label);
}

/// A color-quantity pair for building color scales.
class ColorScaleStop {
  const ColorScaleStop({
    required this.colorArgb,
    required this.quantity,
  });

  /// Color as ARGB integer.
  final int colorArgb;

  /// The data value at this stop.
  final double quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorScaleStop &&
          colorArgb == other.colorArgb &&
          quantity == other.quantity;

  @override
  int get hashCode => Object.hash(colorArgb, quantity);
}

/// Extracts legend entries from a [ColorMap].
///
/// Returns one [LegendEntry] per [ColorMapEntry], preserving order.
List<LegendEntry> extractLegend(ColorMap colorMap) => [
      for (final entry in colorMap.entries)
        LegendEntry(
          colorArgb: entry.colorArgb,
          quantity: entry.quantity,
          opacity: entry.opacity,
          label: entry.label,
        ),
    ];

/// Extracts a color scale (ordered color-quantity stops) from a [ColorMap].
///
/// The stops are sorted by quantity in ascending order, regardless of the
/// original entry order.
List<ColorScaleStop> extractColorScale(ColorMap colorMap) {
  final stops = [
    for (final entry in colorMap.entries)
      ColorScaleStop(
        colorArgb: entry.colorArgb,
        quantity: entry.quantity,
      ),
  ];
  stops.sort((a, b) => a.quantity.compareTo(b.quantity));
  return stops;
}
