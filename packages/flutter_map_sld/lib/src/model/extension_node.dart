import '_equality.dart';

/// Represents an unknown or vendor-specific XML element preserved during parsing.
///
/// Unknown XML subtrees are fully conserved so that debugging and future
/// feature extensions remain possible without re-parsing.
class ExtensionNode {
  ExtensionNode({
    required this.namespaceUri,
    required this.localName,
    Map<String, String> attributes = const {},
    this.text,
    this.rawXml = '',
    List<ExtensionNode> children = const [],
  })  : attributes = Map.unmodifiable(attributes),
        children = List.unmodifiable(children);

  /// The namespace URI of the element.
  final String namespaceUri;

  /// The local (unprefixed) element name.
  final String localName;

  /// Attributes on this element (unmodifiable).
  final Map<String, String> attributes;

  /// Text content of this element, if any.
  final String? text;

  /// The raw XML source of this element and its subtree.
  final String rawXml;

  /// Child extension nodes (unmodifiable).
  final List<ExtensionNode> children;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtensionNode &&
          namespaceUri == other.namespaceUri &&
          localName == other.localName &&
          deepMapEquals(attributes, other.attributes) &&
          text == other.text &&
          rawXml == other.rawXml &&
          deepListEquals(children, other.children);

  @override
  int get hashCode => Object.hash(
        namespaceUri,
        localName,
        Object.hashAll(
          attributes.entries.map((e) => Object.hash(e.key, e.value)),
        ),
        text,
        rawXml,
        Object.hashAll(children),
      );
}
