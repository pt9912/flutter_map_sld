import 'package:xml/xml.dart';

import '../../model/issue.dart';
import '../../model/style.dart';
import '../xml_helpers.dart';
import 'rule_parser.dart';

/// Parses a `<UserStyle>` element.
UserStyle parseUserStyle(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final name = childText(element, 'Name');
  final ftsElements = findChildren(element, 'FeatureTypeStyle');
  final featureTypeStyles = <FeatureTypeStyle>[];

  for (var i = 0; i < ftsElements.length; i++) {
    featureTypeStyles.add(
      parseFeatureTypeStyle(
        ftsElements[i],
        issues,
        '$path/FeatureTypeStyle[${i + 1}]',
      ),
    );
  }

  return UserStyle(name: name, featureTypeStyles: featureTypeStyles);
}

/// Parses a `<FeatureTypeStyle>` element.
FeatureTypeStyle parseFeatureTypeStyle(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final ruleElements = findChildren(element, 'Rule');
  final rules = <dynamic>[];

  for (var i = 0; i < ruleElements.length; i++) {
    rules.add(parseRule(ruleElements[i], issues, '$path/Rule[${i + 1}]'));
  }

  return FeatureTypeStyle(rules: rules.cast());
}
