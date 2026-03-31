# flutter_map_sld: Plan v0.3.0+

Dieser Plan baut auf v0.2.0 (Core) und v0.1.0 (IO) auf und erweitert die Bibliothek um Vektor-Symbolizer, Filter/Expressions, den Flutter-Adapter und WMS-Interop.

Grundlage: [Concept](docs/concept.md), [Architecture](docs/architecture.md), [PLAN-2.md](PLAN-2.md) (v0.2.0, abgeschlossen).

---

## Abhängigkeiten zwischen Phasen

```
Phase A (Vektor-Symbolizer)  ──► unabhängig, kann sofort starten
Phase B (Filter/Expressions) ──► unabhängig vom Vektor-Ausbau, nützlich für beide
Phase C (Flutter-Adapter)    ──► profitiert von A+B, braucht konkreten Use-Case
Phase D (WMS-Interop)        ──► unabhängig, kann parallel starten
```

Phase A und B erweitern den Core (`flutter_map_sld`), Phase C ist ein neues Package, Phase D kann im IO-Package oder als eigenes Package leben.

---

## Phase A: Vektor-Symbolizer

Erweitert den Core um die vier OGC-Vektor-Symbolizer. Der Parser folgt dem etablierten Pattern: Domain-Modell → Parser → Validierung → Tests.

### A1: Domain-Modelle

- [ ] `Stroke` (`color`, `width`, `opacity`, `dashArray`, `lineCap`, `lineJoin`)
- [ ] `Fill` (`color`, `opacity`)
- [ ] `Graphic` (`externalGraphic`, `mark`, `size`, `rotation`, `opacity`)
- [ ] `Mark` (`wellKnownName`, `fill`, `stroke`) — OGC-Standardformen: `square`, `circle`, `triangle`, `star`, `cross`, `x`
- [ ] `ExternalGraphic` (`onlineResource`, `format`)
- [ ] `PointSymbolizer` (`graphic`)
- [ ] `LineSymbolizer` (`stroke`)
- [ ] `PolygonSymbolizer` (`fill`, `stroke`)
- [ ] `TextSymbolizer` (`label`, `font`, `fill`, `halo`, `placement`)
- [ ] `Font` (`family`, `style`, `weight`, `size`)
- [ ] `Halo` (`radius`, `fill`)
- [ ] `LabelPlacement` (`pointPlacement`, `linePlacement`)

### A2: Parser

- [ ] `StrokeParser`, `FillParser`, `GraphicParser`
- [ ] `PointSymbolizerParser`
- [ ] `LineSymbolizerParser`
- [ ] `PolygonSymbolizerParser`
- [ ] `TextSymbolizerParser` (inkl. Font, Halo, LabelPlacement)
- [ ] `Rule` erweitern: `pointSymbolizer`, `lineSymbolizer`, `polygonSymbolizer`, `textSymbolizer` (alle optional, additiv zu `rasterSymbolizer`)
- [ ] `SldDocument` Convenience-Methoden: `selectPointSymbolizers()`, `selectLineSymbolizers()`, etc.

### A3: Validierung

- [ ] Stroke: `width` nicht negativ, `opacity` 0.0–1.0
- [ ] Fill: `opacity` 0.0–1.0
- [ ] Graphic: `size` nicht negativ, `rotation` beliebig
- [ ] Mark: `wellKnownName` gegen bekannte Werte prüfen (info bei unbekanntem)
- [ ] TextSymbolizer: Font-Size nicht negativ, Halo-Radius nicht negativ

### A4: Tests und Fixtures

- [ ] Unit-Tests pro Modell (Konstruktion, Equality)
- [ ] Parser-Tests pro Symbolizer (XML-Fragmente)
- [ ] Golden-Tests: SLD-Fixtures mit Point, Line, Polygon, Text aus dem [GeoServer Vector Cookbook](https://docs.geoserver.org/stable/en/user/styling/sld/cookbook/)
- [ ] Gemischte SLD: Rules mit Raster- und Vektor-Symbolizern

---

## Phase B: Filter und Expressions

OGC Filter Encoding erlaubt regelbasierte Stilzuweisung anhand von Feature-Properties. Erster Scope: Vergleichsoperatoren und logische Verknüpfungen. Keine Spatial-Filter im ersten Schritt.

### B1: Domain-Modelle

- [ ] `Filter` als sealed class (Basis für alle Filtertypen)
- [ ] Vergleichsoperatoren: `PropertyIsEqualTo`, `PropertyIsNotEqualTo`, `PropertyIsLessThan`, `PropertyIsGreaterThan`, `PropertyIsLessThanOrEqualTo`, `PropertyIsGreaterThanOrEqualTo`
- [ ] `PropertyIsBetween` (`lowerBoundary`, `upperBoundary`)
- [ ] `PropertyIsLike` (`pattern`, `wildCard`, `singleChar`, `escapeChar`)
- [ ] `PropertyIsNull`
- [ ] Logische Operatoren: `And`, `Or`, `Not`
- [ ] Expressions: `PropertyName`, `Literal`
- [ ] `Rule.filter` als optionales Feld (additiv zu Scale-Filtern)

### B2: Parser

- [ ] `FilterParser` — Einstieg über `<ogc:Filter>` / `<Filter>`
- [ ] `ExpressionParser` — `<PropertyName>`, `<Literal>`
- [ ] Vergleichsoperator-Parser
- [ ] Logische Operator-Parser (rekursiv)
- [ ] Integration in `RuleParser`

### B3: Evaluation

- [ ] `Filter.evaluate(Map<String, dynamic> properties)` → `bool`
- [ ] `Rule.appliesTo(Map<String, dynamic> properties, {double? scaleDenominator})` → `bool` — kombiniert Filter und Scale-Check
- [ ] `SldDocument.selectSymbolizersFor(Map<String, dynamic> properties, {double? scaleDenominator})` — gibt passende Symbolizer für ein Feature zurück

### B4: Tests

- [ ] Unit-Tests pro Filtertyp
- [ ] Evaluation-Tests mit Properties
- [ ] Parser-Tests mit SLD-Fragmenten
- [ ] Golden-Tests: SLD mit filterbasierter Stilzuweisung

---

## Phase C: `flutter_map_sld_flutter_map` Adapter-Package

Flutter-spezifischer Adapter für `flutter_map`. Braucht einen konkreten Use-Case als Treiber — die folgenden Punkte sind eine Planungsgrundlage, kein fester Scope.

### C1: Package-Setup

- [ ] `packages/flutter_map_sld_flutter_map/` anlegen
- [ ] `pubspec.yaml` (Dependency auf `flutter_map_sld`, `flutter_map`, Flutter SDK)
- [ ] `analysis_options.yaml`
- [ ] Library-Entrypoint

### C2: Legend-Widget

- [ ] `SldLegend` Widget — rendert `extractLegend()`-Ergebnis als vertikale Farbskala/Legende
- [ ] Konfigurierbar: Ausrichtung, Größe, Label-Stil
- [ ] Raster-ColorMap-Unterstützung (Ramp, Intervals, ExactValues)

### C3: Style-Adapter

- [ ] `SldStyleAdapter` — übersetzt Vektor-Symbolizer in `flutter_map`-kompatible Darstellung
- [ ] `PolygonSymbolizer` → `PolygonLayer`-Optionen (Fill, Stroke)
- [ ] `LineSymbolizer` → `PolylineLayer`-Optionen (Stroke)
- [ ] `PointSymbolizer` → `MarkerLayer`-Optionen (Graphic → Icon)

### C4: Asset-Helfer

- [ ] `SldAsset.parseFromAsset(String assetPath)` → `Future<SldParseResult>` (via `rootBundle`)
- [ ] Flutter-Asset-Zugriff, getrennt vom IO-Package

### C5: CI und Publish

- [ ] Dockerfile-Targets im Root-Dockerfile
- [ ] CI-Workflow-Jobs
- [ ] Publish-Workflow mit Tag-Pattern `flutter_map_sld_flutter_map-v*`

---

## Phase D: WMS-Interop

Helfer für WMS-nahe Workflows. Kann im IO-Package oder als eigenes Modul leben.

### D1: WMS-Request-Helfer

- [ ] `WmsRequestBuilder` — baut GetMap-URLs aus Layer-Name, Bounding-Box, Größe, SRS
- [ ] `WmsCapabilitiesParser` — liest GetCapabilities-Response und extrahiert verfügbare Layer und zugehörige Style-Namen
- [ ] `WmsStyleResolver` — verknüpft SLD-Styles mit WMS-Layern

### D2: SLD-basierte Layer-Konfiguration

- [ ] SLD-Dokument → `TileLayer`-Konfiguration für `flutter_map` (Style-Parameter im WMS-Request)
- [ ] GetMap-URL mit eingebettetem SLD_BODY-Parameter

---

## Explizit nicht in diesem Plan

- Client-seitiges Raster-Rendering — erfordert Rohdaten (Pixelwerte), nicht mit vorgerenderten WMS-Kacheln möglich (siehe concept.md Risiken)
- Spatial-Filter (`Intersects`, `Within`, `DWithin`, etc.)
- Vollständige SE-Funktionen (`Categorize`, `Interpolate`, `Recode`)
- CSS-basierte Styles (GeoServer-eigene Alternative zu SLD)

## Release-Strategie

- **v0.3.0** `flutter_map_sld`: Phase A (Vektor-Symbolizer)
- **v0.4.0** `flutter_map_sld`: Phase B (Filter/Expressions)
- **v0.1.0** `flutter_map_sld_flutter_map`: Phase C (erster Use-Case-getriebener Release)
- Phase D: Scope und Package-Zuordnung nach Bedarf entscheiden
