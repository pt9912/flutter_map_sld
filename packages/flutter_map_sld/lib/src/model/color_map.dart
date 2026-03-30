import '_equality.dart';

/// The interpolation method used by a [ColorMap].
enum ColorMapType {
  /// Continuous color interpolation between entries.
  ramp,

  /// Discrete color blocks defined by quantity thresholds.
  ///
  /// This is a GeoServer extension to the OGC standard.
  intervals,

  /// Exact-match mapping from quantity to color.
  exactValues,
}

/// A mapping from quantity values to colors, used in `RasterSymbolizer`.
class ColorMap {
  ColorMap({
    required this.type,
    required List<ColorMapEntry> entries,
  }) : entries = List.unmodifiable(entries);

  /// The interpolation method.
  final ColorMapType type;

  /// Ordered list of color-quantity mappings (unmodifiable).
  final List<ColorMapEntry> entries;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorMap &&
          type == other.type &&
          deepListEquals(entries, other.entries);

  @override
  int get hashCode => Object.hash(type, Object.hashAll(entries));
}

/// A single entry in a [ColorMap].
class ColorMapEntry {
  const ColorMapEntry({
    required this.colorArgb,
    required this.quantity,
    required this.opacity,
    this.label,
  });

  /// Color as ARGB integer (e.g. `0xFF00FF00` for opaque green).
  final int colorArgb;

  /// The data value this entry maps to.
  final double quantity;

  /// Opacity from 0.0 (fully transparent) to 1.0 (fully opaque).
  final double opacity;

  /// Optional human-readable label for legends.
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorMapEntry &&
          colorArgb == other.colorArgb &&
          quantity == other.quantity &&
          opacity == other.opacity &&
          label == other.label;

  @override
  int get hashCode => Object.hash(colorArgb, quantity, opacity, label);
}
