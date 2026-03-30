import 'dart:convert';

import 'package:xml/xml.dart';

import '../model/issue.dart';
import '../model/layer.dart';
import '../model/sld_document.dart';
import 'parsers/layer_parser.dart';
import 'xml_helpers.dart';

/// Parses an SLD/SE XML string into an [SldParseResult].
///
/// Invalid XML is caught and returned as an error issue with a null document.
SldParseResult parseSldXmlString(String xml) {
  final XmlDocument xmlDoc;
  try {
    xmlDoc = XmlDocument.parse(xml);
  } on XmlException catch (e) {
    return SldParseResult(
      issues: [
        SldParseIssue(
          severity: SldIssueSeverity.error,
          code: 'invalid-xml',
          message: 'XML parsing failed: ${e.message}',
        ),
      ],
    );
  }

  return _parseXmlDocument(xmlDoc);
}

/// Parses SLD/SE from raw bytes (UTF-8 assumed).
SldParseResult parseSldBytes(List<int> bytes) {
  final String xml;
  try {
    xml = utf8.decode(bytes);
  } on FormatException catch (e) {
    return SldParseResult(
      issues: [
        SldParseIssue(
          severity: SldIssueSeverity.error,
          code: 'invalid-encoding',
          message: 'Failed to decode bytes as UTF-8: ${e.message}',
        ),
      ],
    );
  }

  return parseSldXmlString(xml);
}

// ---------------------------------------------------------------------------
// Internal
// ---------------------------------------------------------------------------

SldParseResult _parseXmlDocument(XmlDocument xmlDoc) {
  final issues = <SldParseIssue>[];
  final root = xmlDoc.rootElement;

  // Verify root element is StyledLayerDescriptor.
  if (root.localName != 'StyledLayerDescriptor') {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.error,
      code: 'unexpected-root',
      message:
          'Expected <StyledLayerDescriptor> as root, got <${root.localName}>',
      location: '/${root.localName}',
    ));
    return SldParseResult(issues: issues);
  }

  final version = stringAttr(root, 'version');
  const basePath = '/StyledLayerDescriptor';

  // Parse NamedLayer children.
  final layerElements = findChildren(root, 'NamedLayer');
  final layers = <SldLayer>[];

  for (var i = 0; i < layerElements.length; i++) {
    layers.add(
      parseNamedLayer(
        layerElements[i],
        issues,
        '$basePath/NamedLayer[${i + 1}]',
      ),
    );
  }

  if (layers.isEmpty) {
    issues.add(const SldParseIssue(
      severity: SldIssueSeverity.warning,
      code: 'no-layers',
      message: 'No <NamedLayer> elements found',
      location: '/StyledLayerDescriptor',
    ));
  }

  final document = SldDocument(version: version, layers: layers);
  return SldParseResult(document: document, issues: issues);
}
