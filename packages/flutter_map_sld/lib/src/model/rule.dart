import 'line_symbolizer.dart';
import 'point_symbolizer.dart';
import 'polygon_symbolizer.dart';
import 'raster_symbolizer.dart';

/// A styling rule within a `FeatureTypeStyle`.
///
/// Rules may be scale-dependent and contain one or more symbolizers.
class Rule {
  const Rule({
    this.name,
    this.minScaleDenominator,
    this.maxScaleDenominator,
    this.rasterSymbolizer,
    this.pointSymbolizer,
    this.lineSymbolizer,
    this.polygonSymbolizer,
  });

  /// Optional rule name.
  final String? name;

  /// Minimum scale denominator for this rule to apply.
  final double? minScaleDenominator;

  /// Maximum scale denominator for this rule to apply.
  final double? maxScaleDenominator;

  /// Raster symbolizer, if present.
  final RasterSymbolizer? rasterSymbolizer;

  /// Point symbolizer, if present.
  final PointSymbolizer? pointSymbolizer;

  /// Line symbolizer, if present.
  final LineSymbolizer? lineSymbolizer;

  /// Polygon symbolizer, if present.
  final PolygonSymbolizer? polygonSymbolizer;

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
          rasterSymbolizer == other.rasterSymbolizer &&
          pointSymbolizer == other.pointSymbolizer &&
          lineSymbolizer == other.lineSymbolizer &&
          polygonSymbolizer == other.polygonSymbolizer;

  @override
  int get hashCode => Object.hash(
        name,
        minScaleDenominator,
        maxScaleDenominator,
        rasterSymbolizer,
        pointSymbolizer,
        lineSymbolizer,
        polygonSymbolizer,
      );
}
