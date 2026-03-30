import '../model/issue.dart';

/// The result of validating a parsed [SldDocument].
///
/// Validation is separate from parsing: the parser reports structural and
/// syntax problems ([SldParseIssue]), while validation reports domain-level
/// rules and support status ([SldValidationIssue]).
class SldValidationResult {
  SldValidationResult({
    List<SldValidationIssue> issues = const [],
  }) : issues = List.unmodifiable(issues);

  /// Validation issues found (unmodifiable).
  final List<SldValidationIssue> issues;

  /// Whether any issue has severity [SldIssueSeverity.error].
  bool get hasErrors =>
      issues.any((issue) => issue.severity == SldIssueSeverity.error);

  /// Whether any issue has severity [SldIssueSeverity.warning] or higher.
  bool get hasWarnings => issues.any(
        (issue) =>
            issue.severity == SldIssueSeverity.error ||
            issue.severity == SldIssueSeverity.warning,
      );
}
