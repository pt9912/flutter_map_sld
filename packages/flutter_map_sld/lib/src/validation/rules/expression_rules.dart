import '../../model/expression.dart';
import '../../model/issue.dart';

/// Validates a composite [Expression] tree recursively.
///
/// Only composite expressions (Categorize, Interpolate, Recode) have
/// structural constraints worth validating. Simple expressions
/// (PropertyName, Literal, Concatenate, FormatNumber) are structurally
/// always valid if parsing succeeded.
void validateExpression(
  Expression expr,
  List<SldValidationIssue> issues,
  String path,
) {
  switch (expr) {
    case Categorize():
      _validateCategorize(expr, issues, path);
    case Interpolate():
      _validateInterpolate(expr, issues, path);
    case Recode():
      _validateRecode(expr, issues, path);
    case Concatenate():
      for (var i = 0; i < expr.expressions.length; i++) {
        validateExpression(expr.expressions[i], issues, '$path.expressions[$i]');
      }
    case FormatNumber():
      validateExpression(expr.numericValue, issues, '$path.numericValue');
    case PropertyName():
    case Literal():
      break;
  }
}

void _validateCategorize(
  Categorize expr,
  List<SldValidationIssue> issues,
  String path,
) {
  if (expr.values.length != expr.thresholds.length + 1) {
    issues.add(SldValidationIssue(
      severity: SldIssueSeverity.error,
      code: 'categorize-values-thresholds-mismatch',
      message:
          'Categorize requires values.length == thresholds.length + 1, '
          'got ${expr.values.length} values and ${expr.thresholds.length} thresholds',
      location: path,
    ));
  }
}

void _validateInterpolate(
  Interpolate expr,
  List<SldValidationIssue> issues,
  String path,
) {
  if (expr.dataPoints.length < 2) {
    issues.add(SldValidationIssue(
      severity: SldIssueSeverity.warning,
      code: 'interpolate-insufficient-points',
      message:
          'Interpolate should have at least 2 data points, '
          'got ${expr.dataPoints.length}',
      location: path,
    ));
  }

  // Check ascending order.
  for (var i = 1; i < expr.dataPoints.length; i++) {
    if (expr.dataPoints[i].data < expr.dataPoints[i - 1].data) {
      issues.add(SldValidationIssue(
        severity: SldIssueSeverity.warning,
        code: 'interpolate-unsorted-points',
        message:
            'InterpolationPoints should be sorted ascending by data value; '
            'point[$i] (${expr.dataPoints[i].data}) < '
            'point[${i - 1}] (${expr.dataPoints[i - 1].data})',
        location: '$path.dataPoints[$i]',
      ));
      break;
    }
  }
}

void _validateRecode(
  Recode expr,
  List<SldValidationIssue> issues,
  String path,
) {
  // Check for duplicate input values.
  final seen = <dynamic>{};
  for (var i = 0; i < expr.mappings.length; i++) {
    final input = expr.mappings[i].inputValue;
    if (input is Literal) {
      if (!seen.add(input.value)) {
        issues.add(SldValidationIssue(
          severity: SldIssueSeverity.warning,
          code: 'recode-duplicate-input',
          message: 'Recode has duplicate input value: ${input.value}',
          location: '$path.mappings[$i]',
        ));
      }
    }
  }
}
