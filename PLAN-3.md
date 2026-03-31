# flutter_map_sld: Plan v0.3.0+

Dieser Plan baut auf v0.2.0 (Core) und v0.1.0 (IO) auf und erweitert die Bibliothek um Vektor-Symbolizer, Filter/Expressions, den Flutter-Adapter und WMS-Interop.

Grundlage: [Concept](docs/concept.md), [Architecture](docs/architecture.md), [PLAN-2.md](PLAN-2.md) (v0.2.0, abgeschlossen).

---

## Abhängigkeiten zwischen Phasen

```
Phase A (Geometrie-Symbolizer) ──► unabhängig, kann sofort starten
Phase B (Filter/Expressions)   ──► unabhängig von A, nützlich für beide
  └─ TextSymbolizer             ──► Teil von B, weil label eine Expression ist
Phase C (Flutter-Adapter)      ──► profitiert von A+B, braucht konkreten Use-Case
Phase D (WMS-Interop)          ──► unabhängig, kann parallel starten
```

Phase A und B erweitern den Core (`flutter_map_sld`), Phase C ist ein neues Package, Phase D kann im IO-Package oder als eigenes Package leben.

**Wichtige Design-Entscheidung**: `TextSymbolizer` wird in Phase B statt Phase A implementiert, weil `<Label>` im OGC-Standard eine Expression ist (`<PropertyName>`, `<Literal>`). Ein `TextSymbolizer` ohne Expression-Modell kann reale SLDs nicht abbilden und würde einen Breaking Change in v0.4.0 erzwingen. Verkettungen und SE-Funktionen (`Concatenate`, `FormatNumber`, etc.) sind in diesem Plan noch nicht enthalten — der erste Scope deckt einfache Labels mit einzelnem `PropertyName` oder `Literal` ab.

---

## Phase A: Geometrie-Symbolizer (Point, Line, Polygon)

Erweitert den Core um die drei OGC-Geometrie-Symbolizer. TextSymbolizer folgt in Phase B. Der Parser folgt dem etablierten Pattern: Domain-Modell → Parser → Validierung → Tests.

### A1: Domain-Modelle

- [x] `Stroke` (`color`, `width`, `opacity`, `dashArray`, `lineCap`, `lineJoin`)
- [x] `Fill` (`color`, `opacity`)
- [x] `Graphic` (`externalGraphic`, `mark`, `size`, `rotation`, `opacity`)
- [x] `Mark` (`wellKnownName`, `fill`, `stroke`) — OGC-Standardformen: `square`, `circle`, `triangle`, `star`, `cross`, `x`
- [x] `ExternalGraphic` (`onlineResource`, `format`)
- [x] `PointSymbolizer` (`graphic`)
- [x] `LineSymbolizer` (`stroke`)
- [x] `PolygonSymbolizer` (`fill`, `stroke`)

### A2: Parser

- [x] `StrokeParser`, `FillParser`, `GraphicParser`
- [x] `PointSymbolizerParser`
- [x] `LineSymbolizerParser`
- [x] `PolygonSymbolizerParser`
- [x] `Rule` erweitern: `pointSymbolizer`, `lineSymbolizer`, `polygonSymbolizer` (alle optional, additiv zu `rasterSymbolizer`)
- [x] `SldDocument` Convenience-Methoden: `selectPointSymbolizers()`, `selectLineSymbolizers()`, `selectPolygonSymbolizers()`

### A3: Validierung

- [x] Stroke: `width` nicht negativ, `opacity` 0.0–1.0
- [x] Fill: `opacity` 0.0–1.0
- [x] Graphic: `size` nicht negativ, `rotation` beliebig
- [x] Mark: `wellKnownName` gegen bekannte Werte prüfen (info bei unbekanntem)

### A4: Tests und Fixtures

- [x] Unit-Tests pro Modell (Konstruktion, Equality)
- [x] Parser-Tests pro Symbolizer (XML-Fragmente)
- [x] Golden-Tests: SLD-Fixtures mit Point, Line, Polygon
- [x] Gemischte SLD: Rules mit Raster- und Vektor-Symbolizern

---

## Phase B: Filter, Expressions und TextSymbolizer

OGC Filter Encoding erlaubt regelbasierte Stilzuweisung anhand von Feature-Properties. OGC Expressions werden auch für `TextSymbolizer.label` und perspektivisch für parametrische Werte in Symbolizern gebraucht. Deshalb gehören Expressions, Filter und TextSymbolizer in dieselbe Phase.

Erster Scope: `PropertyName` und `Literal` als Expressions, Vergleichsoperatoren und logische Verknüpfungen als Filter. Keine Spatial-Filter, keine zusammengesetzten Expressions (`Concatenate`, `FormatNumber`, etc.) im ersten Schritt.

### B1: Expression-Modell

- [x] `Expression` als sealed class
- [x] `PropertyName` (`name`) — Verweis auf ein Feature-Attribut
- [x] `Literal` (`value`) — konstanter Wert
- [x] `ExpressionParser` — `<PropertyName>`, `<Literal>`
- [x] `Expression.evaluate(Map<String, dynamic> properties)` → `dynamic`

**Semantik-Entscheidung für den ersten Scope**:
- `PropertyName.evaluate(...)` liefert den Property-Wert oder `null`, wenn das Attribut fehlt
- `Literal.evaluate(...)` liefert den Literal-Wert unverändert
- keine implizite Typkonvertierung zwischen String und Zahl im ersten Schritt
- Vergleiche arbeiten nur auf kompatiblen Typen; inkompatible Typen ergeben `false`, nicht Exception
- `null` propagiert nicht als Fehler, sondern führt in Vergleichsoperatoren zu `false`, außer bei `PropertyIsNull`

### B2: TextSymbolizer

Hängt von B1 ab, weil `<Label>` eine Expression enthält. Erster Scope: einzelner `PropertyName` oder `Literal` als Label. Zusammengesetzte Labels (Mixed Content, Verkettungen) sind ein späterer Ausbauschritt.

- [x] `TextSymbolizer` (`label: Expression`, `font`, `fill`, `halo`, `placement`)
- [x] `Font` (`family`, `style`, `weight`, `size`)
- [x] `Halo` (`radius`, `fill`)
- [x] `LabelPlacement` (`pointPlacement`, `linePlacement`)
- [x] `TextSymbolizerParser` (inkl. Font, Halo, LabelPlacement)
- [x] `Rule` erweitern: `textSymbolizer` (optional, additiv)
- [x] `SldDocument.selectTextSymbolizers()`
- [x] Validierung: Font-Size nicht negativ, Halo-Radius nicht negativ
- [x] Golden-Tests: SLD-Fixture mit Text-Labels und Filter

### B3: Filter-Modell

- [x] `Filter` als sealed class (Basis für alle Filtertypen)
- [x] Vergleichsoperatoren: `PropertyIsEqualTo`, `PropertyIsNotEqualTo`, `PropertyIsLessThan`, `PropertyIsGreaterThan`, `PropertyIsLessThanOrEqualTo`, `PropertyIsGreaterThanOrEqualTo`
- [x] `PropertyIsBetween` (`lowerBoundary`, `upperBoundary`)
- [x] `PropertyIsLike` (`pattern`, `wildCard`, `singleChar`, `escapeChar`)
- [x] `PropertyIsNull`
- [x] Logische Operatoren: `And`, `Or`, `Not`
- [x] `Rule.filter` als optionales Feld (additiv zu Scale-Filtern)

**Semantik-Entscheidung für den ersten Scope**:
- Vergleichsoperatoren evaluieren ihre Operanden über `Expression.evaluate(...)`
- bei inkompatiblen Typen oder `null` ergibt der Vergleich `false`
- `PropertyIsNull` ist `true`, wenn die ausgewertete Expression `null` liefert
- `PropertyIsLike` wird im ersten Schritt als String-Match auf Basis der OGC-Parameter `wildCard`, `singleChar`, `escapeChar` implementiert
- logische Operatoren arbeiten strikt boolesch; nicht-boolesche Zwischenergebnisse werden nicht automatisch truthy/falsy interpretiert

### B4: Filter-Parser

- [x] `FilterParser` — Einstieg über `<ogc:Filter>` / `<Filter>`
- [x] Vergleichsoperator-Parser
- [x] Logische Operator-Parser (rekursiv)
- [x] Integration in `RuleParser`

### B5: Evaluation und Selektion

- [x] `Filter.evaluate(Map<String, dynamic> properties)` → `bool`
- [x] `Rule.appliesTo(Map<String, dynamic> properties, {double? scaleDenominator})` → `bool` — kombiniert Filter und Scale-Check
- [x] `MatchedRule` Wrapper-Klasse mit Herkunftskontext:
  ```dart
  class MatchedRule {
    final SldLayer layer;
    final UserStyle style;
    final FeatureTypeStyle featureTypeStyle;
    final Rule rule;
  }
  ```
- [x] `SldDocument.selectMatchingRules(Map<String, dynamic> properties, {double? scaleDenominator})` → `List<MatchedRule>`

**Design-Entscheidung**: Die Selektions-API gibt `MatchedRule`-Objekte zurück, nicht flache `Rule`- oder Symbolizer-Listen. Gründe:
- `Rule` allein trägt keine Parent-Referenzen — bei Selektion über mehrere Layer/Styles geht die Herkunft sonst verloren
- Eine Rule kann mehrere Symbolizer-Typen parallel tragen
- Regelreihenfolge hat Semantik (Zeichenreihenfolge)
- Adapter-Packages können über `matchedRule.layer` / `.style` den Kontext nachvollziehen

### B6: Tests

- [x] Unit-Tests pro Expression- und Filtertyp
- [x] Evaluation-Tests mit Properties-Maps
- [x] Parser-Tests mit SLD-Fragmenten
- [x] Golden-Tests: SLD mit filterbasierter Stilzuweisung

---

## Phase C: `flutter_map_sld_flutter_map` Adapter-Package

Flutter-spezifischer Adapter. Der erste nutzbare Scope ist jetzt als
Style-Adapter umgesetzt; Asset-Helfer, Legend-Widget und tiefere
`flutter_map`-Integration bleiben separat ausbaubar.

### Fester Scope (unabhängig vom Use-Case)

#### C1: Package-Setup

- [x] `packages/flutter_map_sld_flutter_map/` anlegen
- [x] `pubspec.yaml` (Dependency auf `flutter_map_sld`, `flutter_map`, Flutter SDK)
- [x] `analysis_options.yaml`
- [x] Library-Entrypoint

#### C2: Asset-Helfer

- [x] `SldAsset.parseFromAsset(String assetPath)` → `Future<SldParseResult>` (via `rootBundle`)
- [x] Flutter-Asset-Zugriff, getrennt vom IO-Package

#### C3: Legend-Widget

- [x] `SldLegend` Widget — rendert `extractLegend()`-Ergebnis als vertikale Farbskala/Legende
- [x] Konfigurierbar: Ausrichtung, Größe, Label-Stil
- [x] Raster-ColorMap-Unterstützung (Ramp, Intervals, ExactValues)

### Teilweise spezifizierter Scope

#### C4: Style-Adapter (erster Scope umgesetzt)

Der erste Adapter-Scope vermeidet bewusst vollständiges Client-Rendering und
übersetzt stattdessen das Core-Modell in stabile, `flutter_map`-nahe Style-DTOs.
Damit bleibt die Geometrie- und Layer-Erzeugung beim Aufrufer, während Filter-
und Scale-Selektion weiter im Core stattfindet.

- [x] `FlutterMapStyleAdapter`
- [x] `adaptRule(Rule, {properties})` → `FlutterMapRuleStyle`
- [x] `adaptMatchedRule(...)` / `adaptMatchedRules(...)`
- [x] `adaptDocument(SldDocument, {properties, scaleDenominator})`
- [x] `FlutterMapMatchedStyle` als Wrapper um `MatchedRule` + adaptierte Style-Daten
- [x] DTOs für Point, Line, Polygon und Text (`FlutterMapPointStyle`, `FlutterMapLineStyle`, `FlutterMapPolygonStyle`, `FlutterMapTextStyle`)
- [x] Mapping von Stroke/Fill in Flutter-Typen (`Color`, `StrokeCap`, `StrokeJoin`, `TextStyle`)
- [x] Point-Mapping inkl. Mark-Shape, ExternalGraphic-Metadaten, Größe, Rotation, Opacity
- [x] Text-Mapping inkl. Label-Evaluation, Font, Halo und Placement-Hints
- [x] Tests für Rule-Adaptierung sowie Dokument-Selektion via Filter und Scale

**Bewusste Scope-Grenze des ersten C4-Schritts**:
- keine direkte Erzeugung von `Marker`, `Polygon`, `Polyline` oder `TileLayer`
- keine Geometrie-/Feature-Pipeline im Adapter
- keine WMS-Integration in Phase C4; dafür bleibt Phase D zuständig

**Offene Ausbaurichtungen**:
- direkte `flutter_map`-Layer-Helfer, sobald ein stabiler Geometrieinput feststeht
- WMS-`TileLayer`-Hilfen auf Basis von Phase D
- tiefere Übersetzung von Mark-/Graphic-Rendering, falls ein konkreter Use-Case das braucht

#### C5: CI und Publish

- [x] Dockerfile (separates Flutter-basiertes Dockerfile im Package)
- [x] CI-Workflow-Jobs
- [x] Publish-Workflow mit Tag-Pattern `flutter_map_sld_flutter_map-v*`

---

## Phase D: WMS-Interop

Helfer für WMS-nahe Workflows. Lebt im IO-Package (`flutter_map_sld_io`) — **ohne** `flutter_map`-Dependency. Das IO-Package hat bereits `http` als Dependency und passt thematisch (Netzwerk-/Server-Interaktion).

### D1: WMS-Request-Helfer

- [ ] `WmsRequestBuilder` — baut GetMap-URLs aus Layer-Name, Bounding-Box, Größe, CRS/SRS
- [ ] GetMap-URL mit eingebettetem SLD_BODY-Parameter
- [ ] `WmsCapabilitiesParser` — liest GetCapabilities-Response und extrahiert verfügbare Layer und zugehörige Style-Namen
- [ ] `WmsStyleResolver` — verknüpft SLD-Styles mit WMS-Layern

**Wichtige API-Entscheidung**:
- `WmsRequestBuilder` braucht eine explizite WMS-Version (`1.1.1` oder `1.3.0`) im API-Vertrag
- je nach Version wird `SRS` oder `CRS` verwendet
- die Behandlung der Axis-Order muss versions- und CRS-abhängig explizit definiert werden; insbesondere bei WMS 1.3.0 darf das nicht dem Aufrufer implizit überlassen bleiben
- die erste Implementierung sollte deshalb einen kleinen, klaren Vertrag haben, z.B. `version`, `crs`, `bbox`, `width`, `height`, `layers`, `styles`, und die Axis-Order intern konsistent anwenden

**Hinweis**: Die Übersetzung von WMS-URLs in `flutter_map`-`TileLayer`-Konfiguration gehört in Phase C (Flutter-Adapter), nicht hierher. Phase D liefert nur die plattformneutralen URL-/Request-Bausteine.

---

## Explizit nicht in diesem Plan

- Client-seitiges Raster-Rendering — erfordert Rohdaten (Pixelwerte), nicht mit vorgerenderten WMS-Kacheln möglich (siehe concept.md Risiken)
- Spatial-Filter (`Intersects`, `Within`, `DWithin`, etc.)
- Zusammengesetzte Expressions (`Concatenate`, `FormatNumber`, `Categorize`, `Interpolate`, `Recode`)
- CSS-basierte Styles (GeoServer-eigene Alternative zu SLD)

## Release-Strategie

- **v0.3.0** `flutter_map_sld`: Phase A (Geometrie-Symbolizer: Point, Line, Polygon)
- **v0.4.0** `flutter_map_sld`: Phase B (Filter, Expressions, TextSymbolizer)
- **v0.1.0** `flutter_map_sld_flutter_map`: Package-Setup + erster C4-Style-Adapter-Scope; Asset-Helfer und Legend-Widget folgen
- **v0.2.0** `flutter_map_sld_io`: Phase D (WMS-Interop im IO-Package)
