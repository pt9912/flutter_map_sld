import 'package:flutter_map_sld_io/flutter_map_sld_io.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const _validSld = '''<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0"
    xmlns="http://www.opengis.net/sld">
  <NamedLayer>
    <Name>remote</Name>
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
  group('SldIo.parseUrl', () {
    test('loads and parses from HTTP 200', () async {
      final client = MockClient((_) async =>
          http.Response(_validSld, 200));

      final result = await SldIo.parseUrl(
        Uri.parse('http://example.com/style.sld'),
        client: client,
      );

      expect(result, isA<SldLoadSuccess>());
      final success = result as SldLoadSuccess;
      expect(success.parseResult.document, isNotNull);
      expect(success.parseResult.document!.layers.first.name, 'remote');
    });

    test('returns httpError for non-200 status', () async {
      final client = MockClient((_) async =>
          http.Response('Not Found', 404));

      final result = await SldIo.parseUrl(
        Uri.parse('http://example.com/missing.sld'),
        client: client,
      );

      expect(result, isA<SldLoadFailure>());
      final failure = result as SldLoadFailure;
      expect(failure.error.kind, SldLoadErrorKind.httpError);
      expect(failure.error.httpStatusCode, 404);
      expect(failure.error.uri?.host, 'example.com');
    });

    test('returns networkError on ClientException', () async {
      final client = MockClient((_) =>
          throw http.ClientException('Connection refused'));

      final result = await SldIo.parseUrl(
        Uri.parse('http://example.com/style.sld'),
        client: client,
      );

      expect(result, isA<SldLoadFailure>());
      final failure = result as SldLoadFailure;
      expect(failure.error.kind, SldLoadErrorKind.networkError);
      expect(failure.error.message, contains('Connection refused'));
    });

    test('returns encodingError for invalid UTF-8', () async {
      // 0xFF 0xFE is an invalid UTF-8 sequence.
      final client = MockClient((_) async =>
          http.Response.bytes([0xFF, 0xFE, 0x00], 200));

      final result = await SldIo.parseUrl(
        Uri.parse('http://example.com/broken.sld'),
        client: client,
      );

      expect(result, isA<SldLoadFailure>());
      final failure = result as SldLoadFailure;
      expect(failure.error.kind, SldLoadErrorKind.encodingError);
    });

    test('returns httpError for HTTP 500', () async {
      final client = MockClient((_) async =>
          http.Response('Internal Server Error', 500));

      final result = await SldIo.parseUrl(
        Uri.parse('http://example.com/error.sld'),
        client: client,
      );

      expect(result, isA<SldLoadFailure>());
      final failure = result as SldLoadFailure;
      expect(failure.error.kind, SldLoadErrorKind.httpError);
      expect(failure.error.httpStatusCode, 500);
    });
  });
}
