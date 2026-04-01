## 0.5.1

- Added dartdoc comments to all filter classes (comparison, logical, spatial, distance).
- Added conventionally named example file for pub.dev scoring.

## 0.5.0

- **Composite expressions**: `Concatenate`, `FormatNumber`, `Categorize`, `Interpolate`, `Recode` with full evaluate/equality support, plus helper types `InterpolationPoint`, `InterpolateMode`, `RecodeMapping`.
- **Spatial filters**: `BBox`, `Intersects`, `Within`, `Contains`, `Touches`, `Crosses`, `SpatialOverlaps`, `Disjoint`, `DWithin`, `Beyond` — OGC spatial filter operators with GML geometry parsing via `gml4dart`.
- **Spatial operations**: `geometryEnvelope`, `envelopeIntersects`, `pointInPolygon`, `pointInEnvelope`, `distancePointToPoint`, `lineIntersectsEnvelope`, `geometryIntersects`, `geometryWithin`, `geometryDistance`.
- **Expression parser refactored**: `parseFirstExpression`/`parseTwoExpressions` now use a whitelist of known expression element names, enabling nested composite expressions.
- **Expression validation rules**: `Categorize` values/thresholds count, `Interpolate` sort order and minimum points, `Recode` duplicate input detection.
- **New dependency**: `gml4dart: ^0.1.0` for typed geometry model and GML 2.x/3.x parsing.
- **BREAKING**: `Filter.evaluate()` signature changed to `bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry})`. The parameter is optional, so existing call sites without geometry continue to work. `Rule.appliesTo()` and `SldDocument.selectMatchingRules()` extended with the same optional `{GmlGeometry? geometry}` parameter.

## 0.4.0

- **Vector symbolizers**: `PointSymbolizer`, `LineSymbolizer`, `PolygonSymbolizer` with `Stroke`, `Fill`, `Graphic`, `Mark`, `ExternalGraphic`.
- **TextSymbolizer**: label via `Expression` (`PropertyName`, `Literal`), `Font`, `Halo`, `LabelPlacement` (point and line placement).
- **OGC Filter Encoding**: sealed `Filter` model with 6 comparison operators, `PropertyIsBetween`, `PropertyIsLike`, `PropertyIsNull`, and logical operators (`And`, `Or`, `Not`).
- **Expression evaluation**: `Expression.evaluate()` and `Filter.evaluate()` against feature property maps.
- **Rule selection**: `Rule.appliesTo()` combining filter and scale, `SldDocument.selectMatchingRules()` returning `MatchedRule` with full layer/style/FTS context.
- **Convenience methods**: `selectPointSymbolizers()`, `selectLineSymbolizers()`, `selectPolygonSymbolizers()`, `selectTextSymbolizers()`.
- New validation rules: `stroke-width-negative`, `stroke-opacity-out-of-range`, `fill-opacity-out-of-range`, `graphic-size-negative`, `unknown-mark-name`, `font-size-negative`, `halo-radius-negative`.

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
