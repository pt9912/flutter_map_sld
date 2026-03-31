import 'package:flutter/painting.dart';
import 'package:flutter_map_sld/flutter_map_sld.dart';

/// A small first-scope adapter that turns parsed SLD rules into immutable,
/// `flutter_map`-friendly style DTOs.
///
/// The adapter deliberately does not create concrete `flutter_map` layers,
/// markers, or geometries. Geometry ownership and rendering depth remain with
/// the caller.
class FlutterMapStyleAdapter {
  const FlutterMapStyleAdapter();

  /// Adapts a single [rule] into style DTOs.
  FlutterMapRuleStyle adaptRule(
    Rule rule, {
    Map<String, dynamic> properties = const {},
  }) {
    return FlutterMapRuleStyle(
      point: _adaptPoint(rule.pointSymbolizer),
      line: _adaptLine(rule.lineSymbolizer),
      polygon: _adaptPolygon(rule.polygonSymbolizer),
      text: _adaptText(rule.textSymbolizer, properties),
    );
  }

  /// Adapts one already matched rule together with its context.
  FlutterMapMatchedStyle adaptMatchedRule(
    MatchedRule matchedRule, {
    Map<String, dynamic> properties = const {},
  }) {
    return FlutterMapMatchedStyle(
      matchedRule: matchedRule,
      style: adaptRule(matchedRule.rule, properties: properties),
    );
  }

  /// Adapts a list of already matched rules together with their context.
  List<FlutterMapMatchedStyle> adaptMatchedRules(
    Iterable<MatchedRule> matchedRules, {
    Map<String, dynamic> properties = const {},
  }) {
    return matchedRules
        .map((matchedRule) =>
            adaptMatchedRule(matchedRule, properties: properties))
        .toList(growable: false);
  }

  /// Selects and adapts all matching rules in [document].
  List<FlutterMapMatchedStyle> adaptDocument(
    SldDocument document, {
    required Map<String, dynamic> properties,
    double? scaleDenominator,
  }) {
    final matchedRules = document.selectMatchingRules(
      properties,
      scaleDenominator: scaleDenominator,
    );
    return adaptMatchedRules(matchedRules, properties: properties);
  }

  FlutterMapPointStyle? _adaptPoint(PointSymbolizer? symbolizer) {
    if (symbolizer == null) return null;
    final graphic = symbolizer.graphic;
    final mark = graphic?.mark;
    final externalGraphic = graphic?.externalGraphic;
    return FlutterMapPointStyle(
      size: graphic?.size,
      rotation: graphic?.rotation,
      opacity: graphic?.opacity,
      markShape: _toMarkShape(mark?.wellKnownName),
      fill: _adaptFill(mark?.fill),
      stroke: _adaptStroke(mark?.stroke),
      externalGraphicUrl: externalGraphic?.onlineResource,
      externalGraphicFormat: externalGraphic?.format,
    );
  }

  FlutterMapLineStyle? _adaptLine(LineSymbolizer? symbolizer) {
    if (symbolizer == null) return null;
    return FlutterMapLineStyle(stroke: _adaptStroke(symbolizer.stroke));
  }

  FlutterMapPolygonStyle? _adaptPolygon(PolygonSymbolizer? symbolizer) {
    if (symbolizer == null) return null;
    return FlutterMapPolygonStyle(
      fill: _adaptFill(symbolizer.fill),
      stroke: _adaptStroke(symbolizer.stroke),
    );
  }

  FlutterMapTextStyle? _adaptText(
    TextSymbolizer? symbolizer,
    Map<String, dynamic> properties,
  ) {
    if (symbolizer == null) return null;

    final fill = _adaptFill(symbolizer.fill);
    final haloFill = _adaptFill(symbolizer.halo?.fill);
    final font = symbolizer.font;

    return FlutterMapTextStyle(
      text: symbolizer.label?.evaluate(properties)?.toString(),
      fill: fill,
      textStyle: _buildTextStyle(font, fill),
      haloFill: haloFill,
      haloRadius: symbolizer.halo?.radius,
      pointPlacement: _adaptPointPlacement(
        symbolizer.labelPlacement?.pointPlacement,
      ),
      linePlacement: _adaptLinePlacement(
        symbolizer.labelPlacement?.linePlacement,
      ),
    );
  }

  FlutterMapFillStyle? _adaptFill(Fill? fill) {
    if (fill == null) return null;
    return FlutterMapFillStyle(
      color: _toColor(fill.colorArgb),
      opacity: fill.opacity,
    );
  }

  FlutterMapStrokeStyle? _adaptStroke(Stroke? stroke) {
    if (stroke == null) return null;
    return FlutterMapStrokeStyle(
      color: _toColor(stroke.colorArgb),
      width: stroke.width,
      opacity: stroke.opacity,
      dashArray: stroke.dashArray,
      cap: _toStrokeCap(stroke.lineCap),
      join: _toStrokeJoin(stroke.lineJoin),
    );
  }

  FlutterMapPointPlacementStyle? _adaptPointPlacement(
    PointPlacement? placement,
  ) {
    if (placement == null) return null;
    return FlutterMapPointPlacementStyle(
      anchorPointX: placement.anchorPointX,
      anchorPointY: placement.anchorPointY,
      displacementX: placement.displacementX,
      displacementY: placement.displacementY,
      rotation: placement.rotation,
    );
  }

  FlutterMapLinePlacementStyle? _adaptLinePlacement(
    LinePlacement? placement,
  ) {
    if (placement == null) return null;
    return FlutterMapLinePlacementStyle(
      perpendicularOffset: placement.perpendicularOffset,
    );
  }
}

/// The adapted style output for one matched rule.
class FlutterMapMatchedStyle {
  const FlutterMapMatchedStyle({
    required this.matchedRule,
    required this.style,
  });

  final MatchedRule matchedRule;
  final FlutterMapRuleStyle style;
}

/// All adapted style outputs that may be attached to a single rule.
class FlutterMapRuleStyle {
  const FlutterMapRuleStyle({
    this.point,
    this.line,
    this.polygon,
    this.text,
  });

  final FlutterMapPointStyle? point;
  final FlutterMapLineStyle? line;
  final FlutterMapPolygonStyle? polygon;
  final FlutterMapTextStyle? text;
}

/// A reusable fill style.
class FlutterMapFillStyle {
  const FlutterMapFillStyle({
    this.color,
    this.opacity,
  });

  final Color? color;
  final double? opacity;
}

/// A reusable stroke style.
class FlutterMapStrokeStyle {
  FlutterMapStrokeStyle({
    this.color,
    this.width,
    this.opacity,
    List<double>? dashArray,
    this.cap,
    this.join,
  }) : dashArray = dashArray == null ? null : List.unmodifiable(dashArray);

  final Color? color;
  final double? width;
  final double? opacity;
  final List<double>? dashArray;
  final StrokeCap? cap;
  final StrokeJoin? join;
}

/// Well-known mark names mapped to a stable Dart enum.
enum FlutterMapMarkShape {
  square,
  circle,
  triangle,
  star,
  cross,
  x,
  unknown,
}

/// Point/marker styling translated from an SLD [PointSymbolizer].
class FlutterMapPointStyle {
  const FlutterMapPointStyle({
    this.size,
    this.rotation,
    this.opacity,
    this.markShape,
    this.fill,
    this.stroke,
    this.externalGraphicUrl,
    this.externalGraphicFormat,
  });

  final double? size;
  final double? rotation;
  final double? opacity;
  final FlutterMapMarkShape? markShape;
  final FlutterMapFillStyle? fill;
  final FlutterMapStrokeStyle? stroke;
  final String? externalGraphicUrl;
  final String? externalGraphicFormat;
}

/// Line styling translated from an SLD [LineSymbolizer].
class FlutterMapLineStyle {
  const FlutterMapLineStyle({
    this.stroke,
  });

  final FlutterMapStrokeStyle? stroke;
}

/// Polygon styling translated from an SLD [PolygonSymbolizer].
class FlutterMapPolygonStyle {
  const FlutterMapPolygonStyle({
    this.fill,
    this.stroke,
  });

  final FlutterMapFillStyle? fill;
  final FlutterMapStrokeStyle? stroke;
}

/// Point-placement hints translated from an SLD [PointPlacement].
class FlutterMapPointPlacementStyle {
  const FlutterMapPointPlacementStyle({
    this.anchorPointX,
    this.anchorPointY,
    this.displacementX,
    this.displacementY,
    this.rotation,
  });

  final double? anchorPointX;
  final double? anchorPointY;
  final double? displacementX;
  final double? displacementY;
  final double? rotation;
}

/// Line-placement hints translated from an SLD [LinePlacement].
class FlutterMapLinePlacementStyle {
  const FlutterMapLinePlacementStyle({
    this.perpendicularOffset,
  });

  final double? perpendicularOffset;
}

/// Text styling translated from an SLD [TextSymbolizer].
class FlutterMapTextStyle {
  const FlutterMapTextStyle({
    this.text,
    this.fill,
    this.textStyle,
    this.haloFill,
    this.haloRadius,
    this.pointPlacement,
    this.linePlacement,
  });

  final String? text;
  final FlutterMapFillStyle? fill;
  final TextStyle? textStyle;
  final FlutterMapFillStyle? haloFill;
  final double? haloRadius;
  final FlutterMapPointPlacementStyle? pointPlacement;
  final FlutterMapLinePlacementStyle? linePlacement;
}

Color? _toColor(int? argb) => argb == null ? null : Color(argb);

FlutterMapMarkShape _toMarkShape(String? wellKnownName) {
  switch (wellKnownName) {
    case 'square':
      return FlutterMapMarkShape.square;
    case 'circle':
      return FlutterMapMarkShape.circle;
    case 'triangle':
      return FlutterMapMarkShape.triangle;
    case 'star':
      return FlutterMapMarkShape.star;
    case 'cross':
      return FlutterMapMarkShape.cross;
    case 'x':
      return FlutterMapMarkShape.x;
    default:
      return FlutterMapMarkShape.unknown;
  }
}

StrokeCap? _toStrokeCap(String? lineCap) {
  switch (lineCap) {
    case 'butt':
      return StrokeCap.butt;
    case 'round':
      return StrokeCap.round;
    case 'square':
      return StrokeCap.square;
    default:
      return null;
  }
}

StrokeJoin? _toStrokeJoin(String? lineJoin) {
  switch (lineJoin) {
    case 'miter':
      return StrokeJoin.miter;
    case 'round':
      return StrokeJoin.round;
    case 'bevel':
      return StrokeJoin.bevel;
    default:
      return null;
  }
}

FontStyle? _toFontStyle(String? fontStyle) {
  switch (fontStyle) {
    case 'italic':
      return FontStyle.italic;
    case 'normal':
      return FontStyle.normal;
    default:
      return null;
  }
}

FontWeight? _toFontWeight(String? fontWeight) {
  switch (fontWeight) {
    case 'normal':
      return FontWeight.normal;
    case 'bold':
      return FontWeight.bold;
    default:
      return null;
  }
}

TextStyle? _buildTextStyle(Font? font, FlutterMapFillStyle? fill) {
  final color = fill?.color;
  final family = font?.family;
  final size = font?.size;
  final style = _toFontStyle(font?.style);
  final weight = _toFontWeight(font?.weight);

  if (color == null &&
      family == null &&
      size == null &&
      style == null &&
      weight == null) {
    return null;
  }

  return TextStyle(
    color: color,
    fontFamily: family,
    fontSize: size,
    fontStyle: style,
    fontWeight: weight,
  );
}
