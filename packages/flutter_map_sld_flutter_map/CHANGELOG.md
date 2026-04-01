## 0.1.2

- Bump flutter_map_sld dependency to `^0.5.0`.

## 0.1.1

- Added dartdoc comments to all public classes, constructors, fields, and enum values.
- Added library-level documentation.
- Added example file for pub.dev scoring.

## 0.1.0

- Initial release: Flutter and flutter_map adapters for SLD/SE styles.
- `FlutterMapStyleAdapter` — translates parsed SLD vector/text symbolizers into flutter_map-friendly style DTOs.
- `SldAsset.parseFromAsset` — load SLD from Flutter asset bundles.
- `SldLegend` widget — render ColorMap legends with configurable layout, swatch size, and label style.
- Style DTOs: `FlutterMapPointStyle`, `FlutterMapLineStyle`, `FlutterMapPolygonStyle`, `FlutterMapTextStyle`.
- `FlutterMapMatchedStyle` — matched rule wrapper with adapted style data.
- `adaptDocument` — select and adapt matching rules by properties and scale.
