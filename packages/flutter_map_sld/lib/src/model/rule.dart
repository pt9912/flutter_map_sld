import 'package:gml4dart/gml4dart.dart';

import 'filter.dart';
import 'line_symbolizer.dart';
import 'point_symbolizer.dart';
import 'polygon_symbolizer.dart';
import 'raster_symbolizer.dart';
import 'text_symbolizer.dart';

/// A styling rule within a `FeatureTypeStyle`.
///
/// Rules may be scale-dependent, filter-dependent, and contain one or more
/// symbolizers.
class Rule {
  const Rule({
    this.name,
    this.filter,
    this.minScaleDenominator,
    this.maxScaleDenominator,
    this.rasterSymbolizer,
    this.pointSymbolizer,
    this.lineSymbolizer,
    this.polygonSymbolizer,
    this.textSymbolizer,
  });

  /// Optional rule name.
  final String? name;

  /// Optional OGC filter for property-based rule selection.
  final Filter? filter;

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

  /// Text symbolizer, if present.
  final TextSymbolizer? textSymbolizer;

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

  /// Whether this rule applies to the given [properties] and optional
  /// [scaleDenominator] and feature [geometry].
  /// Combines filter and scale checks.
  bool appliesTo(
    Map<String, dynamic> properties, {
    double? scaleDenominator,
    GmlGeometry? geometry,
  }) {
    if (scaleDenominator != null && !appliesAtScale(scaleDenominator)) {
      return false;
    }
    final f = filter;
    if (f != null && !f.evaluate(properties, geometry: geometry)) return false;
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rule &&
          name == other.name &&
          filter == other.filter &&
          minScaleDenominator == other.minScaleDenominator &&
          maxScaleDenominator == other.maxScaleDenominator &&
          rasterSymbolizer == other.rasterSymbolizer &&
          pointSymbolizer == other.pointSymbolizer &&
          lineSymbolizer == other.lineSymbolizer &&
          polygonSymbolizer == other.polygonSymbolizer &&
          textSymbolizer == other.textSymbolizer;

  @override
  int get hashCode => Object.hash(
        name,
        filter,
        minScaleDenominator,
        maxScaleDenominator,
        rasterSymbolizer,
        pointSymbolizer,
        lineSymbolizer,
        polygonSymbolizer,
        textSymbolizer,
      );
}
