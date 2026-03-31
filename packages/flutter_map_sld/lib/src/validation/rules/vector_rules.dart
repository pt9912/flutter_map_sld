import '../../model/fill.dart';
import '../../model/graphic.dart';
import '../../model/issue.dart';
import '../../model/line_symbolizer.dart';
import '../../model/point_symbolizer.dart';
import '../../model/polygon_symbolizer.dart';
import '../../model/stroke.dart';
import '../../model/text_symbolizer.dart';

/// Known OGC well-known mark names.
const _knownMarkNames = {
  'square', 'circle', 'triangle', 'star', 'cross', 'x',
};

void _validateStroke(
    Stroke stroke, List<SldValidationIssue> issues, String path) {
  final w = stroke.width;
  if (w != null && w < 0.0) {
    issues.add(SldValidationIssue(
      severity: SldIssueSeverity.error,
      code: 'stroke-width-negative',
      message: 'Stroke width must be non-negative, got $w',
      location: '$path.width',
    ));
  }
  final o = stroke.opacity;
  if (o != null && (o < 0.0 || o > 1.0)) {
    issues.add(SldValidationIssue(
      severity: SldIssueSeverity.error,
      code: 'stroke-opacity-out-of-range',
      message: 'Stroke opacity must be between 0.0 and 1.0, got $o',
      location: '$path.opacity',
    ));
  }
}

void _validateFill(
    Fill fill, List<SldValidationIssue> issues, String path) {
  final o = fill.opacity;
  if (o != null && (o < 0.0 || o > 1.0)) {
    issues.add(SldValidationIssue(
      severity: SldIssueSeverity.error,
      code: 'fill-opacity-out-of-range',
      message: 'Fill opacity must be between 0.0 and 1.0, got $o',
      location: '$path.opacity',
    ));
  }
}

void _validateGraphic(
    Graphic graphic, List<SldValidationIssue> issues, String path) {
  final s = graphic.size;
  if (s != null && s < 0.0) {
    issues.add(SldValidationIssue(
      severity: SldIssueSeverity.error,
      code: 'graphic-size-negative',
      message: 'Graphic size must be non-negative, got $s',
      location: '$path.size',
    ));
  }
  final mark = graphic.mark;
  if (mark != null) {
    final name = mark.wellKnownName;
    if (name != null && !_knownMarkNames.contains(name)) {
      issues.add(SldValidationIssue(
        severity: SldIssueSeverity.info,
        code: 'unknown-mark-name',
        message: 'Unknown WellKnownName: "$name"',
        location: '$path.mark.wellKnownName',
      ));
    }
    if (mark.fill != null) {
      _validateFill(mark.fill!, issues, '$path.mark.fill');
    }
    if (mark.stroke != null) {
      _validateStroke(mark.stroke!, issues, '$path.mark.stroke');
    }
  }
}

/// Validates a [PointSymbolizer].
void validatePointSymbolizer(
  PointSymbolizer ps,
  List<SldValidationIssue> issues,
  String path,
) {
  if (ps.graphic != null) {
    _validateGraphic(ps.graphic!, issues, '$path.graphic');
  }
}

/// Validates a [LineSymbolizer].
void validateLineSymbolizer(
  LineSymbolizer ls,
  List<SldValidationIssue> issues,
  String path,
) {
  if (ls.stroke != null) {
    _validateStroke(ls.stroke!, issues, '$path.stroke');
  }
}

/// Validates a [PolygonSymbolizer].
void validatePolygonSymbolizer(
  PolygonSymbolizer ps,
  List<SldValidationIssue> issues,
  String path,
) {
  if (ps.fill != null) {
    _validateFill(ps.fill!, issues, '$path.fill');
  }
  if (ps.stroke != null) {
    _validateStroke(ps.stroke!, issues, '$path.stroke');
  }
}

/// Validates a [TextSymbolizer].
void validateTextSymbolizer(
  TextSymbolizer ts,
  List<SldValidationIssue> issues,
  String path,
) {
  final fontSize = ts.font?.size;
  if (fontSize != null && fontSize < 0.0) {
    issues.add(SldValidationIssue(
      severity: SldIssueSeverity.error,
      code: 'font-size-negative',
      message: 'Font size must be non-negative, got $fontSize',
      location: '$path.font.size',
    ));
  }

  final haloRadius = ts.halo?.radius;
  if (haloRadius != null && haloRadius < 0.0) {
    issues.add(SldValidationIssue(
      severity: SldIssueSeverity.error,
      code: 'halo-radius-negative',
      message: 'Halo radius must be non-negative, got $haloRadius',
      location: '$path.halo.radius',
    ));
  }

  if (ts.fill != null) {
    _validateFill(ts.fill!, issues, '$path.fill');
  }
}
