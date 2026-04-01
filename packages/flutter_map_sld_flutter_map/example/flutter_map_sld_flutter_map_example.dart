// ignore_for_file: avoid_print
import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:flutter_map_sld_flutter_map/flutter_map_sld_flutter_map.dart';

const exampleSld = '''
<StyledLayerDescriptor version="1.0.0"
    xmlns="http://www.opengis.net/sld">
  <NamedLayer>
    <Name>cities</Name>
    <UserStyle>
      <FeatureTypeStyle>
        <Rule>
          <ogc:Filter xmlns:ogc="http://www.opengis.net/ogc">
            <ogc:PropertyIsEqualTo>
              <ogc:PropertyName>type</ogc:PropertyName>
              <ogc:Literal>city</ogc:Literal>
            </ogc:PropertyIsEqualTo>
          </ogc:Filter>
          <PointSymbolizer>
            <Graphic>
              <Mark>
                <WellKnownName>circle</WellKnownName>
                <Fill><CssParameter name="fill">#FF0000</CssParameter></Fill>
              </Mark>
              <Size>8</Size>
            </Graphic>
          </PointSymbolizer>
          <TextSymbolizer>
            <Label><PropertyName>name</PropertyName></Label>
            <Font>
              <CssParameter name="font-family">Arial</CssParameter>
              <CssParameter name="font-size">12</CssParameter>
            </Font>
          </TextSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
''';

void main() {
  // 1. Parse
  final parseResult = SldDocument.parseXmlString(exampleSld);
  final sld = parseResult.document!;

  // 2. Adapt to flutter_map style DTOs
  const adapter = FlutterMapStyleAdapter();
  final matched = adapter.adaptDocument(
    sld,
    properties: {'type': 'city', 'name': 'Berlin'},
    scaleDenominator: 50000,
  );

  for (final m in matched) {
    final style = m.style;

    if (style.point != null) {
      print('Point: shape=${style.point!.markShape}, size=${style.point!.size}');
    }

    if (style.text != null) {
      print('Text: "${style.text!.text}", font=${style.text!.textStyle?.fontFamily}');
    }
  }
}
