import '_equality.dart';
import '../parser/sld_parser.dart' as parser;
import 'issue.dart';
import 'layer.dart';
import 'raster_symbolizer.dart';

/// A parsed SLD/SE document.
class SldDocument {
  SldDocument({
    this.version,
    required List<SldLayer> layers,
  }) : layers = List.unmodifiable(layers);

  /// Parses an SLD/SE XML string.
  ///
  /// Returns an [SldParseResult] with the parsed document and any issues.
  /// Invalid XML is reported as an error issue; the document will be `null`.
  static SldParseResult parseXmlString(String xml) =>
      parser.parseSldXmlString(xml);

  /// Parses SLD/SE from raw bytes (UTF-8).
  ///
  /// Returns an [SldParseResult] with the parsed document and any issues.
  static SldParseResult parseBytes(List<int> bytes) =>
      parser.parseSldBytes(bytes);

  /// SLD version string (e.g. `"1.0.0"` or `"1.1.0"`).
  final String? version;

  /// Named layers in this document (unmodifiable).
  final List<SldLayer> layers;

  /// Convenience method: collects all [RasterSymbolizer] instances
  /// from all layers, styles, feature type styles, and rules.
  List<RasterSymbolizer> selectRasterSymbolizers() {
    final result = <RasterSymbolizer>[];
    for (final layer in layers) {
      for (final style in layer.styles) {
        for (final fts in style.featureTypeStyles) {
          for (final rule in fts.rules) {
            final rs = rule.rasterSymbolizer;
            if (rs != null) {
              result.add(rs);
            }
          }
        }
      }
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SldDocument &&
          version == other.version &&
          deepListEquals(layers, other.layers);

  @override
  int get hashCode => Object.hash(version, Object.hashAll(layers));
}

/// The result of parsing an SLD/SE XML document.
class SldParseResult {
  SldParseResult({
    this.document,
    List<SldParseIssue> issues = const [],
  }) : issues = List.unmodifiable(issues);

  /// The parsed document, or null if parsing failed with errors.
  final SldDocument? document;

  /// Issues encountered during parsing (unmodifiable).
  final List<SldParseIssue> issues;

  /// Whether any issue has severity [SldIssueSeverity.error].
  bool get hasErrors =>
      issues.any((issue) => issue.severity == SldIssueSeverity.error);
}
