import 'package:gml4dart/gml4dart.dart';

import '../eval/spatial_ops.dart';
import 'expression.dart';

/// An OGC filter that can be evaluated against feature properties.
///
/// The optional `geometry` parameter on `evaluate()` supplies the feature's
/// geometry for spatial filter evaluation. Non-spatial filters ignore it.
sealed class Filter {
  const Filter();

  /// Evaluates this filter against the given [properties] and optional
  /// feature [geometry].
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry});
}

// ---------------------------------------------------------------------------
// Comparison operators
// ---------------------------------------------------------------------------

/// Base for binary comparison filters.
sealed class ComparisonFilter extends Filter {
  const ComparisonFilter({
    required this.expression1,
    required this.expression2,
  });

  /// Left-hand expression.
  final Expression expression1;

  /// Right-hand expression.
  final Expression expression2;
}

/// True when both expressions evaluate to equal values.
final class PropertyIsEqualTo extends ComparisonFilter {
  const PropertyIsEqualTo({
    required super.expression1,
    required super.expression2,
  });

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    final a = expression1.evaluate(properties);
    final b = expression2.evaluate(properties);
    if (a == null || b == null) return false;
    return a == b;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyIsEqualTo &&
          expression1 == other.expression1 &&
          expression2 == other.expression2;

  @override
  int get hashCode => Object.hash(expression1, expression2);
}

/// True when both expressions evaluate to different values.
final class PropertyIsNotEqualTo extends ComparisonFilter {
  const PropertyIsNotEqualTo({
    required super.expression1,
    required super.expression2,
  });

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    final a = expression1.evaluate(properties);
    final b = expression2.evaluate(properties);
    if (a == null || b == null) return false;
    return a != b;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyIsNotEqualTo &&
          expression1 == other.expression1 &&
          expression2 == other.expression2;

  @override
  int get hashCode => Object.hash(expression1, expression2);
}

/// True when expression1 is numerically or lexicographically less than expression2.
final class PropertyIsLessThan extends ComparisonFilter {
  const PropertyIsLessThan({
    required super.expression1,
    required super.expression2,
  });

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    final cmp = _compareNum(expression1, expression2, properties);
    return cmp < 0 && cmp != _incompatible;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyIsLessThan &&
          expression1 == other.expression1 &&
          expression2 == other.expression2;

  @override
  int get hashCode => Object.hash(expression1, expression2);
}

/// True when expression1 is numerically or lexicographically greater than expression2.
final class PropertyIsGreaterThan extends ComparisonFilter {
  const PropertyIsGreaterThan({
    required super.expression1,
    required super.expression2,
  });

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    final cmp = _compareNum(expression1, expression2, properties);
    return cmp > 0 && cmp != _incompatible;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyIsGreaterThan &&
          expression1 == other.expression1 &&
          expression2 == other.expression2;

  @override
  int get hashCode => Object.hash(expression1, expression2);
}

/// True when expression1 is less than or equal to expression2.
final class PropertyIsLessThanOrEqualTo extends ComparisonFilter {
  const PropertyIsLessThanOrEqualTo({
    required super.expression1,
    required super.expression2,
  });

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    final cmp = _compareNum(expression1, expression2, properties);
    return cmp <= 0 && cmp != _incompatible;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyIsLessThanOrEqualTo &&
          expression1 == other.expression1 &&
          expression2 == other.expression2;

  @override
  int get hashCode => Object.hash(expression1, expression2);
}

/// True when expression1 is greater than or equal to expression2.
final class PropertyIsGreaterThanOrEqualTo extends ComparisonFilter {
  const PropertyIsGreaterThanOrEqualTo({
    required super.expression1,
    required super.expression2,
  });

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    final cmp = _compareNum(expression1, expression2, properties);
    return cmp >= 0 && cmp != _incompatible;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyIsGreaterThanOrEqualTo &&
          expression1 == other.expression1 &&
          expression2 == other.expression2;

  @override
  int get hashCode => Object.hash(expression1, expression2);
}

// ---------------------------------------------------------------------------
// Between, Like, Null
// ---------------------------------------------------------------------------

/// True when [expression] falls between [lowerBoundary] and [upperBoundary] (inclusive).
final class PropertyIsBetween extends Filter {
  const PropertyIsBetween({
    required this.expression,
    required this.lowerBoundary,
    required this.upperBoundary,
  });

  /// The expression to test.
  final Expression expression;

  /// Lower boundary (inclusive).
  final Expression lowerBoundary;

  /// Upper boundary (inclusive).
  final Expression upperBoundary;

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    final v = expression.evaluate(properties);
    final lo = lowerBoundary.evaluate(properties);
    final hi = upperBoundary.evaluate(properties);
    if (v is! num || lo is! num || hi is! num) return false;
    return v >= lo && v <= hi;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyIsBetween &&
          expression == other.expression &&
          lowerBoundary == other.lowerBoundary &&
          upperBoundary == other.upperBoundary;

  @override
  int get hashCode => Object.hash(expression, lowerBoundary, upperBoundary);
}

/// True when [expression] matches [pattern] using wildcard/single-char syntax.
final class PropertyIsLike extends Filter {
  const PropertyIsLike({
    required this.expression,
    required this.pattern,
    this.wildCard = '*',
    this.singleChar = '?',
    this.escapeChar = '\\',
  });

  /// The expression to match.
  final Expression expression;

  /// The pattern string containing wildcard and single-char placeholders.
  final String pattern;

  /// Character representing zero or more characters (default `*`).
  final String wildCard;

  /// Character representing exactly one character (default `?`).
  final String singleChar;

  /// Escape character for literal wildcards (default `\`).
  final String escapeChar;

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    final v = expression.evaluate(properties);
    if (v is! String) return false;
    final regex = _toRegex(pattern, wildCard, singleChar, escapeChar);
    return regex.hasMatch(v);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyIsLike &&
          expression == other.expression &&
          pattern == other.pattern &&
          wildCard == other.wildCard &&
          singleChar == other.singleChar &&
          escapeChar == other.escapeChar;

  @override
  int get hashCode =>
      Object.hash(expression, pattern, wildCard, singleChar, escapeChar);
}

/// True when [expression] evaluates to `null`.
final class PropertyIsNull extends Filter {
  const PropertyIsNull({required this.expression});

  /// The expression to test for null.
  final Expression expression;

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) =>
      expression.evaluate(properties) == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyIsNull && expression == other.expression;

  @override
  int get hashCode => expression.hashCode;
}

// ---------------------------------------------------------------------------
// Logical operators
// ---------------------------------------------------------------------------

/// Logical AND: true when all child [filters] evaluate to true.
final class And extends Filter {
  const And({required this.filters});

  /// The child filters (all must match).
  final List<Filter> filters;

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) =>
      filters.every((f) => f.evaluate(properties, geometry: geometry));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is And && _filterListEquals(filters, other.filters);

  @override
  int get hashCode => Object.hashAll(filters);
}

/// Logical OR: true when any child [filters] evaluates to true.
final class Or extends Filter {
  const Or({required this.filters});

  /// The child filters (at least one must match).
  final List<Filter> filters;

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) =>
      filters.any((f) => f.evaluate(properties, geometry: geometry));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Or && _filterListEquals(filters, other.filters);

  @override
  int get hashCode => Object.hashAll(filters);
}

/// Logical NOT: negates the result of [filter].
final class Not extends Filter {
  const Not({required this.filter});

  /// The filter to negate.
  final Filter filter;

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) =>
      !filter.evaluate(properties, geometry: geometry);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Not && filter == other.filter;

  @override
  int get hashCode => filter.hashCode;
}

// ---------------------------------------------------------------------------
// Spatial filters
// ---------------------------------------------------------------------------

/// Base for spatial filter operators.
sealed class SpatialFilter extends Filter {
  const SpatialFilter({this.propertyName, required this.geometry});

  /// Optional geometry property name. Null means the default geometry.
  final String? propertyName;

  /// The reference geometry from the SLD document.
  final GmlGeometry geometry;
}

/// Bounding-box filter: true when the feature geometry intersects the envelope.
final class BBox extends SpatialFilter {
  const BBox({super.propertyName, required GmlEnvelope envelope})
      : super(geometry: envelope);

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    if (geometry == null) return false;
    return envelopeIntersects(
        geometryEnvelope(geometry), this.geometry as GmlEnvelope);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BBox &&
          propertyName == other.propertyName &&
          geometry == other.geometry;

  @override
  int get hashCode => Object.hash(propertyName, geometry);
}

/// True when the feature geometry intersects the reference [geometry].
final class Intersects extends SpatialFilter {
  const Intersects({super.propertyName, required super.geometry});

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    if (geometry == null) return false;
    return geometryIntersects(geometry, this.geometry);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Intersects &&
          propertyName == other.propertyName &&
          geometry == other.geometry;

  @override
  int get hashCode => Object.hash(propertyName, geometry);
}

/// True when the feature geometry is fully within the reference [geometry].
final class Within extends SpatialFilter {
  const Within({super.propertyName, required super.geometry});

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    if (geometry == null) return false;
    return geometryWithin(geometry, this.geometry);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Within &&
          propertyName == other.propertyName &&
          geometry == other.geometry;

  @override
  int get hashCode => Object.hash(propertyName, geometry);
}

/// True when the feature geometry fully contains the reference [geometry].
final class Contains extends SpatialFilter {
  const Contains({super.propertyName, required super.geometry});

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    if (geometry == null) return false;
    return geometryWithin(this.geometry, geometry);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contains &&
          propertyName == other.propertyName &&
          geometry == other.geometry;

  @override
  int get hashCode => Object.hash(propertyName, geometry);
}

/// True when the feature geometry touches the reference [geometry].
final class Touches extends SpatialFilter {
  const Touches({super.propertyName, required super.geometry});

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    if (geometry == null) return false;
    // Simplified: uses envelope intersection as approximation.
    return envelopeIntersects(
        geometryEnvelope(geometry), geometryEnvelope(this.geometry));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Touches &&
          propertyName == other.propertyName &&
          geometry == other.geometry;

  @override
  int get hashCode => Object.hash(propertyName, geometry);
}

/// True when the feature geometry crosses the reference [geometry].
final class Crosses extends SpatialFilter {
  const Crosses({super.propertyName, required super.geometry});

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    if (geometry == null) return false;
    return geometryIntersects(geometry, this.geometry);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Crosses &&
          propertyName == other.propertyName &&
          geometry == other.geometry;

  @override
  int get hashCode => Object.hash(propertyName, geometry);
}

/// Named `SpatialOverlaps` to avoid collision with Flutter's `Overlaps`.
final class SpatialOverlaps extends SpatialFilter {
  const SpatialOverlaps({super.propertyName, required super.geometry});

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    if (geometry == null) return false;
    return geometryIntersects(geometry, this.geometry);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpatialOverlaps &&
          propertyName == other.propertyName &&
          geometry == other.geometry;

  @override
  int get hashCode => Object.hash(propertyName, geometry);
}

/// True when the feature geometry does not intersect the reference [geometry].
final class Disjoint extends SpatialFilter {
  const Disjoint({super.propertyName, required super.geometry});

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    if (geometry == null) return false;
    return !geometryIntersects(geometry, this.geometry);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Disjoint &&
          propertyName == other.propertyName &&
          geometry == other.geometry;

  @override
  int get hashCode => Object.hash(propertyName, geometry);
}

// ---------------------------------------------------------------------------
// Distance-based spatial filters
// ---------------------------------------------------------------------------

/// Base for distance-based spatial filters.
sealed class DistanceFilter extends SpatialFilter {
  const DistanceFilter({
    super.propertyName,
    required super.geometry,
    required this.distance,
    this.units = '',
  });

  /// Distance threshold in coordinate units.
  final double distance;

  /// Distance units (informational; CRS handling is the caller's concern).
  final String units;
}

/// True when the feature geometry is within [distance] of the reference [geometry].
final class DWithin extends DistanceFilter {
  const DWithin({
    super.propertyName,
    required super.geometry,
    required super.distance,
    super.units,
  });

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    if (geometry == null) return false;
    return geometryDistance(geometry, this.geometry) <= distance;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DWithin &&
          propertyName == other.propertyName &&
          geometry == other.geometry &&
          distance == other.distance &&
          units == other.units;

  @override
  int get hashCode => Object.hash(propertyName, geometry, distance, units);
}

/// True when the feature geometry is beyond [distance] from the reference [geometry].
final class Beyond extends DistanceFilter {
  const Beyond({
    super.propertyName,
    required super.geometry,
    required super.distance,
    super.units,
  });

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    if (geometry == null) return false;
    return geometryDistance(geometry, this.geometry) > distance;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Beyond &&
          propertyName == other.propertyName &&
          geometry == other.geometry &&
          distance == other.distance &&
          units == other.units;

  @override
  int get hashCode => Object.hash(propertyName, geometry, distance, units);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Sentinel for incompatible types in numeric comparison.
const _incompatible = -999999;

int _compareNum(
    Expression a, Expression b, Map<String, dynamic> properties) {
  final va = a.evaluate(properties);
  final vb = b.evaluate(properties);
  if (va is num && vb is num) return va.compareTo(vb);
  if (va is String && vb is String) return va.compareTo(vb);
  return _incompatible;
}

RegExp _toRegex(
    String pattern, String wildCard, String singleChar, String escapeChar) {
  final buf = StringBuffer('^');
  for (var i = 0; i < pattern.length; i++) {
    if (pattern.startsWith(escapeChar, i) &&
        i + escapeChar.length < pattern.length) {
      i += escapeChar.length;
      buf.write(RegExp.escape(pattern[i]));
    } else if (pattern.startsWith(wildCard, i)) {
      buf.write('.*');
      i += wildCard.length - 1;
    } else if (pattern.startsWith(singleChar, i)) {
      buf.write('.');
      i += singleChar.length - 1;
    } else {
      buf.write(RegExp.escape(pattern[i]));
    }
  }
  buf.write(r'$');
  return RegExp(buf.toString());
}

bool _filterListEquals(List<Filter> a, List<Filter> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
