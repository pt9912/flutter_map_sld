import 'raster_symbolizer.dart';

/// A styling rule within a `FeatureTypeStyle`.
///
/// Rules may be scale-dependent and contain one or more symbolizers.
/// In v1, only [RasterSymbolizer] is supported.
class Rule {
  const Rule({
    this.name,
    this.minScaleDenominator,
    this.maxScaleDenominator,
    this.rasterSymbolizer,
  });

  /// Optional rule name.
  final String? name;

  /// Minimum scale denominator for this rule to apply.
  final double? minScaleDenominator;

  /// Maximum scale denominator for this rule to apply.
  final double? maxScaleDenominator;

  /// Raster symbolizer, if present.
  final RasterSymbolizer? rasterSymbolizer;

  /// Whether this rule applies at the given [scaleDenominator].
  ///
  /// Returns `true` if no scale filter is set, or if [scaleDenominator] falls
  /// within the range. Bounds follow OGC convention: inclusive lower bound,
  /// exclusive upper bound — i.e. `min <= scale < max`.
  bool appliesAtScale(double scaleDenominator) {
    final min = minScaleDenominator;
    final max = maxScaleDenominator;
    if (min != null && scaleDenominator < min) return false;
    if (max != null && scaleDenominator >= max) return false;
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rule &&
          name == other.name &&
          minScaleDenominator == other.minScaleDenominator &&
          maxScaleDenominator == other.maxScaleDenominator &&
          rasterSymbolizer == other.rasterSymbolizer;

  @override
  int get hashCode => Object.hash(
        name,
        minScaleDenominator,
        maxScaleDenominator,
        rasterSymbolizer,
      );
}
