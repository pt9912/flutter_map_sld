/// Severity levels for parse and validation issues.
enum SldIssueSeverity {
  /// A problem that prevents meaningful use of the result.
  error,

  /// A potential problem that does not prevent use but should be reviewed.
  warning,

  /// Informational note, e.g. an unsupported vendor extension was encountered.
  info,
}

/// Gemeinsame Basis für alle Issues (Dart 3 sealed class).
///
/// [location] ist kontextabhängig:
/// - In [SldParseIssue]: XPath-ähnlicher Pfad zum betroffenen XML-Knoten
///   (z.B. `"/StyledLayerDescriptor/NamedLayer[1]/UserStyle/…/ColorMap"`)
/// - In [SldValidationIssue]: Modellpfad zum betroffenen Domain-Objekt
///   (z.B. `"layers[0].styles[0].featureTypeStyles[0].rules[0].rasterSymbolizer.colorMap"`)
sealed class SldIssue {
  const SldIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.location,
  });

  /// Severity of this issue.
  final SldIssueSeverity severity;

  /// Machine-readable issue code (e.g. `"invalid-opacity"`).
  final String code;

  /// Human-readable description.
  final String message;

  /// Context-dependent location string. See class documentation.
  final String? location;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SldIssue &&
          runtimeType == other.runtimeType &&
          severity == other.severity &&
          code == other.code &&
          message == other.message &&
          location == other.location;

  @override
  int get hashCode => Object.hash(runtimeType, severity, code, message, location);
}

/// An issue encountered during XML parsing.
final class SldParseIssue extends SldIssue {
  const SldParseIssue({
    required super.severity,
    required super.code,
    required super.message,
    super.location,
  });
}

/// An issue encountered during model validation.
final class SldValidationIssue extends SldIssue {
  const SldValidationIssue({
    required super.severity,
    required super.code,
    required super.message,
    super.location,
  });
}
