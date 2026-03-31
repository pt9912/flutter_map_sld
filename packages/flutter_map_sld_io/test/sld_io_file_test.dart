import 'dart:io';

import 'package:flutter_map_sld_io/flutter_map_sld_io.dart';
import 'package:test/test.dart';

const _validSld = '''<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0"
    xmlns="http://www.opengis.net/sld">
  <NamedLayer>
    <Name>test</Name>
    <UserStyle>
      <FeatureTypeStyle>
        <Rule>
          <RasterSymbolizer>
            <ColorMap>
              <ColorMapEntry color="#000000" quantity="0"/>
              <ColorMapEntry color="#FFFFFF" quantity="100"/>
            </ColorMap>
          </RasterSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>''';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('sld_io_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('SldIo.parseFile', () {
    test('loads and parses a valid SLD file', () async {
      final file = File('${tempDir.path}/test.sld');
      file.writeAsStringSync(_validSld);

      final result = await SldIo.parseFile(file.path);

      expect(result, isA<SldLoadSuccess>());
      final success = result as SldLoadSuccess;
      expect(success.parseResult.document, isNotNull);
      expect(success.parseResult.document!.layers, hasLength(1));
      expect(success.parseResult.document!.layers.first.name, 'test');
    });

    test('returns fileNotFound for non-existent path', () async {
      final result = await SldIo.parseFile('${tempDir.path}/no_such_file.sld');

      expect(result, isA<SldLoadFailure>());
      final failure = result as SldLoadFailure;
      expect(failure.error.kind, SldLoadErrorKind.fileNotFound);
      expect(failure.error.uri, isNotNull);
    });

    test('successfully parses UTF-8 bytes', () async {
      final file = File('${tempDir.path}/utf8.sld');
      file.writeAsBytesSync(_validSld.codeUnits);

      final result = await SldIo.parseFile(file.path);

      expect(result, isA<SldLoadSuccess>());
    });
  });
}
