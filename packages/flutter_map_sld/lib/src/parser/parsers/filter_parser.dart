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
