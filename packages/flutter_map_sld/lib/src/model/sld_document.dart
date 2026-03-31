import 'dart:typed_data';

import '../parser/sld_parser.dart' as parser;
import '_equality.dart';
import 'issue.dart';
import 'layer.dart';
import 'line_symbolizer.dart';
import 'matched_rule.dart';
import 'point_symbolizer.dart';
import 'polygon_symbolizer.dart';
import 'raster_symbolizer.dart';
import 'rule.dart';
import 'text_symbolizer.dart';

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

  /// Parses SLD/SE from an asynchronous byte stream (UTF-8).
  ///
  /// This is a convenience wrapper that collects all chunks from [byteStream]
  /// and then delegates to [parseBytes]. It does **not** perform incremental
  /// XML parsing — use it for API ergonomics, not for reducing peak memory
  /// on very large documents.
  static Future<SldParseResult> parseAsyncStream(
      Stream<List<int>> byteStream) async {
    final chunks = await byteStream.toList();
    final totalLength = chunks.fold<int>(0, (sum, c) => sum + c.length);
    final bytes = Uint8List(totalLength);
    var offset = 0;
    for (final chunk in chunks) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return parseBytes(bytes);
  }

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

  /// Like [selectRasterSymbolizers], but only includes symbolizers from rules
  /// that apply at the given [scaleDenominator] (see [Rule.appliesAtScale]).
  List<RasterSymbolizer> selectRasterSymbolizersAtScale(
      double scaleDenominator) {
    final result = <RasterSymbolizer>[];
    for (final layer in layers) {
      for (final style in layer.styles) {
        for (final fts in style.featureTypeStyles) {
          for (final rule in fts.rules) {
            if (!rule.appliesAtScale(scaleDenominator)) continue;
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

  /// Collects all [PointSymbolizer] instances from all rules.
  List<PointSymbolizer> selectPointSymbolizers() =>
      _collectSymbolizers((rule) => rule.pointSymbolizer);

  /// Collects all [LineSymbolizer] instances from all rules.
  List<LineSymbolizer> selectLineSymbolizers() =>
      _collectSymbolizers((rule) => rule.lineSymbolizer);

  /// Collects all [PolygonSymbolizer] instances from all rules.
  List<PolygonSymbolizer> selectPolygonSymbolizers() =>
      _collectSymbolizers((rule) => rule.polygonSymbolizer);

  /// Collects all [TextSymbolizer] instances from all rules.
  List<TextSymbolizer> selectTextSymbolizers() =>
      _collectSymbolizers((rule) => rule.textSymbolizer);

  /// Returns all rules that match the given [properties] and optional
  /// [scaleDenominator], wrapped in [MatchedRule] with full context.
  ///
  /// Rule order is preserved (drawing order semantics).
  List<MatchedRule> selectMatchingRules(
    Map<String, dynamic> properties, {
    double? scaleDenominator,
  }) {
    final result = <MatchedRule>[];
    for (final layer in layers) {
      for (final style in layer.styles) {
        for (final fts in style.featureTypeStyles) {
          for (final rule in fts.rules) {
            if (rule.appliesTo(properties,
                scaleDenominator: scaleDenominator)) {
              result.add(MatchedRule(
                layer: layer,
                style: style,
                featureTypeStyle: fts,
                rule: rule,
              ));
            }
          }
        }
      }
    }
    return result;
  }

  List<T> _collectSymbolizers<T>(T? Function(Rule) extract) {
    final result = <T>[];
    for (final layer in layers) {
      for (final style in layer.styles) {
        for (final fts in style.featureTypeStyles) {
          for (final rule in fts.rules) {
            final s = extract(rule);
            if (s != null) {
              result.add(s);
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
