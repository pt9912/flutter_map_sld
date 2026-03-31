import 'layer.dart';
import 'rule.dart';
import 'style.dart';

/// A rule matched by `SldDocument.selectMatchingRules`, together with its
/// layer/style/feature-type-style context.
class MatchedRule {
  const MatchedRule({
    required this.layer,
    required this.style,
    required this.featureTypeStyle,
    required this.rule,
  });

  /// The layer this rule belongs to.
  final SldLayer layer;

  /// The user style this rule belongs to.
  final UserStyle style;

  /// The feature type style this rule belongs to.
  final FeatureTypeStyle featureTypeStyle;

  /// The matched rule.
  final Rule rule;
}
