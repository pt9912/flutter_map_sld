import 'package:xml/xml.dart';

import '../../model/issue.dart';
import '../../model/rule.dart';
import '../xml_helpers.dart';
import 'raster_symbolizer_parser.dart';
import 'vector_symbolizer_parser.dart';

/// Parses a `<Rule>` element.
Rule parseRule(XmlElement element, List<SldParseIssue> issues, String path) {
  final name = childText(element, 'Name');
  final minScale = _childDouble(element, 'MinScaleDenominator');
  final maxScale = _childDouble(element, 'MaxScaleDenominator');

  final rsEl = findChild(element, 'RasterSymbolizer');
  final rasterSymbolizer = rsEl != null
      ? parseRasterSymbolizer(rsEl, issues, '$path/RasterSymbolizer')
      : null;

  final psEl = findChild(element, 'PointSymbolizer');
  final pointSymbolizer = psEl != null
      ? parsePointSymbolizer(psEl, issues, '$path/PointSymbolizer')
      : null;

  final lsEl = findChild(element, 'LineSymbolizer');
  final lineSymbolizer = lsEl != null
      ? parseLineSymbolizer(lsEl, issues, '$path/LineSymbolizer')
      : null;

  final polsEl = findChild(element, 'PolygonSymbolizer');
  final polygonSymbolizer = polsEl != null
      ? parsePolygonSymbolizer(polsEl, issues, '$path/PolygonSymbolizer')
      : null;

  return Rule(
    name: name,
    minScaleDenominator: minScale,
    maxScaleDenominator: maxScale,
    rasterSymbolizer: rasterSymbolizer,
    pointSymbolizer: pointSymbolizer,
    lineSymbolizer: lineSymbolizer,
    polygonSymbolizer: polygonSymbolizer,
  );
}

double? _childDouble(XmlElement parent, String localName) {
  final text = childText(parent, localName);
  if (text == null) return null;
  return double.tryParse(text);
}
