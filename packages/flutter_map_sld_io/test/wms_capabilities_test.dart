import 'package:flutter_map_sld_io/flutter_map_sld_io.dart';
import 'package:test/test.dart';

const _capabilities111 = '''<?xml version="1.0" encoding="UTF-8"?>
<WMT_MS_Capabilities version="1.1.1">
  <Service>
    <Title>GeoServer WMS</Title>
  </Service>
  <Capability>
    <Layer>
      <Title>All Layers</Title>
      <Layer queryable="1">
        <Name>dem</Name>
        <Title>Digital Elevation Model</Title>
        <Style>
          <Name>elevation</Name>
          <Title>Elevation Style</Title>
        </Style>
        <Style>
          <Name>contour</Name>
          <Title>Contour Lines</Title>
        </Style>
      </Layer>
      <Layer queryable="1">
        <Name>roads</Name>
        <Title>Road Network</Title>
        <Style>
          <Name>default</Name>
          <Title>Default</Title>
        </Style>
      </Layer>
    </Layer>
  </Capability>
</WMT_MS_Capabilities>''';

const _capabilities130 = '''<?xml version="1.0" encoding="UTF-8"?>
<WMS_Capabilities version="1.3.0"
    xmlns="http://www.opengis.net/wms">
  <Service>
    <Title>Test WMS 1.3.0</Title>
  </Service>
  <Capability>
    <Layer>
      <Layer>
        <Name>satellite</Name>
        <Title>Satellite Imagery</Title>
        <Style>
          <Name>natural</Name>
        </Style>
      </Layer>
    </Layer>
  </Capability>
</WMS_Capabilities>''';

void main() {
  group('parseWmsCapabilities', () {
    test('parses WMS 1.1.1 capabilities', () {
      final caps = parseWmsCapabilities(_capabilities111);

      expect(caps, isNotNull);
      expect(caps!.version, '1.1.1');
      expect(caps.title, 'GeoServer WMS');
      expect(caps.layers, hasLength(2));

      expect(caps.layers[0].name, 'dem');
      expect(caps.layers[0].title, 'Digital Elevation Model');
      expect(caps.layers[0].styles, hasLength(2));
      expect(caps.layers[0].styles[0].name, 'elevation');
      expect(caps.layers[0].styles[1].name, 'contour');

      expect(caps.layers[1].name, 'roads');
      expect(caps.layers[1].styles, hasLength(1));
    });

    test('parses WMS 1.3.0 capabilities', () {
      final caps = parseWmsCapabilities(_capabilities130);

      expect(caps, isNotNull);
      expect(caps!.version, '1.3.0');
      expect(caps.title, 'Test WMS 1.3.0');
      expect(caps.layers, hasLength(1));
      expect(caps.layers[0].name, 'satellite');
      expect(caps.layers[0].styles[0].name, 'natural');
    });

    test('returns null for invalid XML', () {
      expect(parseWmsCapabilities('not xml'), isNull);
    });

    test('returns null for non-capabilities XML', () {
      expect(
        parseWmsCapabilities('<html><body/></html>'),
        isNull,
      );
    });
  });
}
