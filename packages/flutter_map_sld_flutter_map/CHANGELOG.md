## 0.1.0

- Initial release: Flutter and flutter_map adapters for SLD/SE styles.
- `FlutterMapStyleAdapter` — translates parsed SLD vector/text symbolizers into flutter_map-friendly style DTOs.
- `SldAsset.parseFromAsset` — load SLD from Flutter asset bundles.
- `SldLegend` widget — render ColorMap legends with configurable layout, swatch size, and label style.
- Style DTOs: `FlutterMapPointStyle`, `FlutterMapLineStyle`, `FlutterMapPolygonStyle`, `FlutterMapTextStyle`.
- `FlutterMapMatchedStyle` — matched rule wrapper with adapted style data.
- `adaptDocument` — select and adapt matching rules by properties and scale.
