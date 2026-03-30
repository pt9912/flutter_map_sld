## 0.1.0

- Initial release: raster-first pure Dart core.
- Parse SLD/SE XML from string or bytes (`SldDocument.parseXmlString`, `SldDocument.parseBytes`).
- Support for SLD 1.0 and SE/SLD 1.1 namespace variants (`sld:`, `se:`, unprefixed).
- Domain model: `SldDocument`, `SldLayer`, `UserStyle`, `FeatureTypeStyle`, `Rule`, `RasterSymbolizer`, `ColorMap`, `ColorMapEntry`, `ContrastEnhancement`.
- Unknown/vendor XML elements preserved as `ExtensionNode`.
- Separate parse and validation results (`SldParseResult`, `SldValidationResult`).
- Validation rules: opacity range, empty ColorMap, quantity ordering, duplicate quantities, entry opacity range, GeoServer `intervals` vendor extension.
- Legend and color scale extraction (`extractLegend`, `extractColorScale`).
