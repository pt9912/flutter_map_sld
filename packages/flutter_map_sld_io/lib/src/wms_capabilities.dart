import 'package:xml/xml.dart';

/// A WMS layer as extracted from a GetCapabilities response.
class WmsLayerInfo {
  const WmsLayerInfo({
    required this.name,
    this.title,
    this.styles = const [],
  });

  /// The machine-readable layer name (used in GetMap requests).
  final String name;

  /// The human-readable layer title.
  final String? title;

  /// Available style names for this layer.
  final List<WmsStyleInfo> styles;
}

/// A named style available for a WMS layer.
class WmsStyleInfo {
  const WmsStyleInfo({
    required this.name,
    this.title,
  });

  /// The machine-readable style name.
  final String name;

  /// The human-readable style title.
  final String? title;
}

/// Parsed WMS GetCapabilities metadata.
class WmsCapabilities {
  const WmsCapabilities({
    this.version,
    this.title,
    required this.layers,
  });

  /// WMS version advertised by the server.
  final String? version;

  /// Service title.
  final String? title;

  /// Available layers with their styles.
  final List<WmsLayerInfo> layers;
}

/// Parses a WMS GetCapabilities XML response.
///
/// Extracts layer names, titles, and available styles. Works with both
/// WMS 1.1.1 and 1.3.0 responses.
///
/// Returns `null` if the XML is not a valid WMS Capabilities document.
WmsCapabilities? parseWmsCapabilities(String xml) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xml);
  } on XmlException {
    return null;
  }

  final root = doc.rootElement;
  if (!root.localName.contains('Capabilities')) return null;

  final version = root.getAttribute('version');
  final serviceEl = _findChild(root, 'Service');
  final title = serviceEl != null ? _childText(serviceEl, 'Title') : null;

  final capabilityEl = _findChild(root, 'Capability');
  if (capabilityEl == null) return const WmsCapabilities(layers: []);

  final layers = <WmsLayerInfo>[];
  _collectLayers(capabilityEl, layers);

  return WmsCapabilities(
    version: version,
    title: title,
    layers: layers,
  );
}

void _collectLayers(XmlElement parent, List<WmsLayerInfo> result) {
  for (final layerEl in parent.findElements('Layer')) {
    final name = _childText(layerEl, 'Name');
    if (name != null) {
      final title = _childText(layerEl, 'Title');
      final styles = <WmsStyleInfo>[];
      for (final styleEl in layerEl.findElements('Style')) {
        final styleName = _childText(styleEl, 'Name');
        if (styleName != null) {
          styles.add(WmsStyleInfo(
            name: styleName,
            title: _childText(styleEl, 'Title'),
          ));
        }
      }
      result.add(WmsLayerInfo(name: name, title: title, styles: styles));
    }
    // Recurse into nested layers.
    _collectLayers(layerEl, result);
  }
}

XmlElement? _findChild(XmlElement parent, String localName) {
  for (final child in parent.childElements) {
    if (child.localName == localName) return child;
  }
  return null;
}

String? _childText(XmlElement parent, String localName) {
  final child = _findChild(parent, localName);
  if (child == null) return null;
  final text = child.innerText.trim();
  return text.isEmpty ? null : text;
}
