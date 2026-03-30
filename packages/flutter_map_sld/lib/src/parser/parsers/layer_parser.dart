import 'package:xml/xml.dart';

import '../../model/issue.dart';
import '../../model/layer.dart';
import '../../model/style.dart';
import '../xml_helpers.dart';
import 'style_parser.dart';

/// Parses a `<NamedLayer>` element.
SldLayer parseNamedLayer(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final name = childText(element, 'Name');
  final styleElements = findChildren(element, 'UserStyle');
  final styles = <UserStyle>[];

  for (var i = 0; i < styleElements.length; i++) {
    styles.add(
      parseUserStyle(
        styleElements[i],
        issues,
        '$path/UserStyle[${i + 1}]',
      ),
    );
  }

  return SldLayer(name: name, styles: styles);
}
