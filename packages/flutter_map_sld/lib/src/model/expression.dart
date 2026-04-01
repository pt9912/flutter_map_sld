/// An OGC expression that can be evaluated against feature properties.
sealed class Expression {
  const Expression();

  /// Evaluates this expression against the given [properties].
  dynamic evaluate(Map<String, dynamic> properties);
}

/// A reference to a feature attribute by name.
final class PropertyName extends Expression {
  const PropertyName(this.name);

  /// The property/attribute name.
  final String name;

  @override
  dynamic evaluate(Map<String, dynamic> properties) => properties[name];

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PropertyName && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

/// A constant literal value.
final class Literal extends Expression {
  const Literal(this.value);

  /// The literal value (typically a String or num).
  final dynamic value;

  @override
  dynamic evaluate(Map<String, dynamic> properties) => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Literal && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

// ---------------------------------------------------------------------------
// Composite expressions (SE / GeoServer)
// ---------------------------------------------------------------------------

/// Concatenates the string representations of its child expressions.
final class Concatenate extends Expression {
  const Concatenate({required this.expressions});

  /// The child expressions to concatenate.
  final List<Expression> expressions;

  @override
  dynamic evaluate(Map<String, dynamic> properties) {
    final buf = StringBuffer();
    for (final e in expressions) {
      final v = e.evaluate(properties);
      if (v == null) return null;
      buf.write(v);
    }
    return buf.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Concatenate &&
          _expressionListEquals(expressions, other.expressions);

  @override
  int get hashCode => Object.hashAll(expressions);
}

/// Formats a numeric value using a pattern string.
///
/// Initial scope: simple decimal-place rounding (e.g. `#.##`).
/// Thousands grouping and full DecimalFormat compatibility are deferred.
final class FormatNumber extends Expression {
  const FormatNumber({required this.numericValue, required this.pattern});

  /// The expression producing the numeric value to format.
  final Expression numericValue;

  /// The format pattern (subset of Java DecimalFormat).
  final String pattern;

  @override
  dynamic evaluate(Map<String, dynamic> properties) {
    final v = numericValue.evaluate(properties);
    final n = v is num ? v : num.tryParse(v.toString());
    if (n == null) return null;
    return _applyDecimalPattern(n, pattern);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormatNumber &&
          numericValue == other.numericValue &&
          pattern == other.pattern;

  @override
  int get hashCode => Object.hash(numericValue, pattern);
}

/// Maps a continuous value to discrete categories via thresholds.
///
/// Semantics follow OGC SE `Categorize`:
/// `values[0]` applies when `lookupValue < thresholds[0]`,
/// `values[i]` applies when `thresholds[i-1] <= lookupValue < thresholds[i]`,
/// `values[last]` applies when `lookupValue >= thresholds[last]`.
final class Categorize extends Expression {
  const Categorize({
    required this.lookupValue,
    required this.thresholds,
    required this.values,
    this.fallbackValue,
  });

  /// The expression whose result is classified.
  final Expression lookupValue;

  /// Threshold boundaries (length N).
  final List<Expression> thresholds;

  /// Category values (length N + 1).
  final List<Expression> values;

  /// Optional fallback when the lookup value is null or non-numeric.
  final Expression? fallbackValue;

  @override
  dynamic evaluate(Map<String, dynamic> properties) {
    final raw = lookupValue.evaluate(properties);
    final v = raw is num ? raw : num.tryParse(raw?.toString() ?? '');
    if (v == null) return fallbackValue?.evaluate(properties);

    for (var i = 0; i < thresholds.length; i++) {
      final tRaw = thresholds[i].evaluate(properties);
      final t = tRaw is num ? tRaw : num.tryParse(tRaw?.toString() ?? '');
      if (t == null) return fallbackValue?.evaluate(properties);
      if (v < t) return values[i].evaluate(properties);
    }
    return values.last.evaluate(properties);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Categorize &&
          lookupValue == other.lookupValue &&
          _expressionListEquals(thresholds, other.thresholds) &&
          _expressionListEquals(values, other.values) &&
          fallbackValue == other.fallbackValue;

  @override
  int get hashCode => Object.hash(
        lookupValue,
        Object.hashAll(thresholds),
        Object.hashAll(values),
        fallbackValue,
      );
}

/// Interpolates between data points.
///
/// Supported modes per OGC SE 1.1: `linear` and `cubic`.
/// Cubic mode falls back to linear in this initial implementation.
final class Interpolate extends Expression {
  const Interpolate({
    required this.lookupValue,
    required this.dataPoints,
    this.mode = InterpolateMode.linear,
    this.fallbackValue,
  });

  /// The expression whose result is used for lookup.
  final Expression lookupValue;

  /// The interpolation data points (must be sorted by [InterpolationPoint.data]).
  final List<InterpolationPoint> dataPoints;

  /// Interpolation mode.
  final InterpolateMode mode;

  /// Optional fallback when lookup value is null or non-numeric.
  final Expression? fallbackValue;

  @override
  dynamic evaluate(Map<String, dynamic> properties) {
    final raw = lookupValue.evaluate(properties);
    final v = raw is num ? raw : num.tryParse(raw?.toString() ?? '');
    if (v == null) return fallbackValue?.evaluate(properties);
    if (dataPoints.isEmpty) return fallbackValue?.evaluate(properties);

    // Below first point.
    if (v <= dataPoints.first.data) {
      return dataPoints.first.value.evaluate(properties);
    }
    // Above last point.
    if (v >= dataPoints.last.data) {
      return dataPoints.last.value.evaluate(properties);
    }

    // Find the surrounding interval.
    for (var i = 0; i < dataPoints.length - 1; i++) {
      final lo = dataPoints[i];
      final hi = dataPoints[i + 1];
      if (v >= lo.data && v <= hi.data) {
        final loVal = lo.value.evaluate(properties);
        final hiVal = hi.value.evaluate(properties);
        if (loVal is num && hiVal is num) {
          final fraction = (hi.data - lo.data) == 0
              ? 0.0
              : (v - lo.data) / (hi.data - lo.data);
          return loVal + (hiVal - loVal) * fraction;
        }
        // Non-numeric values: return lower bound value.
        return loVal;
      }
    }
    return fallbackValue?.evaluate(properties);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Interpolate &&
          lookupValue == other.lookupValue &&
          mode == other.mode &&
          fallbackValue == other.fallbackValue &&
          _interpolationPointListEquals(dataPoints, other.dataPoints);

  @override
  int get hashCode => Object.hash(
        lookupValue,
        mode,
        fallbackValue,
        Object.hashAll(dataPoints),
      );
}

/// Remaps discrete input values to output values.
final class Recode extends Expression {
  const Recode({
    required this.lookupValue,
    required this.mappings,
    this.fallbackValue,
  });

  /// The expression whose result is looked up.
  final Expression lookupValue;

  /// The input→output mappings.
  final List<RecodeMapping> mappings;

  /// Optional fallback when no mapping matches.
  final Expression? fallbackValue;

  @override
  dynamic evaluate(Map<String, dynamic> properties) {
    final v = lookupValue.evaluate(properties);
    if (v == null) return fallbackValue?.evaluate(properties);
    for (final m in mappings) {
      final input = m.inputValue.evaluate(properties);
      if (v == input) return m.outputValue.evaluate(properties);
    }
    return fallbackValue?.evaluate(properties);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recode &&
          lookupValue == other.lookupValue &&
          fallbackValue == other.fallbackValue &&
          _recodeMappingListEquals(mappings, other.mappings);

  @override
  int get hashCode => Object.hash(
        lookupValue,
        fallbackValue,
        Object.hashAll(mappings),
      );
}

// ---------------------------------------------------------------------------
// Helper types
// ---------------------------------------------------------------------------

/// A data/value pair for [Interpolate].
final class InterpolationPoint {
  const InterpolationPoint({required this.data, required this.value});

  /// The numeric position on the lookup axis.
  final num data;

  /// The value at this position.
  final Expression value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterpolationPoint &&
          data == other.data &&
          value == other.value;

  @override
  int get hashCode => Object.hash(data, value);
}

/// Interpolation modes per OGC SE 1.1.
enum InterpolateMode { linear, cubic }

/// A single input→output mapping for [Recode].
final class RecodeMapping {
  const RecodeMapping({required this.inputValue, required this.outputValue});

  /// The input value to match.
  final Expression inputValue;

  /// The output value when matched.
  final Expression outputValue;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecodeMapping &&
          inputValue == other.inputValue &&
          outputValue == other.outputValue;

  @override
  int get hashCode => Object.hash(inputValue, outputValue);
}

// ---------------------------------------------------------------------------
// List equality helpers
// ---------------------------------------------------------------------------

bool _expressionListEquals(List<Expression> a, List<Expression> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _interpolationPointListEquals(
    List<InterpolationPoint> a, List<InterpolationPoint> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _recodeMappingListEquals(List<RecodeMapping> a, List<RecodeMapping> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// FormatNumber helpers
// ---------------------------------------------------------------------------

/// Applies a simple decimal-format pattern to a number.
///
/// Supports patterns like `#`, `#.#`, `#.##`, `0.00`.
/// Thousands grouping is not yet supported.
String _applyDecimalPattern(num value, String pattern) {
  // Count decimal places after the dot.
  final dotIndex = pattern.indexOf('.');
  if (dotIndex < 0) {
    return value.round().toString();
  }
  final decimals = pattern.length - dotIndex - 1;
  return value.toStringAsFixed(decimals);
}
