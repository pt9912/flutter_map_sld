# flutter_map_sld_flutter_map

Flutter- und `flutter_map`-Adapter für `flutter_map_sld`.

## Features

- `FlutterMapStyleAdapter` — übersetzt geparste SLD-Symbolizer in `flutter_map`-nahe Style-DTOs (Point, Line, Polygon, Text)
- `SldAsset.parseFromAsset` — lädt SLD/SE aus Flutter-Asset-Bundles
- `SldLegend` Widget — rendert ColorMap-Legenden (vertikal/horizontal, konfigurierbare Swatch-Größe und Label-Stil)

Der Adapter rendert bewusst keine Geometrien und erzeugt keine `Marker`, `Polyline` oder `Polygon` direkt. Er liefert typisierte Style-Daten, damit der Aufrufer Geometrien, Filter-Pipeline und Renderingtiefe kontrollieren kann.

## Usage

```dart
import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:flutter_map_sld_flutter_map/flutter_map_sld_flutter_map.dart';

final document = SldDocument.parseXmlString(xml).document!;
final adapter = const FlutterMapStyleAdapter();

final styles = adapter.adaptDocument(
  document,
  properties: {'type': 'city', 'name': 'Berlin'},
);

final label = styles.first.style.text?.text;
```

## License

MIT — see [LICENSE](LICENSE).
