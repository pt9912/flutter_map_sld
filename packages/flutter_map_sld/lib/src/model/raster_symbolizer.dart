import '_equality.dart';
import 'color_map.dart';
import 'contrast_enhancement.dart';
import 'extension_node.dart';

/// Styling parameters for raster data.
class RasterSymbolizer {
  RasterSymbolizer({
    this.opacity,
    this.colorMap,
    this.contrastEnhancement,
    List<ExtensionNode> extensions = const [],
  }) : extensions = List.unmodifiable(extensions);

  /// Overall opacity from 0.0 (transparent) to 1.0 (opaque).
  final double? opacity;

  /// Color mapping for raster values.
  final ColorMap? colorMap;

  /// Contrast enhancement parameters.
  final ContrastEnhancement? contrastEnhancement;

  /// Unrecognized child elements preserved for debugging or future use
  /// (unmodifiable).
  final List<ExtensionNode> extensions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RasterSymbolizer &&
          opacity == other.opacity &&
          colorMap == other.colorMap &&
          contrastEnhancement == other.contrastEnhancement &&
          deepListEquals(extensions, other.extensions);

  @override
  int get hashCode =>
      Object.hash(opacity, colorMap, contrastEnhancement, Object.hashAll(extensions));
}
