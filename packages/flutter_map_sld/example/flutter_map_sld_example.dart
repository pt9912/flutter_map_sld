// ignore_for_file: avoid_print
import 'package:flutter_map_sld/flutter_map_sld.dart';

const exampleSld = '''
<StyledLayerDescriptor version="1.0.0"
    xmlns="http://www.opengis.net/sld">
  <NamedLayer>
    <Name>DEM</Name>
    <UserStyle>
      <Name>Elevation</Name>
      <FeatureTypeStyle>
        <Rule>
          <RasterSymbolizer>
            <Opacity>0.8</Opacity>
            <ColorMap>
              <ColorMapEntry color="#0000FF" quantity="0" label="Low"/>
              <ColorMapEntry color="#00FF00" quantity="500" label="Mid"/>
              <ColorMapEntry color="#FF0000" quantity="1000" label="High"/>
            </ColorMap>
          </RasterSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
''';

void main() {
  // 1. Parse
  final parseResult = SldDocument.parseXmlString(exampleSld);

  if (parseResult.hasErrors) {
    for (final issue in parseResult.issues) {
      print('PARSE ${issue.severity.name}: ${issue.message}');
    }
    return;
  }

  final sld = parseResult.document!;
  print('SLD version: ${sld.version}');
  print('Layers: ${sld.layers.map((l) => l.name).join(', ')}');

  // 2. Validate
  final validation = const SldValidator().validate(sld);

  if (validation.hasWarnings) {
    for (final issue in validation.issues) {
      print('VALIDATION ${issue.severity.name}: ${issue.message}');
    }
  } else {
    print('Validation passed.');
  }

  // 3. Extract raster symbolizers
  final rasterSymbolizers = sld.selectRasterSymbolizers();
  print('Raster symbolizers: ${rasterSymbolizers.length}');

  for (final rs in rasterSymbolizers) {
    print('  Opacity: ${rs.opacity}');

    if (rs.colorMap != null) {
      // 4. Extract legend
      final legend = extractLegend(rs.colorMap!);
      print('  Legend:');
      for (final entry in legend) {
        print('    ${entry.label ?? "—"}: '
            'quantity=${entry.quantity}, '
            'color=0x${entry.colorArgb.toRadixString(16).toUpperCase()}');
      }

      // 5. Extract color scale
      final scale = extractColorScale(rs.colorMap!);
      print('  Color scale (${scale.length} stops):');
      for (final stop in scale) {
        print('    ${stop.quantity} → '
            '0x${stop.colorArgb.toRadixString(16).toUpperCase()}');
      }
    }
  }
}
