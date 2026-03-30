import 'dart:convert';

import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:test/test.dart';

void main() {
  // -----------------------------------------------------------------------
  // Invalid input
  // -----------------------------------------------------------------------
  group('invalid input', () {
    test('invalid XML returns error issue', () {
      final result = SldDocument.parseXmlString('<not closed');

      expect(result.hasErrors, isTrue);
      expect(result.document, isNull);
      expect(result.issues.first.code, 'invalid-xml');
    });

    test('wrong root element returns error issue', () {
      final result = SldDocument.parseXmlString('<Something/>');

      expect(result.hasErrors, isTrue);
      expect(result.document, isNull);
      expect(result.issues.first.code, 'unexpected-root');
    });

    test('parseBytes handles invalid UTF-8', () {
      final result = SldDocument.parseBytes([0xFF, 0xFE, 0x00]);

      expect(result.hasErrors, isTrue);
      expect(result.document, isNull);
      expect(result.issues.first.code, 'invalid-encoding');
    });

    test('parseBytes works with valid UTF-8', () {
      const xml = '<StyledLayerDescriptor version="1.0.0">'
          '<NamedLayer><Name>L</Name></NamedLayer>'
          '</StyledLayerDescriptor>';
      final result = SldDocument.parseBytes(utf8.encode(xml));

      expect(result.hasErrors, isFalse);
      expect(result.document, isNotNull);
      expect(result.document!.layers.first.name, 'L');
    });
  });

  // -----------------------------------------------------------------------
  // Empty / minimal documents
  // -----------------------------------------------------------------------
  group('minimal documents', () {
    test('empty StyledLayerDescriptor warns about no layers', () {
      final result = SldDocument.parseXmlString(
        '<StyledLayerDescriptor version="1.0.0"/>',
      );

      expect(result.hasErrors, isFalse);
      expect(result.document, isNotNull);
      expect(result.document!.version, '1.0.0');
      expect(result.document!.layers, isEmpty);
      expect(result.issues.any((i) => i.code == 'no-layers'), isTrue);
    });

    test('parses version attribute', () {
      final result = SldDocument.parseXmlString(
        '<StyledLayerDescriptor version="1.1.0">'
        '<NamedLayer><Name>X</Name></NamedLayer>'
        '</StyledLayerDescriptor>',
      );

      expect(result.document!.version, '1.1.0');
    });
  });

  // -----------------------------------------------------------------------
  // Full SLD 1.0 document (unprefixed)
  // -----------------------------------------------------------------------
  group('SLD 1.0 unprefixed', () {
    test('parses two-color gradient', () {
      final result = SldDocument.parseXmlString(_twoColorGradientSld10);

      expect(result.hasErrors, isFalse);
      expect(result.document, isNotNull);

      final doc = result.document!;
      expect(doc.version, '1.0.0');
      expect(doc.layers, hasLength(1));
      expect(doc.layers.first.name, 'DEM');

      final rs = doc.selectRasterSymbolizers();
      expect(rs, hasLength(1));
      expect(rs.first.opacity, isNull);

      final cm = rs.first.colorMap;
      expect(cm, isNotNull);
      expect(cm!.type, ColorMapType.ramp);
      expect(cm.entries, hasLength(2));
      expect(cm.entries[0].colorArgb, 0xFF000000);
      expect(cm.entries[0].quantity, 0.0);
      expect(cm.entries[1].colorArgb, 0xFFFFFFFF);
      expect(cm.entries[1].quantity, 100.0);
    });
  });

  // -----------------------------------------------------------------------
  // SLD 1.0 with sld: prefix
  // -----------------------------------------------------------------------
  group('SLD 1.0 sld-prefixed', () {
    test('parses sld-prefixed document', () {
      final result = SldDocument.parseXmlString(_sldPrefixedDocument);

      expect(result.hasErrors, isFalse);
      final doc = result.document!;
      expect(doc.layers, hasLength(1));
      expect(doc.layers.first.name, 'Raster');

      final rs = doc.selectRasterSymbolizers();
      expect(rs, hasLength(1));
      expect(rs.first.opacity, 0.75);
      expect(rs.first.colorMap!.entries, hasLength(2));
    });
  });

  // -----------------------------------------------------------------------
  // SLD 1.1 / SE with se: prefix
  // -----------------------------------------------------------------------
  group('SLD 1.1 SE-prefixed', () {
    test('parses se-prefixed document', () {
      final result = SldDocument.parseXmlString(_sePrefixedDocument);

      expect(result.hasErrors, isFalse);
      final doc = result.document!;
      expect(doc.version, '1.1.0');
      expect(doc.layers.first.name, 'Elevation');

      final rs = doc.selectRasterSymbolizers();
      expect(rs, hasLength(1));
      expect(rs.first.colorMap!.type, ColorMapType.intervals);
      expect(rs.first.colorMap!.entries, hasLength(3));
      expect(rs.first.contrastEnhancement?.method, ContrastMethod.normalize);
    });
  });

  // -----------------------------------------------------------------------
  // End-to-end: selectRasterSymbolizers across multiple layers
  // -----------------------------------------------------------------------
  group('multi-layer', () {
    test('collects raster symbolizers from all layers', () {
      final result = SldDocument.parseXmlString(_multiLayerSld);

      expect(result.hasErrors, isFalse);
      final doc = result.document!;
      expect(doc.layers, hasLength(2));
      expect(doc.selectRasterSymbolizers(), hasLength(2));
    });
  });
}

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

const _twoColorGradientSld10 = '''
<StyledLayerDescriptor version="1.0.0">
  <NamedLayer>
    <Name>DEM</Name>
    <UserStyle>
      <Name>TwoColor</Name>
      <FeatureTypeStyle>
        <Rule>
          <RasterSymbolizer>
            <ColorMap>
              <ColorMapEntry color="#000000" quantity="0" opacity="1.0"/>
              <ColorMapEntry color="#FFFFFF" quantity="100" opacity="1.0"/>
            </ColorMap>
          </RasterSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
''';

const _sldPrefixedDocument = '''
<sld:StyledLayerDescriptor version="1.0.0"
    xmlns:sld="http://www.opengis.net/sld">
  <sld:NamedLayer>
    <sld:Name>Raster</sld:Name>
    <sld:UserStyle>
      <sld:Name>RasterStyle</sld:Name>
      <sld:FeatureTypeStyle>
        <sld:Rule>
          <sld:RasterSymbolizer>
            <sld:Opacity>0.75</sld:Opacity>
            <sld:ColorMap>
              <sld:ColorMapEntry color="#FF0000" quantity="0"/>
              <sld:ColorMapEntry color="#00FF00" quantity="100"/>
            </sld:ColorMap>
          </sld:RasterSymbolizer>
        </sld:Rule>
      </sld:FeatureTypeStyle>
    </sld:UserStyle>
  </sld:NamedLayer>
</sld:StyledLayerDescriptor>
''';

const _sePrefixedDocument = '''
<sld:StyledLayerDescriptor version="1.1.0"
    xmlns:sld="http://www.opengis.net/sld"
    xmlns:se="http://www.opengis.net/se">
  <sld:NamedLayer>
    <se:Name>Elevation</se:Name>
    <sld:UserStyle>
      <se:Name>ElevationStyle</se:Name>
      <se:FeatureTypeStyle>
        <se:Rule>
          <se:RasterSymbolizer>
            <se:ColorMap type="intervals">
              <se:ColorMapEntry color="#00FF00" quantity="0" label="Low"/>
              <se:ColorMapEntry color="#FFFF00" quantity="50" label="Mid"/>
              <se:ColorMapEntry color="#FF0000" quantity="100" label="High"/>
            </se:ColorMap>
            <se:ContrastEnhancement>
              <se:Normalize/>
            </se:ContrastEnhancement>
          </se:RasterSymbolizer>
        </se:Rule>
      </se:FeatureTypeStyle>
    </sld:UserStyle>
  </sld:NamedLayer>
</sld:StyledLayerDescriptor>
''';

const _multiLayerSld = '''
<StyledLayerDescriptor version="1.0.0">
  <NamedLayer>
    <Name>Layer1</Name>
    <UserStyle>
      <FeatureTypeStyle>
        <Rule>
          <RasterSymbolizer>
            <Opacity>1.0</Opacity>
            <ColorMap>
              <ColorMapEntry color="#000000" quantity="0"/>
            </ColorMap>
          </RasterSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
  <NamedLayer>
    <Name>Layer2</Name>
    <UserStyle>
      <FeatureTypeStyle>
        <Rule>
          <RasterSymbolizer>
            <Opacity>0.5</Opacity>
            <ColorMap>
              <ColorMapEntry color="#FF0000" quantity="50"/>
            </ColorMap>
          </RasterSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
''';
