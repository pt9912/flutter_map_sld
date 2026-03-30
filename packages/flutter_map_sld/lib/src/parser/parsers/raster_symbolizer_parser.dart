import 'package:xml/xml.dart';

import '../../model/color_map.dart';
import '../../model/contrast_enhancement.dart';
import '../../model/extension_node.dart';
import '../../model/issue.dart';
import '../../model/raster_symbolizer.dart';
import '../xml_helpers.dart';

/// Known child element names within a RasterSymbolizer.
const _knownRasterChildren = {
  'Opacity',
  'ColorMap',
  'ContrastEnhancement',
  'ChannelSelection',
  'ShadedRelief',
  'ImageOutline',
  'Geometry',
  'OverlapBehavior',
};

/// Known child element names within a ColorMap.
const _knownColorMapChildren = {'ColorMapEntry'};

// ---------------------------------------------------------------------------
// ColorMapEntry
// ---------------------------------------------------------------------------

/// Parses a `<ColorMapEntry>` element.
///
/// Returns `null` and adds an issue if the required `color` attribute is
/// missing or unparseable.
ColorMapEntry? parseColorMapEntry(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final colorRaw = stringAttr(element, 'color');
  final colorArgb = parseColorHex(colorRaw);
  if (colorArgb == null) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.error,
      code: 'invalid-color',
      message: 'Missing or invalid color attribute: "$colorRaw"',
      location: path,
    ));
    return null;
  }

  final quantity = doubleAttr(element, 'quantity');
  if (quantity == null) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.error,
      code: 'invalid-quantity',
      message: 'Missing or invalid quantity attribute',
      location: path,
    ));
    return null;
  }

  final opacity = doubleAttr(element, 'opacity') ?? 1.0;
  final label = stringAttr(element, 'label');

  return ColorMapEntry(
    colorArgb: colorArgb,
    quantity: quantity,
    opacity: opacity,
    label: label,
  );
}

// ---------------------------------------------------------------------------
// ColorMap
// ---------------------------------------------------------------------------

/// Parses a `<ColorMap>` element.
ColorMap? parseColorMap(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  final typeRaw = stringAttr(element, 'type');
  final type = _parseColorMapType(typeRaw);

  final entryElements = findChildren(element, 'ColorMapEntry');
  final entries = <ColorMapEntry>[];

  for (var i = 0; i < entryElements.length; i++) {
    final entry = parseColorMapEntry(
      entryElements[i],
      issues,
      '$path/ColorMapEntry[${i + 1}]',
    );
    if (entry != null) {
      entries.add(entry);
    }
  }

  // Report unknown children within ColorMap.
  for (final child in element.childElements) {
    if (!_knownColorMapChildren.contains(child.localName)) {
      issues.add(SldParseIssue(
        severity: SldIssueSeverity.info,
        code: 'unknown-element',
        message: 'Unknown element in ColorMap: <${child.localName}>',
        location: '$path/${child.localName}',
      ));
    }
  }

  return ColorMap(type: type, entries: entries);
}

ColorMapType _parseColorMapType(String? raw) => switch (raw) {
      'intervals' => ColorMapType.intervals,
      'values' => ColorMapType.exactValues,
      _ => ColorMapType.ramp,
    };

// ---------------------------------------------------------------------------
// ContrastEnhancement
// ---------------------------------------------------------------------------

/// Parses a `<ContrastEnhancement>` element.
ContrastEnhancement parseContrastEnhancement(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  ContrastMethod? method;

  if (findChild(element, 'Normalize') != null) {
    method = ContrastMethod.normalize;
  } else if (findChild(element, 'Histogram') != null) {
    method = ContrastMethod.histogram;
  }

  final gammaText = childText(element, 'GammaValue');
  final gammaValue = gammaText != null ? double.tryParse(gammaText) : null;

  if (gammaText != null && gammaValue == null) {
    issues.add(SldParseIssue(
      severity: SldIssueSeverity.warning,
      code: 'invalid-gamma',
      message: 'Invalid GammaValue: "$gammaText"',
      location: '$path/GammaValue',
    ));
  }

  return ContrastEnhancement(method: method, gammaValue: gammaValue);
}

// ---------------------------------------------------------------------------
// RasterSymbolizer
// ---------------------------------------------------------------------------

/// Parses a `<RasterSymbolizer>` element.
RasterSymbolizer parseRasterSymbolizer(
  XmlElement element,
  List<SldParseIssue> issues,
  String path,
) {
  // Opacity
  final opacityText = childText(element, 'Opacity');
  double? opacity;
  if (opacityText != null) {
    opacity = double.tryParse(opacityText);
    if (opacity == null) {
      issues.add(SldParseIssue(
        severity: SldIssueSeverity.warning,
        code: 'invalid-opacity',
        message: 'Invalid Opacity value: "$opacityText"',
        location: '$path/Opacity',
      ));
    }
  }

  // ColorMap
  final colorMapEl = findChild(element, 'ColorMap');
  final colorMap = colorMapEl != null
      ? parseColorMap(colorMapEl, issues, '$path/ColorMap')
      : null;

  // ContrastEnhancement
  final ceEl = findChild(element, 'ContrastEnhancement');
  final contrastEnhancement = ceEl != null
      ? parseContrastEnhancement(ceEl, issues, '$path/ContrastEnhancement')
      : null;

  // Collect unknown children as ExtensionNodes.
  final extensions = <ExtensionNode>[];
  for (final child in element.childElements) {
    if (!_knownRasterChildren.contains(child.localName)) {
      extensions.add(_toExtensionNode(child));
      issues.add(SldParseIssue(
        severity: SldIssueSeverity.info,
        code: 'unknown-element',
        message:
            'Unknown element in RasterSymbolizer: <${child.localName}>',
        location: '$path/${child.localName}',
      ));
    }
  }

  return RasterSymbolizer(
    opacity: opacity,
    colorMap: colorMap,
    contrastEnhancement: contrastEnhancement,
    extensions: extensions,
  );
}

// ---------------------------------------------------------------------------
// ExtensionNode builder
// ---------------------------------------------------------------------------

ExtensionNode _toExtensionNode(XmlElement element) {
  final attributes = <String, String>{};
  for (final attr in element.attributes) {
    attributes[attr.localName] = attr.value;
  }

  return ExtensionNode(
    namespaceUri: element.namespaceUri ?? '',
    localName: element.localName,
    attributes: attributes,
    text: element.innerText.trim().isEmpty ? null : element.innerText.trim(),
    rawXml: element.toXmlString(),
    children: element.childElements.map(_toExtensionNode).toList(),
  );
}
