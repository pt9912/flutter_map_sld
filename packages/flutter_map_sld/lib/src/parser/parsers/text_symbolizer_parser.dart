import 'package:xml/xml.dart';

import '../../model/issue.dart';
import '../../model/text_symbolizer.dart';
import '../xml_helpers.dart';
import 'expression_parser.dart';
import 'vector_symbolizer_parser.dart';

/// Parses a `<TextSymbolizer>` element.
TextSymbolizer parseTextSymbolizer(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  // Label — first expression child of <Label>
  final labelEl = findChild(element, 'Label');
  final label = labelEl != null
      ? parseFirstExpression(labelEl, issues, '$path/Label')
      : null;

  // Font
  final fontEl = findChild(element, 'Font');
  final font = fontEl != null ? _parseFont(fontEl, issues, '$path/Font') : null;

  // Fill (text color)
  final fillEl = findChild(element, 'Fill');
  final fill = fillEl != null ? parseFill(fillEl, issues, '$path/Fill') : null;

  // Halo
  final haloEl = findChild(element, 'Halo');
  final halo = haloEl != null ? _parseHalo(haloEl, issues, '$path/Halo') : null;

  // LabelPlacement
  final placementEl = findChild(element, 'LabelPlacement');
  final labelPlacement = placementEl != null
      ? _parseLabelPlacement(placementEl, issues, '$path/LabelPlacement')
      : null;

  return TextSymbolizer(
    label: label,
    font: font,
    fill: fill,
    halo: halo,
    labelPlacement: labelPlacement,
  );
}

Font _parseFont(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  String? family;
  String? style;
  String? weight;
  double? size;

  for (final param in findChildren(element, 'CssParameter')) {
    final name = stringAttr(param, 'name');
    final value = param.innerText.trim();
    switch (name) {
      case 'font-family':
        family = value;
      case 'font-style':
        style = value;
      case 'font-weight':
        weight = value;
      case 'font-size':
        size = double.tryParse(value);
    }
  }

  for (final param in findChildren(element, 'SvgParameter')) {
    final name = stringAttr(param, 'name');
    final value = param.innerText.trim();
    switch (name) {
      case 'font-family':
        family ??= value;
      case 'font-style':
        style ??= value;
      case 'font-weight':
        weight ??= value;
      case 'font-size':
        size ??= double.tryParse(value);
    }
  }

  return Font(family: family, style: style, weight: weight, size: size);
}

Halo _parseHalo(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final radiusText = childText(element, 'Radius');
  final radius = radiusText != null ? double.tryParse(radiusText) : null;

  final fillEl = findChild(element, 'Fill');
  final fill = fillEl != null ? parseFill(fillEl, issues, '$path/Fill') : null;

  return Halo(radius: radius, fill: fill);
}

LabelPlacement _parseLabelPlacement(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final ppEl = findChild(element, 'PointPlacement');
  final pointPlacement = ppEl != null
      ? _parsePointPlacement(ppEl, issues, '$path/PointPlacement')
      : null;

  final lpEl = findChild(element, 'LinePlacement');
  final linePlacement = lpEl != null
      ? _parseLinePlacement(lpEl, issues, '$path/LinePlacement')
      : null;

  return LabelPlacement(
      pointPlacement: pointPlacement, linePlacement: linePlacement);
}

PointPlacement _parsePointPlacement(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  double? anchorX, anchorY, displacementX, displacementY, rotation;

  final anchorEl = findChild(element, 'AnchorPoint');
  if (anchorEl != null) {
    final axText = childText(anchorEl, 'AnchorPointX');
    anchorX = axText != null ? double.tryParse(axText) : null;
    final ayText = childText(anchorEl, 'AnchorPointY');
    anchorY = ayText != null ? double.tryParse(ayText) : null;
  }

  final dispEl = findChild(element, 'Displacement');
  if (dispEl != null) {
    final dxText = childText(dispEl, 'DisplacementX');
    displacementX = dxText != null ? double.tryParse(dxText) : null;
    final dyText = childText(dispEl, 'DisplacementY');
    displacementY = dyText != null ? double.tryParse(dyText) : null;
  }

  final rotText = childText(element, 'Rotation');
  rotation = rotText != null ? double.tryParse(rotText) : null;

  return PointPlacement(
    anchorPointX: anchorX,
    anchorPointY: anchorY,
    displacementX: displacementX,
    displacementY: displacementY,
    rotation: rotation,
  );
}

LinePlacement _parseLinePlacement(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final offsetText = childText(element, 'PerpendicularOffset');
  final offset = offsetText != null ? double.tryParse(offsetText) : null;
  return LinePlacement(perpendicularOffset: offset);
}
