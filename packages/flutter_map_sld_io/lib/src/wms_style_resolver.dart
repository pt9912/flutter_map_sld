import 'package:flutter_map_sld/flutter_map_sld.dart';

import 'wms_capabilities.dart';

/// A resolved association between a WMS layer and its matched SLD style.
class ResolvedWmsStyle {
  /// Creates a resolved style associating a WMS [layerInfo] with an optional
  /// SLD [sldLayer] and [userStyle].
  const ResolvedWmsStyle({
    required this.layerInfo,
    required this.styleName,
    this.sldLayer,
    this.userStyle,
  });

  /// The WMS layer metadata from GetCapabilities.
  final WmsLayerInfo layerInfo;

  /// The style name used in the WMS request.
  final String styleName;

  /// The matching SLD layer, if found (matched by layer name).
  final SldLayer? sldLayer;

  /// The matching SLD UserStyle, if found (matched by style name within
  /// the resolved SLD layer).
  final UserStyle? userStyle;
}

/// Resolves WMS layer/style associations against parsed SLD documents.
///
/// Matches at two levels:
/// 1. WMS layer name → SLD `NamedLayer` name
/// 2. WMS style name → SLD `UserStyle` name within that layer
class WmsStyleResolver {
  const WmsStyleResolver();

  /// Resolves WMS layers from [capabilities] against layers in [document].
  ///
  /// For each WMS layer, attempts to find:
  /// - An SLD layer with the same name ([WmsLayerInfo.name] = [SldLayer.name])
  /// - A UserStyle within that SLD layer matching the style name
  ///
  /// If [styleName] is provided, only resolves layers that advertise
  /// that style. Otherwise, resolves all named layers using their first
  /// advertised style.
  List<ResolvedWmsStyle> resolve(
    WmsCapabilities capabilities,
    SldDocument document, {
    String? styleName,
  }) {
    final sldLayersByName = <String, SldLayer>{};
    for (final layer in document.layers) {
      final name = layer.name;
      if (name != null) {
        sldLayersByName[name] = layer;
      }
    }

    final result = <ResolvedWmsStyle>[];
    for (final wmsLayer in capabilities.layers) {
      if (styleName != null) {
        final hasStyle =
            wmsLayer.styles.any((s) => s.name == styleName);
        if (!hasStyle) continue;
      }

      final sldLayer = sldLayersByName[wmsLayer.name];
      final resolvedStyleName = styleName ??
          (wmsLayer.styles.isNotEmpty ? wmsLayer.styles.first.name : '');

      // Match UserStyle by name within the SLD layer.
      UserStyle? userStyle;
      if (sldLayer != null && resolvedStyleName.isNotEmpty) {
        for (final style in sldLayer.styles) {
          if (style.name == resolvedStyleName) {
            userStyle = style;
            break;
          }
        }
      }

      result.add(ResolvedWmsStyle(
        layerInfo: wmsLayer,
        styleName: resolvedStyleName,
        sldLayer: sldLayer,
        userStyle: userStyle,
      ));
    }

    return result;
  }
}
