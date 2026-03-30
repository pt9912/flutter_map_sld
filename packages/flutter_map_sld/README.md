# flutter_map_sld

Parse, validate, and use OGC **Styled Layer Descriptor (SLD)** and **Symbology Encoding (SE)** styles in Dart.

Raster-first, pure Dart, no Flutter dependency.

## Features

- Parse SLD/SE XML from string or bytes
- SLD 1.0 and SE/SLD 1.1 namespace variants (`sld:`, `se:`, unprefixed)
- Immutable domain model with deep equality
- Separate parse and validation results
- 7 validation rules (opacity, ColorMap, quantity ordering, vendor extensions)
- Legend and color scale extraction
- Unknown/vendor XML elements preserved as `ExtensionNode`

## Usage

```dart
import 'package:flutter_map_sld/flutter_map_sld.dart';

// Parse
final result = SldDocument.parseXmlString(sldXml);
if (result.hasErrors) {
  for (final issue in result.issues) {
    print('${issue.severity.name}: ${issue.message}');
  }
  return;
}
final sld = result.document!;

// Validate
final validation = const SldValidator().validate(sld);

// Extract raster styles
final rasterSymbolizers = sld.selectRasterSymbolizers();
final colorMap = rasterSymbolizers.first.colorMap!;

// Legend and color scale
final legend = extractLegend(colorMap);
final scale = extractColorScale(colorMap);
```

See [example/parse_and_validate.dart](example/parse_and_validate.dart) for a complete example.

## Part of a package family

| Package | Description |
|---------|------------|
| **flutter_map_sld** (this) | Pure Dart core |
| `flutter_map_sld_io` (planned) | File and HTTP helpers |
| `flutter_map_sld_flutter_map` (planned) | Flutter and flutter_map adapters |

## Documentation

- [Concept](../../docs/concept.md) — Product vision, scope, and target audience
- [Architecture](../../docs/architecture.md) — Layer model, domain model, and test strategy

## License

MIT — see [LICENSE](LICENSE).
