import 'package:xml/xml.dart';

import '../../model/fill.dart';
import '../../model/graphic.dart';
import '../../model/issue.dart';
import '../../model/line_symbolizer.dart';
import '../../model/point_symbolizer.dart';
import '../../model/polygon_symbolizer.dart';
import '../../model/stroke.dart';
import '../xml_helpers.dart';

// ---------------------------------------------------------------------------
// Stroke
// ---------------------------------------------------------------------------

/// Parses a `<Stroke>` element.
Stroke parseStroke(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  int? color;
  double? width;
  double? opacity;
  String? dashArrayRaw;
  String? lineCap;
  String? lineJoin;

  for (final param in findChildren(element, 'CssParameter')) {
    final name = stringAttr(param, 'name');
    final value = param.innerText.trim();
    switch (name) {
      case 'stroke':
        color = parseColorHex(value);
      case 'stroke-width':
        width = double.tryParse(value);
      case 'stroke-opacity':
        opacity = double.tryParse(value);
      case 'stroke-dasharray':
        dashArrayRaw = value;
      case 'stroke-linecap':
        lineCap = value;
      case 'stroke-linejoin':
        lineJoin = value;
    }
  }

  // Also check SvgParameter (SE 1.1 name for CssParameter).
  for (final param in findChildren(element, 'SvgParameter')) {
    final name = stringAttr(param, 'name');
    final value = param.innerText.trim();
    switch (name) {
      case 'stroke':
        color ??= parseColorHex(value);
      case 'stroke-width':
        width ??= double.tryParse(value);
      case 'stroke-opacity':
        opacity ??= double.tryParse(value);
      case 'stroke-dasharray':
        dashArrayRaw ??= value;
      case 'stroke-linecap':
        lineCap ??= value;
      case 'stroke-linejoin':
        lineJoin ??= value;
    }
  }

  List<double>? dashArray;
  if (dashArrayRaw != null) {
    dashArray = dashArrayRaw
        .split(RegExp(r'[\s,]+'))
        .map(double.tryParse)
        .whereType<double>()
        .toList();
    if (dashArray.isEmpty) dashArray = null;
  }

  return Stroke(
    colorArgb: color,
    width: width,
    opacity: opacity,
    dashArray: dashArray,
    lineCap: lineCap,
    lineJoin: lineJoin,
  );
}

// ---------------------------------------------------------------------------
// Fill
// ---------------------------------------------------------------------------

/// Parses a `<Fill>` element.
Fill parseFill(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  int? color;
  double? opacity;

  for (final param in findChildren(element, 'CssParameter')) {
    final name = stringAttr(param, 'name');
    final value = param.innerText.trim();
    switch (name) {
      case 'fill':
        color = parseColorHex(value);
      case 'fill-opacity':
        opacity = double.tryParse(value);
    }
  }

  for (final param in findChildren(element, 'SvgParameter')) {
    final name = stringAttr(param, 'name');
    final value = param.innerText.trim();
    switch (name) {
      case 'fill':
        color ??= parseColorHex(value);
      case 'fill-opacity':
        opacity ??= double.tryParse(value);
    }
  }

  return Fill(colorArgb: color, opacity: opacity);
}

// ---------------------------------------------------------------------------
// Mark
// ---------------------------------------------------------------------------

/// Parses a `<Mark>` element.
Mark parseMark(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final wellKnownName = childText(element, 'WellKnownName');

  final fillEl = findChild(element, 'Fill');
  final fill = fillEl != null ? parseFill(fillEl, issues, '$path/Fill') : null;

  final strokeEl = findChild(element, 'Stroke');
  final stroke =
      strokeEl != null ? parseStroke(strokeEl, issues, '$path/Stroke') : null;

  return Mark(wellKnownName: wellKnownName, fill: fill, stroke: stroke);
}

// ---------------------------------------------------------------------------
// ExternalGraphic
// ---------------------------------------------------------------------------

/// Parses an `<ExternalGraphic>` element.
ExternalGraphic? parseExternalGraphic(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final onlineResourceEl = findChild(element, 'OnlineResource');
  final href = onlineResourceEl?.getAttribute('xlink:href') ??
      onlineResourceEl?.getAttribute('href');

  if (href == null || href.isEmpty) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.warning,
      code: 'missing-online-resource',
      message: 'ExternalGraphic without OnlineResource href',
      location: path,
    ));
    return null;
  }

  final format = childText(element, 'Format');

  return ExternalGraphic(onlineResource: href, format: format);
}

// ---------------------------------------------------------------------------
// Graphic
// ---------------------------------------------------------------------------

/// Parses a `<Graphic>` element.
Graphic parseGraphic(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final markEl = findChild(element, 'Mark');
  final mark =
      markEl != null ? parseMark(markEl, issues, '$path/Mark') : null;

  final extEl = findChild(element, 'ExternalGraphic');
  final externalGraphic = extEl != null
      ? parseExternalGraphic(extEl, issues, '$path/ExternalGraphic')
      : null;

  final sizeText = childText(element, 'Size');
  final size = sizeText != null ? double.tryParse(sizeText) : null;

  final rotationText = childText(element, 'Rotation');
  final rotation = rotationText != null ? double.tryParse(rotationText) : null;

  final opacityText = childText(element, 'Opacity');
  final opacity = opacityText != null ? double.tryParse(opacityText) : null;

  return Graphic(
    mark: mark,
    externalGraphic: externalGraphic,
    size: size,
    rotation: rotation,
    opacity: opacity,
  );
}

// ---------------------------------------------------------------------------
// PointSymbolizer
// ---------------------------------------------------------------------------

/// Parses a `<PointSymbolizer>` element.
PointSymbolizer parsePointSymbolizer(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final graphicEl = findChild(element, 'Graphic');
  final graphic = graphicEl != null
      ? parseGraphic(graphicEl, issues, '$path/Graphic')
      : null;

  return PointSymbolizer(graphic: graphic);
}

// ---------------------------------------------------------------------------
// LineSymbolizer
// ---------------------------------------------------------------------------

/// Parses a `<LineSymbolizer>` element.
LineSymbolizer parseLineSymbolizer(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final strokeEl = findChild(element, 'Stroke');
  final stroke =
      strokeEl != null ? parseStroke(strokeEl, issues, '$path/Stroke') : null;

  return LineSymbolizer(stroke: stroke);
}

// ---------------------------------------------------------------------------
// PolygonSymbolizer
// ---------------------------------------------------------------------------

/// Parses a `<PolygonSymbolizer>` element.
PolygonSymbolizer parsePolygonSymbolizer(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final fillEl = findChild(element, 'Fill');
  final fill = fillEl != null ? parseFill(fillEl, issues, '$path/Fill') : null;

  final strokeEl = findChild(element, 'Stroke');
  final stroke =
      strokeEl != null ? parseStroke(strokeEl, issues, '$path/Stroke') : null;

  return PolygonSymbolizer(fill: fill, stroke: stroke);
}
