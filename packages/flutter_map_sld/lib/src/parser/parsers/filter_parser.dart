import 'package:gml4dart/gml4dart.dart';
import 'package:xml/xml.dart';

import '../../model/expression.dart';
import '../../model/filter.dart';
import '../../model/issue.dart';
import '../xml_helpers.dart';
import 'expression_parser.dart';

/// Parses an `<ogc:Filter>` or `<Filter>` element.
Filter? parseFilter(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  // A Filter element contains exactly one child filter operator.
  for (final child in element.childElements) {
    return _parseFilterOperator(child, issues, '$path/${child.localName}');
  }
  return null;
}

Filter? _parseFilterOperator(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  switch (element.localName) {
    // Comparison operators
    case 'PropertyIsEqualTo':
      return _parseComparison(element, issues, path,
          (a, b) => PropertyIsEqualTo(expression1: a, expression2: b));
    case 'PropertyIsNotEqualTo':
      return _parseComparison(element, issues, path,
          (a, b) => PropertyIsNotEqualTo(expression1: a, expression2: b));
    case 'PropertyIsLessThan':
      return _parseComparison(element, issues, path,
          (a, b) => PropertyIsLessThan(expression1: a, expression2: b));
    case 'PropertyIsGreaterThan':
      return _parseComparison(element, issues, path,
          (a, b) => PropertyIsGreaterThan(expression1: a, expression2: b));
    case 'PropertyIsLessThanOrEqualTo':
      return _parseComparison(element, issues, path,
          (a, b) =>
              PropertyIsLessThanOrEqualTo(expression1: a, expression2: b));
    case 'PropertyIsGreaterThanOrEqualTo':
      return _parseComparison(element, issues, path,
          (a, b) =>
              PropertyIsGreaterThanOrEqualTo(expression1: a, expression2: b));

    // Between
    case 'PropertyIsBetween':
      return _parseBetween(element, issues, path);

    // Like
    case 'PropertyIsLike':
      return _parseLike(element, issues, path);

    // Null
    case 'PropertyIsNull':
      return _parseNull(element, issues, path);

    // Logical operators
    case 'And':
      return _parseLogical(element, issues, path, isAnd: true);
    case 'Or':
      return _parseLogical(element, issues, path, isAnd: false);
    case 'Not':
      return _parseNot(element, issues, path);

    // Spatial operators
    case 'BBOX':
      return _parseBBox(element, issues, path);
    case 'Intersects':
      return _parseSpatialBinary(element, issues, path,
          (pn, g) => Intersects(propertyName: pn, geometry: g));
    case 'Within':
      return _parseSpatialBinary(element, issues, path,
          (pn, g) => Within(propertyName: pn, geometry: g));
    case 'Contains':
      return _parseSpatialBinary(element, issues, path,
          (pn, g) => Contains(propertyName: pn, geometry: g));
    case 'Touches':
      return _parseSpatialBinary(element, issues, path,
          (pn, g) => Touches(propertyName: pn, geometry: g));
    case 'Crosses':
      return _parseSpatialBinary(element, issues, path,
          (pn, g) => Crosses(propertyName: pn, geometry: g));
    case 'Overlaps':
      return _parseSpatialBinary(element, issues, path,
          (pn, g) => SpatialOverlaps(propertyName: pn, geometry: g));
    case 'Disjoint':
      return _parseSpatialBinary(element, issues, path,
          (pn, g) => Disjoint(propertyName: pn, geometry: g));
    case 'DWithin':
      return _parseSpatialDistance(element, issues, path, isDWithin: true);
    case 'Beyond':
      return _parseSpatialDistance(element, issues, path, isDWithin: false);

    default:
      issues.add(SldParseIssue(
        severity: SldIssueSeverity.info,
        code: 'unsupported-filter',
        message: 'Unsupported filter operator: <${element.localName}>',
        location: path,
      ));
      return null;
  }
}

// ---------------------------------------------------------------------------
// Comparison parsers
// ---------------------------------------------------------------------------

Filter? _parseComparison(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
  Filter Function(Expression, Expression) builder,
) {
  final exprs = parseTwoExpressions(element, issues, path);
  if (exprs == null) return null;
  return builder(exprs[0], exprs[1]);
}

Filter? _parseBetween(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final expr = parseFirstExpression(element, issues, path);
  if (expr == null) return null;

  final lowerEl = findChild(element, 'LowerBoundary');
  final upperEl = findChild(element, 'UpperBoundary');
  final lower = lowerEl != null
      ? parseFirstExpression(lowerEl, issues, '$path/LowerBoundary')
      : null;
  final upper = upperEl != null
      ? parseFirstExpression(upperEl, issues, '$path/UpperBoundary')
      : null;

  if (lower == null || upper == null) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.warning,
      code: 'missing-between-boundary',
      message: 'PropertyIsBetween requires LowerBoundary and UpperBoundary',
      location: path,
    ));
    return null;
  }

  return PropertyIsBetween(
      expression: expr, lowerBoundary: lower, upperBoundary: upper);
}

Filter? _parseLike(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final expr = parseFirstExpression(element, issues, path);
  if (expr == null) return null;

  final pattern = stringAttr(element, 'literal') ??
      childText(element, 'Literal') ??
      '';
  final wildCard = stringAttr(element, 'wildCard') ?? '*';
  final singleChar = stringAttr(element, 'singleChar') ?? '?';
  final escapeChar =
      stringAttr(element, 'escapeChar') ?? stringAttr(element, 'escape') ?? '\\';

  return PropertyIsLike(
    expression: expr,
    pattern: pattern,
    wildCard: wildCard,
    singleChar: singleChar,
    escapeChar: escapeChar,
  );
}

Filter? _parseNull(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final expr = parseFirstExpression(element, issues, path);
  if (expr == null) return null;
  return PropertyIsNull(expression: expr);
}

// ---------------------------------------------------------------------------
// Logical parsers
// ---------------------------------------------------------------------------

Filter? _parseLogical(
  XmlElement element,
  List<SldParseIssue> issues,
  String path, {
  required bool isAnd,
}) {
  final filters = <Filter>[];
  for (final child in element.childElements) {
    final f =
        _parseFilterOperator(child, issues, '$path/${child.localName}');
    if (f != null) filters.add(f);
  }
  if (filters.isEmpty) return null;
  return isAnd ? And(filters: filters) : Or(filters: filters);
}

Filter? _parseNot(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  for (final child in element.childElements) {
    final f =
        _parseFilterOperator(child, issues, '$path/${child.localName}');
    if (f != null) return Not(filter: f);
  }
  return null;
}

// ---------------------------------------------------------------------------
// Spatial filter parsers
// ---------------------------------------------------------------------------

/// Known GML geometry element local names.
const _gmlGeometryNames = {
  'Point', 'LineString', 'LinearRing', 'Polygon', 'Envelope', 'Box',
  'Curve', 'Surface', 'MultiPoint', 'MultiLineString', 'MultiPolygon',
  'MultiGeometry', 'MultiSurface', 'MultiCurve',
};

/// Parses a GML geometry element via `gml4dart`.
GmlGeometry? _parseGmlGeometry(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final result = GmlDocument.parseXmlString(element.toXmlString());
  if (result.hasErrors) {
    for (final issue in result.issues) {
      issues.add(SldParseIssue(
        severity: SldIssueSeverity.warning,
        code: 'gml-parse-error',
        message: issue.message,
        location: path,
      ));
    }
    return null;
  }
  final root = result.document?.root;
  if (root is! GmlGeometry) return null;
  return root;
}

/// Finds the optional `<PropertyName>` and the first GML geometry child.
({String? propertyName, GmlGeometry? geometry}) _parseSpatialChildren(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  String? propertyName;
  GmlGeometry? geometry;

  for (final child in element.childElements) {
    if (child.localName == 'PropertyName') {
      propertyName = child.innerText.trim();
    } else if (_gmlGeometryNames.contains(child.localName)) {
      geometry ??= _parseGmlGeometry(child, issues, '$path/${child.localName}');
    }
  }

  return (propertyName: propertyName, geometry: geometry);
}

/// Parses `<BBOX>` — expects optional PropertyName + Envelope/Box.
Filter? _parseBBox(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final children = _parseSpatialChildren(element, issues, path);
  final geom = children.geometry;

  GmlEnvelope? envelope;
  if (geom is GmlEnvelope) {
    envelope = geom;
  } else if (geom is GmlBox) {
    envelope = GmlEnvelope(
        lowerCorner: geom.lowerCorner, upperCorner: geom.upperCorner);
  }

  if (envelope == null) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.warning,
      code: 'bbox-missing-envelope',
      message: 'BBOX requires an Envelope or Box geometry child',
      location: path,
    ));
    return null;
  }

  return BBox(propertyName: children.propertyName, envelope: envelope);
}

/// Parses a binary spatial filter (Intersects, Within, Contains, etc.).
Filter? _parseSpatialBinary(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
  Filter Function(String?, GmlGeometry) builder,
) {
  final children = _parseSpatialChildren(element, issues, path);
  final geom = children.geometry;

  if (geom == null) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.warning,
      code: 'spatial-filter-missing-geometry',
      message: '${element.localName} requires a GML geometry child',
      location: path,
    ));
    return null;
  }

  return builder(children.propertyName, geom);
}

/// Parses `<DWithin>` or `<Beyond>` — spatial + distance + units.
Filter? _parseSpatialDistance(
  XmlElement element,
  List<SldParseIssue> issues,
  String path, {
  required bool isDWithin,
}) {
  final children = _parseSpatialChildren(element, issues, path);
  final geom = children.geometry;

  if (geom == null) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.warning,
      code: 'distance-filter-missing-geometry',
      message: '${element.localName} requires a GML geometry child',
      location: path,
    ));
    return null;
  }

  final distanceEl = findChild(element, 'Distance');
  final distanceText = distanceEl?.innerText.trim();
  final distance = distanceText != null ? double.tryParse(distanceText) : null;

  if (distance == null) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.warning,
      code: 'distance-filter-missing-distance',
      message: '${element.localName} requires a <Distance> child',
      location: path,
    ));
    return null;
  }

  final units = distanceEl != null
      ? (stringAttr(distanceEl, 'units') ?? stringAttr(distanceEl, 'uom') ?? '')
      : '';

  if (isDWithin) {
    return DWithin(
      propertyName: children.propertyName,
      geometry: geom,
      distance: distance,
      units: units,
    );
  } else {
    return Beyond(
      propertyName: children.propertyName,
      geometry: geom,
      distance: distance,
      units: units,
    );
  }
}
