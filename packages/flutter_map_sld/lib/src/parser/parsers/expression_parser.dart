import 'package:xml/xml.dart';

import '../../model/expression.dart';
import '../../model/issue.dart';
import '../xml_helpers.dart';

/// Parses an OGC expression element (`<PropertyName>` or `<Literal>`).
///
/// Returns `null` if the element is not a recognized expression type.
Expression? parseExpression(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final name = element.localName;
  switch (name) {
    case 'PropertyName':
      final text = element.innerText.trim();
      if (text.isEmpty) {
        issues.add(SldParseIssue(
          severity: SldIssueSeverity.warning,
          code: 'empty-property-name',
          message: 'Empty PropertyName element',
          location: path,
        ));
        return null;
      }
      return PropertyName(text);
    case 'Literal':
      final text = element.innerText.trim();
      // Try numeric parsing for convenience.
      final asNum = num.tryParse(text);
      return Literal(asNum ?? text);
    default:
      issues.add(SldParseIssue(
        severity: SldIssueSeverity.info,
        code: 'unsupported-expression',
        message: 'Unsupported expression type: <$name>',
        location: path,
      ));
      return null;
  }
}

/// Finds and parses the first expression child element within [parent].
Expression? parseFirstExpression(
  XmlElement parent,
  List<SldParseIssue> issues,
  String path,
) {
  // Try PropertyName first, then Literal.
  final pn = findChild(parent, 'PropertyName');
  if (pn != null) return parseExpression(pn, issues, '$path/PropertyName');
  final lit = findChild(parent, 'Literal');
  if (lit != null) return parseExpression(lit, issues, '$path/Literal');
  return null;
}

/// Parses the two expression operands within a comparison filter element.
/// Returns `[expression1, expression2]` or `null` if parsing fails.
List<Expression>? parseTwoExpressions(
  XmlElement parent,
  List<SldParseIssue> issues,
  String path,
) {
  final expressions = <Expression>[];
  for (final child in parent.childElements) {
    if (child.localName == 'PropertyName' ||
        child.localName == 'Literal') {
      final expr = parseExpression(child, issues, '$path/${child.localName}');
      if (expr != null) expressions.add(expr);
    }
  }
  if (expressions.length < 2) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.warning,
      code: 'missing-comparison-operand',
      message: 'Comparison filter requires two expression operands',
      location: path,
    ));
    return null;
  }
  return expressions;
}
