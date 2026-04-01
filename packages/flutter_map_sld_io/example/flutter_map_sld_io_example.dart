// ignore_for_file: avoid_print
import 'package:flutter_map_sld_io/flutter_map_sld_io.dart';

void main() async {
  // 1. Load SLD from a local file
  final result = await SldIo.parseFile('path/to/style.sld');

  switch (result) {
    case SldLoadSuccess(:final parseResult):
      if (parseResult.hasErrors) {
        for (final issue in parseResult.issues) {
          print('Parse issue: ${issue.message}');
        }
        return;
      }

      final sld = parseResult.document!;
      print('Loaded SLD version: ${sld.version}');
      print('Layers: ${sld.layers.map((l) => l.name).join(', ')}');

    case SldLoadFailure(:final error):
      print('Load failed: ${error.kind} — ${error.message}');
      return;
  }

  // 2. Load SLD from a URL
  final urlResult = await SldIo.parseUrl(
    Uri.parse('https://example.com/geoserver/wms?service=WMS&request=GetStyles&layers=my_layer'),
  );

  switch (urlResult) {
    case SldLoadSuccess(:final parseResult):
      print('Remote SLD layers: ${parseResult.document?.layers.length}');
    case SldLoadFailure(:final error):
      print('URL load failed: ${error.message}');
  }

  // 3. Build a WMS GetMap request URL
  final getMapUrl = WmsRequestBuilder(
    baseUrl: Uri.parse('https://example.com/geoserver/wms'),
    layers: ['topp:states'],
    styles: ['population'],
    bbox: (minX: 0, minY: 0, maxX: 180, maxY: 90),
    width: 800,
    height: 600,
    srs: 'EPSG:4326',
  ).build();

  print('GetMap URL: $getMapUrl');
}
