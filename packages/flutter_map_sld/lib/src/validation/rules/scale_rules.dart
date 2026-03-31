import '../../model/issue.dart';
import '../../model/rule.dart';

/// Validates scale denominator bounds on a [Rule].
void validateScaleDenominators(
  Rule rule,
  List<SldValidationIssue> issues,
  String path,
) {
  final min = rule.minScaleDenominator;
  final max = rule.maxScaleDenominator;

  if (min != null && max != null && min >= max) {
    issues.add(SldValidationIssue(
      severity: SldIssueSeverity.error,
      code: 'empty-scale-range',
      message: 'minScaleDenominator ($min) >= maxScaleDenominator ($max) — '
          'rule can never match',
      location: path,
    ));
  }
}
