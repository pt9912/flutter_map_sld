import '_equality.dart';
import 'channel_selection.dart';
import 'color_map.dart';
import 'contrast_enhancement.dart';
import 'extension_node.dart';
import 'shaded_relief.dart';
import 'vendor_option.dart';

/// Styling parameters for raster data.
class RasterSymbolizer {
  RasterSymbolizer({
    this.opacity,
    this.channelSelection,
    this.colorMap,
    this.contrastEnhancement,
    this.shadedRelief,
    List<VendorOption> vendorOptions = const [],
    List<ExtensionNode> extensions = const [],
  })  : vendorOptions = List.unmodifiable(vendorOptions),
        extensions = List.unmodifiable(extensions);

  /// Overall opacity from 0.0 (transparent) to 1.0 (opaque).
  final double? opacity;

  /// Channel (band) selection for multi-band raster data.
  final ChannelSelection? channelSelection;

  /// Color mapping for raster values.
  final ColorMap? colorMap;

  /// Contrast enhancement parameters.
  final ContrastEnhancement? contrastEnhancement;

  /// Shaded relief rendering parameters.
  final ShadedRelief? shadedRelief;

  /// Parsed `<VendorOption>` elements (unmodifiable).
  final List<VendorOption> vendorOptions;

  /// Unrecognized child elements preserved for debugging or future use
  /// (unmodifiable).
  final List<ExtensionNode> extensions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RasterSymbolizer &&
          opacity == other.opacity &&
          channelSelection == other.channelSelection &&
          colorMap == other.colorMap &&
          contrastEnhancement == other.contrastEnhancement &&
          shadedRelief == other.shadedRelief &&
          deepListEquals(vendorOptions, other.vendorOptions) &&
          deepListEquals(extensions, other.extensions);

  @override
  int get hashCode => Object.hash(
        opacity,
        channelSelection,
        colorMap,
        contrastEnhancement,
        shadedRelief,
        Object.hashAll(vendorOptions),
        Object.hashAll(extensions),
      );
}
