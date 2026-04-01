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
  /// Creates a matched style wrapping the [matchedRule] context and adapted [style].
  const FlutterMapMatchedStyle({
    required this.matchedRule,
    required this.style,
  });

  /// The original matched rule with layer/style context.
  final MatchedRule matchedRule;

  /// The adapted style DTOs for this rule.
  final FlutterMapRuleStyle style;
}

/// All adapted style outputs that may be attached to a single rule.
class FlutterMapRuleStyle {
  /// Creates a rule style with optional symbolizer outputs.
  const FlutterMapRuleStyle({
    this.point,
    this.line,
    this.polygon,
    this.text,
  });

  /// Point/marker style, if the rule contains a PointSymbolizer.
  final FlutterMapPointStyle? point;

  /// Line style, if the rule contains a LineSymbolizer.
  final FlutterMapLineStyle? line;

  /// Polygon style, if the rule contains a PolygonSymbolizer.
  final FlutterMapPolygonStyle? polygon;

  /// Text style, if the rule contains a TextSymbolizer.
  final FlutterMapTextStyle? text;
}

/// A reusable fill style.
class FlutterMapFillStyle {
  /// Creates a fill style with optional [color] and [opacity].
  const FlutterMapFillStyle({
    this.color,
    this.opacity,
  });

  /// Fill color derived from the SLD ARGB value.
  final Color? color;

  /// Fill opacity from 0.0 (transparent) to 1.0 (opaque).
  final double? opacity;
}

/// A reusable stroke style.
class FlutterMapStrokeStyle {
  /// Creates a stroke style with optional visual properties.
  FlutterMapStrokeStyle({
    this.color,
    this.width,
    this.opacity,
    List<double>? dashArray,
    this.cap,
    this.join,
  }) : dashArray = dashArray == null ? null : List.unmodifiable(dashArray);

  /// Stroke color derived from the SLD ARGB value.
  final Color? color;

  /// Stroke width in pixels.
  final double? width;

  /// Stroke opacity from 0.0 (transparent) to 1.0 (opaque).
  final double? opacity;

  /// Dash pattern as alternating dash/gap lengths (unmodifiable).
  final List<double>? dashArray;

  /// Line cap style.
  final StrokeCap? cap;

  /// Line join style.
  final StrokeJoin? join;
}

/// Well-known mark names mapped to a stable Dart enum.
enum FlutterMapMarkShape {
  /// Square mark shape.
  square,

  /// Circle mark shape.
  circle,

  /// Triangle mark shape.
  triangle,

  /// Star mark shape.
  star,

  /// Cross mark shape.
  cross,

  /// X mark shape.
  x,

  /// Unknown or unsupported mark shape.
  unknown,
}

/// Point/marker styling translated from an SLD [PointSymbolizer].
class FlutterMapPointStyle {
  /// Creates a point style with optional visual properties.
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

  /// Symbol size in pixels.
  final double? size;

  /// Rotation angle in degrees (clockwise).
  final double? rotation;

  /// Graphic opacity from 0.0 to 1.0.
  final double? opacity;

  /// Well-known mark shape.
  final FlutterMapMarkShape? markShape;

  /// Fill style for the mark interior.
  final FlutterMapFillStyle? fill;

  /// Stroke style for the mark outline.
  final FlutterMapStrokeStyle? stroke;

  /// URL of an external graphic image.
  final String? externalGraphicUrl;

  /// MIME type of the external graphic (e.g. `image/png`).
  final String? externalGraphicFormat;
}

/// Line styling translated from an SLD [LineSymbolizer].
class FlutterMapLineStyle {
  /// Creates a line style with optional [stroke].
  const FlutterMapLineStyle({
    this.stroke,
  });

  /// Stroke style for the line.
  final FlutterMapStrokeStyle? stroke;
}

/// Polygon styling translated from an SLD [PolygonSymbolizer].
class FlutterMapPolygonStyle {
  /// Creates a polygon style with optional [fill] and [stroke].
  const FlutterMapPolygonStyle({
    this.fill,
    this.stroke,
  });

  /// Fill style for the polygon interior.
  final FlutterMapFillStyle? fill;

  /// Stroke style for the polygon outline.
  final FlutterMapStrokeStyle? stroke;
}

/// Point-placement hints translated from an SLD [PointPlacement].
class FlutterMapPointPlacementStyle {
  /// Creates point-placement hints with optional anchor, displacement, and rotation.
  const FlutterMapPointPlacementStyle({
    this.anchorPointX,
    this.anchorPointY,
    this.displacementX,
    this.displacementY,
    this.rotation,
  });

  /// Anchor X (0.0 = left, 0.5 = center, 1.0 = right).
  final double? anchorPointX;

  /// Anchor Y (0.0 = bottom, 0.5 = middle, 1.0 = top).
  final double? anchorPointY;

  /// Displacement X in pixels.
  final double? displacementX;

  /// Displacement Y in pixels.
  final double? displacementY;

  /// Rotation angle in degrees.
  final double? rotation;
}

/// Line-placement hints translated from an SLD [LinePlacement].
class FlutterMapLinePlacementStyle {
  /// Creates line-placement hints with optional [perpendicularOffset].
  const FlutterMapLinePlacementStyle({
    this.perpendicularOffset,
  });

  /// Offset perpendicular to the line in pixels.
  final double? perpendicularOffset;
}

/// Text styling translated from an SLD [TextSymbolizer].
class FlutterMapTextStyle {
  /// Creates a text style with optional label, fill, halo, and placement.
  const FlutterMapTextStyle({
    this.text,
    this.fill,
    this.textStyle,
    this.haloFill,
    this.haloRadius,
    this.pointPlacement,
    this.linePlacement,
  });

  /// The evaluated label text.
  final String? text;

  /// Fill style for the label text.
  final FlutterMapFillStyle? fill;

  /// Flutter [TextStyle] derived from SLD font parameters.
  final TextStyle? textStyle;

  /// Fill style for the text halo (outline).
  final FlutterMapFillStyle? haloFill;

  /// Halo radius in pixels.
  final double? haloRadius;

  /// Point-based label placement hints.
  final FlutterMapPointPlacementStyle? pointPlacement;

  /// Line-following label placement hints.
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
