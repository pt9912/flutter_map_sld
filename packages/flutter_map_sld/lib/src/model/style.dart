import '_equality.dart';
import 'rule.dart';

/// A named style applied to a layer, containing one or more
/// [FeatureTypeStyle] blocks.
class UserStyle {
  UserStyle({
    this.name,
    required List<FeatureTypeStyle> featureTypeStyles,
  }) : featureTypeStyles = List.unmodifiable(featureTypeStyles);

  /// Optional style name.
  final String? name;

  /// Feature type styles within this user style (unmodifiable).
  final List<FeatureTypeStyle> featureTypeStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStyle &&
          name == other.name &&
          deepListEquals(featureTypeStyles, other.featureTypeStyles);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(featureTypeStyles));
}

/// Groups rules that apply to a specific feature type.
class FeatureTypeStyle {
  FeatureTypeStyle({
    required List<Rule> rules,
  }) : rules = List.unmodifiable(rules);

  /// The rules within this feature type style (unmodifiable).
  final List<Rule> rules;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeatureTypeStyle && deepListEquals(rules, other.rules);

  @override
  int get hashCode => Object.hashAll(rules);
}
