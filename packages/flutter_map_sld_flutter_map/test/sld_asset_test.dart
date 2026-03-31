import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_map_sld_flutter_map/flutter_map_sld_flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

const _validSld = '<?xml version="1.0" encoding="UTF-8"?>'
    '<StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld">'
    '<NamedLayer><Name>test</Name><UserStyle><FeatureTypeStyle>'
    '<Rule><RasterSymbolizer><ColorMap>'
    '<ColorMapEntry color="#000000" quantity="0"/>'
    '</ColorMap></RasterSymbolizer></Rule>'
    '</FeatureTypeStyle></UserStyle></NamedLayer>'
    '</StyledLayerDescriptor>';

/// A fake [AssetBundle] that serves a single SLD document.
class _TestBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = utf8.encode(_validSld);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

void main() {
  group('SldAsset', () {
    test('parseFromAsset loads and parses SLD from asset bundle', () async {
      final result = await SldAsset.parseFromAsset(
        'assets/style.sld',
        bundle: _TestBundle(),
      );

      expect(result.hasErrors, isFalse);
      expect(result.document, isNotNull);
      expect(result.document!.layers.first.name, 'test');
    });
  });
}
