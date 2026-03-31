## 0.2.0

- **Scale-dependent rule selection**: `Rule.appliesAtScale()` with OGC-convention bounds (inclusive lower, exclusive upper) and `SldDocument.selectRasterSymbolizersAtScale()`.
- **ChannelSelection**: domain model and parser for RGB and gray band selection with per-channel `ContrastEnhancement`.
- **ShadedRelief**: domain model and parser (`brightnessOnly`, `reliefFactor`).
- **VendorOption**: typed parsing of `<VendorOption name="...">value</VendorOption>` into `RasterSymbolizer.vendorOptions`, separate from `ExtensionNode`.
- **Async stream parsing**: `SldDocument.parseAsyncStream(Stream<List<int>>)` convenience wrapper.
- **Parser fix**: known-but-unimplemented OGC elements (`ImageOutline`, `Geometry`, `OverlapBehavior`) are now preserved as `ExtensionNode` with issue code `unsupported-element` instead of being silently dropped.
- New validation rules: `empty-scale-range` (error), `relief-factor-negative` (error), `incomplete-rgb-channels` (error), `vendor-option-missing-name` (warning).

## 0.1.0

- Initial release: raster-first pure Dart core.
- Parse SLD/SE XML from string or bytes (`SldDocument.parseXmlString`, `SldDocument.parseBytes`).
- Support for SLD 1.0 and SE/SLD 1.1 namespace variants (`sld:`, `se:`, unprefixed).
- Domain model: `SldDocument`, `SldLayer`, `UserStyle`, `FeatureTypeStyle`, `Rule`, `RasterSymbolizer`, `ColorMap`, `ColorMapEntry`, `ContrastEnhancement`.
- Unknown/vendor XML elements preserved as `ExtensionNode`.
- Separate parse and validation results (`SldParseResult`, `SldValidationResult`).
- Validation rules: opacity range, empty ColorMap, quantity ordering, duplicate quantities, entry opacity range, GeoServer `intervals` vendor extension.
- Legend and color scale extraction (`extractLegend`, `extractColorScale`).
