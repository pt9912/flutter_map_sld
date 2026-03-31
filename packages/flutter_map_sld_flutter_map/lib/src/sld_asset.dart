import 'package:flutter/services.dart';
import 'package:flutter_map_sld/flutter_map_sld.dart';

/// Loads and parses SLD/SE documents from Flutter asset bundles.
class SldAsset {
  const SldAsset._();

  /// Parses an SLD/SE document from a Flutter asset at [assetPath].
  ///
  /// Uses the default [rootBundle] unless a custom [bundle] is provided
  /// (useful for testing).
  ///
  /// Example:
  /// ```dart
  /// final result = await SldAsset.parseFromAsset('assets/style.sld');
  /// ```
  static Future<SldParseResult> parseFromAsset(
    String assetPath, {
    AssetBundle? bundle,
  }) async {
    final b = bundle ?? rootBundle;
    final data = await b.load(assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    return SldDocument.parseBytes(bytes);
  }
}
