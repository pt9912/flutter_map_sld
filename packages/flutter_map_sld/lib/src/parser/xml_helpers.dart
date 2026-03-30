import 'package:xml/xml.dart';

// ---------------------------------------------------------------------------
// SLD / SE namespace constants
// ---------------------------------------------------------------------------

/// OGC SLD namespace (used in SLD 1.0 and 1.1).
const sldNamespace = 'http://www.opengis.net/sld';

/// OGC Symbology Encoding namespace (used in SLD 1.1 / SE 1.1).
const seNamespace = 'http://www.opengis.net/se';

/// All namespaces to search when looking for SLD/SE elements.
/// Order: SE first (more specific), then SLD, then empty (unprefixed).
const _sldSeNamespaces = [seNamespace, sldNamespace, ''];

// ---------------------------------------------------------------------------
// Namespace-aware element lookup
// ---------------------------------------------------------------------------

/// Finds the first direct child element with the given [localName] across
/// SLD, SE, and unprefixed namespaces.
///
/// Returns `null` if no matching child is found.
XmlElement? findChild(XmlElement parent, String localName) {
  for (final ns in _sldSeNamespaces) {
    final found = parent.getElement(localName, namespace: ns.isEmpty ? null : ns);
    if (found != null) return found;
  }
  // Fallback: match by local name only, ignoring namespace.
  for (final child in parent.childElements) {
    if (child.localName == localName) return child;
  }
  return null;
}

/// Finds all direct child elements with the given [localName] across
/// SLD, SE, and unprefixed namespaces.
List<XmlElement> findChildren(XmlElement parent, String localName) {
  final seen = <XmlElement>{};
  for (final ns in _sldSeNamespaces) {
    final found = parent.findElements(localName, namespace: ns.isEmpty ? null : ns);
    seen.addAll(found);
  }
  // Fallback: also include local-name-only matches.
  for (final child in parent.childElements) {
    if (child.localName == localName) {
      seen.add(child);
    }
  }
  return seen.toList();
}

// ---------------------------------------------------------------------------
// Text and attribute extraction
// ---------------------------------------------------------------------------

/// Returns the trimmed text content of a direct child element with the given
/// [localName], or `null` if the child does not exist or has no text.
String? childText(XmlElement parent, String localName) {
  final child = findChild(parent, localName);
  if (child == null) return null;
  final text = child.innerText.trim();
  return text.isEmpty ? null : text;
}

/// Returns the value of the attribute [name] on [element], or `null` if
/// the attribute does not exist.
String? stringAttr(XmlElement element, String name) =>
    element.getAttribute(name);

/// Parses the attribute [name] on [element] as a `double`.
///
/// Returns `null` if the attribute is missing or not a valid number.
double? doubleAttr(XmlElement element, String name) {
  final raw = element.getAttribute(name);
  if (raw == null) return null;
  return double.tryParse(raw);
}

// ---------------------------------------------------------------------------
// Color parsing
// ---------------------------------------------------------------------------

/// Parses a CSS-style hex color string to an ARGB integer.
///
/// Supports:
/// - `#RRGGBB` → fully opaque (`0xFFRRGGBB`)
/// - `#AARRGGBB` → with alpha
/// - `0xRRGGBB` / `0xAARRGGBB` — same as above, with `0x` prefix
///
/// Returns `null` if the input is not a recognized format.
int? parseColorHex(String? raw) {
  if (raw == null) return null;
  var s = raw.trim();

  // Strip leading # or 0x.
  if (s.startsWith('#')) {
    s = s.substring(1);
  } else if (s.toLowerCase().startsWith('0x')) {
    s = s.substring(2);
  } else {
    return null;
  }

  // 6-digit: RRGGBB → add FF alpha.
  if (s.length == 6) {
    return int.tryParse('FF$s', radix: 16);
  }

  // 8-digit: AARRGGBB.
  if (s.length == 8) {
    return int.tryParse(s, radix: 16);
  }

  return null;
}
