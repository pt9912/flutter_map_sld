import 'package:xml/xml.dart';

import '../../model/expression.dart';
import '../../model/issue.dart';
import '../xml_helpers.dart';

/// All known expression element local names.
const _expressionLocalNames = {
  'PropertyName',
  'Literal',
  'Concatenate',
  'FormatNumber',
  'Categorize',
  'Interpolate',
  'Recode',
};

/// Parses an OGC expression element.
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
    case 'Concatenate':
      return _parseConcatenate(element, issues, path);
    case 'FormatNumber':
      return _parseFormatNumber(element, issues, path);
    case 'Categorize':
      return _parseCategorize(element, issues, path);
    case 'Interpolate':
      return _parseInterpolate(element, issues, path);
    case 'Recode':
      return _parseRecode(element, issues, path);
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
  for (final child in parent.childElements) {
    if (_expressionLocalNames.contains(child.localName)) {
      return parseExpression(child, issues, '$path/${child.localName}');
    }
  }
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
    if (_expressionLocalNames.contains(child.localName)) {
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

/// Collects all expression children of [parent].
List<Expression> parseAllExpressions(
  XmlElement parent,
  List<SldParseIssue> issues,
  String path,
) {
  final result = <Expression>[];
  for (final child in parent.childElements) {
    if (_expressionLocalNames.contains(child.localName)) {
      final expr = parseExpression(child, issues, '$path/${child.localName}');
      if (expr != null) result.add(expr);
    }
  }
  return result;
}

// ---------------------------------------------------------------------------
// Composite expression parsers
// ---------------------------------------------------------------------------

/// Parses `<Concatenate>` — collects all expression children.
Concatenate? _parseConcatenate(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final exprs = parseAllExpressions(element, issues, path);
  if (exprs.isEmpty) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.warning,
      code: 'concatenate-empty',
      message: 'Concatenate has no expression children',
      location: path,
    ));
    return null;
  }
  return Concatenate(expressions: exprs);
}

/// Parses `<FormatNumber>` — expects one expression child + `<Pattern>`.
FormatNumber? _parseFormatNumber(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final numExpr = parseFirstExpression(element, issues, path);
  if (numExpr == null) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.warning,
      code: 'format-number-missing-value',
      message: 'FormatNumber requires a numeric expression child',
      location: path,
    ));
    return null;
  }
  final pattern = childText(element, 'Pattern');
  if (pattern == null) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.warning,
      code: 'format-number-missing-pattern',
      message: 'FormatNumber requires a <Pattern> child',
      location: path,
    ));
    return null;
  }
  return FormatNumber(numericValue: numExpr, pattern: pattern);
}

/// Parses `<Categorize>`.
///
/// Expected structure:
/// ```xml
/// <Categorize>
///   <LookupValue>...</LookupValue>
///   <Value>v0</Value>
///   <Threshold>t1</Threshold>
///   <Value>v1</Value>
///   ...
/// </Categorize>
/// ```
Categorize? _parseCategorize(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  // LookupValue
  final lookupEl = findChild(element, 'LookupValue');
  Expression? lookupValue;
  if (lookupEl != null) {
    lookupValue = parseFirstExpression(lookupEl, issues, '$path/LookupValue');
  }
  if (lookupValue == null) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.warning,
      code: 'categorize-missing-lookup',
      message: 'Categorize requires a <LookupValue> child',
      location: path,
    ));
    return null;
  }

  // Collect Value and Threshold elements in document order.
  final values = <Expression>[];
  final thresholds = <Expression>[];
  for (final child in element.childElements) {
    final ln = child.localName;
    if (ln == 'Value') {
      final text = child.innerText.trim();
      final asNum = num.tryParse(text);
      values.add(Literal(asNum ?? text));
    } else if (ln == 'Threshold') {
      final text = child.innerText.trim();
      final asNum = num.tryParse(text);
      thresholds.add(Literal(asNum ?? text));
    }
  }

  if (values.isEmpty) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.warning,
      code: 'categorize-no-values',
      message: 'Categorize requires at least one <Value>',
      location: path,
    ));
    return null;
  }

  // Fallback
  final fallbackEl = findChild(element, 'Fallback');
  Expression? fallbackValue;
  if (fallbackEl != null) {
    fallbackValue = parseFirstExpression(fallbackEl, issues, '$path/Fallback');
  }

  return Categorize(
    lookupValue: lookupValue,
    thresholds: thresholds,
    values: values,
    fallbackValue: fallbackValue,
  );
}

/// Parses `<Interpolate>`.
///
/// Expected structure:
/// ```xml
/// <Interpolate method="linear">
///   <LookupValue>...</LookupValue>
///   <InterpolationPoint><Data>0</Data><Value>#00FF00</Value></InterpolationPoint>
///   ...
/// </Interpolate>
/// ```
Interpolate? _parseInterpolate(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  // Mode
  final methodStr = stringAttr(element, 'method') ??
      stringAttr(element, 'mode');
  final mode = switch (methodStr?.toLowerCase()) {
    'cubic' => InterpolateMode.cubic,
    _ => InterpolateMode.linear,
  };

  // LookupValue
  final lookupEl = findChild(element, 'LookupValue');
  Expression? lookupValue;
  if (lookupEl != null) {
    lookupValue = parseFirstExpression(lookupEl, issues, '$path/LookupValue');
  }
  if (lookupValue == null) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.warning,
      code: 'interpolate-missing-lookup',
      message: 'Interpolate requires a <LookupValue> child',
      location: path,
    ));
    return null;
  }

  // InterpolationPoints
  final points = <InterpolationPoint>[];
  for (final ipEl in findChildren(element, 'InterpolationPoint')) {
    final ipPath = '$path/InterpolationPoint';
    final dataText = childText(ipEl, 'Data');
    final dataNum = dataText != null ? num.tryParse(dataText) : null;
    if (dataNum == null) {
      issues.add(SldParseIssue(
        severity: SldIssueSeverity.warning,
        code: 'interpolation-point-invalid-data',
        message: 'InterpolationPoint requires a numeric <Data> child',
        location: ipPath,
      ));
      continue;
    }
    final valueText = childText(ipEl, 'Value');
    if (valueText == null) {
      issues.add(SldParseIssue(
        severity: SldIssueSeverity.warning,
        code: 'interpolation-point-missing-value',
        message: 'InterpolationPoint requires a <Value> child',
        location: ipPath,
      ));
      continue;
    }
    final asNum = num.tryParse(valueText);
    points.add(InterpolationPoint(
      data: dataNum,
      value: Literal(asNum ?? valueText),
    ));
  }

  if (points.isEmpty) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.warning,
      code: 'interpolate-no-points',
      message: 'Interpolate requires at least one <InterpolationPoint>',
      location: path,
    ));
    return null;
  }

  // Fallback
  final fallbackEl = findChild(element, 'Fallback');
  Expression? fallbackValue;
  if (fallbackEl != null) {
    fallbackValue = parseFirstExpression(fallbackEl, issues, '$path/Fallback');
  }

  return Interpolate(
    lookupValue: lookupValue,
    dataPoints: points,
    mode: mode,
    fallbackValue: fallbackValue,
  );
}

/// Parses `<Recode>`.
///
/// Expected structure:
/// ```xml
/// <Recode>
///   <LookupValue>...</LookupValue>
///   <MapItem><Data>A</Data><Value>Alpha</Value></MapItem>
///   ...
/// </Recode>
/// ```
Recode? _parseRecode(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  // LookupValue
  final lookupEl = findChild(element, 'LookupValue');
  Expression? lookupValue;
  if (lookupEl != null) {
    lookupValue = parseFirstExpression(lookupEl, issues, '$path/LookupValue');
  }
  if (lookupValue == null) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.warning,
      code: 'recode-missing-lookup',
      message: 'Recode requires a <LookupValue> child',
      location: path,
    ));
    return null;
  }

  // MapItems
  final mappings = <RecodeMapping>[];
  for (final mapEl in findChildren(element, 'MapItem')) {
    final mapPath = '$path/MapItem';
    final dataText = childText(mapEl, 'Data');
    if (dataText == null) {
      issues.add(SldParseIssue(
        severity: SldIssueSeverity.warning,
        code: 'map-item-missing-data',
        message: 'MapItem requires a <Data> child',
        location: mapPath,
      ));
      continue;
    }
    final valueText = childText(mapEl, 'Value');
    if (valueText == null) {
      issues.add(SldParseIssue(
        severity: SldIssueSeverity.warning,
        code: 'map-item-missing-value',
        message: 'MapItem requires a <Value> child',
        location: mapPath,
      ));
      continue;
    }
    final dataNum = num.tryParse(dataText);
    final valueNum = num.tryParse(valueText);
    mappings.add(RecodeMapping(
      inputValue: Literal(dataNum ?? dataText),
      outputValue: Literal(valueNum ?? valueText),
    ));
  }

  if (mappings.isEmpty) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.warning,
      code: 'recode-no-mappings',
      message: 'Recode requires at least one <MapItem>',
      location: path,
    ));
    return null;
  }

  // Fallback
  final fallbackEl = findChild(element, 'Fallback');
  Expression? fallbackValue;
  if (fallbackEl != null) {
    fallbackValue = parseFirstExpression(fallbackEl, issues, '$path/Fallback');
  }

  return Recode(
    lookupValue: lookupValue,
    mappings: mappings,
    fallbackValue: fallbackValue,
  );
}
