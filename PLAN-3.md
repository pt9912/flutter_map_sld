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

**Wichtige Design-Entscheidung**: `TextSymbolizer` wird in Phase B statt Phase A implementiert, weil `<Label>` im OGC-Standard eine Expression ist (`<PropertyName>`, `<Literal>`, Verkettungen). Ein `TextSymbolizer` ohne Expression-Modell kann reale SLDs nicht abbilden und würde einen Breaking Change in v0.4.0 erzwingen.

---

## Phase A: Geometrie-Symbolizer (Point, Line, Polygon)

Erweitert den Core um die drei OGC-Geometrie-Symbolizer. TextSymbolizer folgt in Phase B. Der Parser folgt dem etablierten Pattern: Domain-Modell → Parser → Validierung → Tests.

### A1: Domain-Modelle

- [ ] `Stroke` (`color`, `width`, `opacity`, `dashArray`, `lineCap`, `lineJoin`)
- [ ] `Fill` (`color`, `opacity`)
- [ ] `Graphic` (`externalGraphic`, `mark`, `size`, `rotation`, `opacity`)
- [ ] `Mark` (`wellKnownName`, `fill`, `stroke`) — OGC-Standardformen: `square`, `circle`, `triangle`, `star`, `cross`, `x`
- [ ] `ExternalGraphic` (`onlineResource`, `format`)
- [ ] `PointSymbolizer` (`graphic`)
- [ ] `LineSymbolizer` (`stroke`)
- [ ] `PolygonSymbolizer` (`fill`, `stroke`)

### A2: Parser

- [ ] `StrokeParser`, `FillParser`, `GraphicParser`
- [ ] `PointSymbolizerParser`
- [ ] `LineSymbolizerParser`
- [ ] `PolygonSymbolizerParser`
- [ ] `Rule` erweitern: `pointSymbolizer`, `lineSymbolizer`, `polygonSymbolizer` (alle optional, additiv zu `rasterSymbolizer`)
- [ ] `SldDocument` Convenience-Methoden: `selectPointSymbolizers()`, `selectLineSymbolizers()`, `selectPolygonSymbolizers()`

### A3: Validierung

- [ ] Stroke: `width` nicht negativ, `opacity` 0.0–1.0
- [ ] Fill: `opacity` 0.0–1.0
- [ ] Graphic: `size` nicht negativ, `rotation` beliebig
- [ ] Mark: `wellKnownName` gegen bekannte Werte prüfen (info bei unbekanntem)

### A4: Tests und Fixtures

- [ ] Unit-Tests pro Modell (Konstruktion, Equality)
- [ ] Parser-Tests pro Symbolizer (XML-Fragmente)
- [ ] Golden-Tests: SLD-Fixtures mit Point, Line, Polygon aus dem [GeoServer Vector Cookbook](https://docs.geoserver.org/stable/en/user/styling/sld/cookbook/)
- [ ] Gemischte SLD: Rules mit Raster- und Vektor-Symbolizern

---

## Phase B: Filter, Expressions und TextSymbolizer

OGC Filter Encoding erlaubt regelbasierte Stilzuweisung anhand von Feature-Properties. OGC Expressions werden auch für `TextSymbolizer.label` und perspektivisch für parametrische Werte in Symbolizern gebraucht. Deshalb gehören Expressions, Filter und TextSymbolizer in dieselbe Phase.

Erster Scope: Vergleichsoperatoren und logische Verknüpfungen. Keine Spatial-Filter im ersten Schritt.

### B1: Expression-Modell

- [ ] `Expression` als sealed class
- [ ] `PropertyName` (`name`) — Verweis auf ein Feature-Attribut
- [ ] `Literal` (`value`) — konstanter Wert
- [ ] `ExpressionParser` — `<PropertyName>`, `<Literal>`
- [ ] `Expression.evaluate(Map<String, dynamic> properties)` → `dynamic`

### B2: TextSymbolizer

Hängt von B1 ab, weil `<Label>` eine Expression (oder Verkettung) enthält.

- [ ] `TextSymbolizer` (`label: Expression`, `font`, `fill`, `halo`, `placement`)
- [ ] `Font` (`family`, `style`, `weight`, `size`)
- [ ] `Halo` (`radius`, `fill`)
- [ ] `LabelPlacement` (`pointPlacement`, `linePlacement`)
- [ ] `TextSymbolizerParser` (inkl. Font, Halo, LabelPlacement)
- [ ] `Rule` erweitern: `textSymbolizer` (optional, additiv)
- [ ] `SldDocument.selectTextSymbolizers()`
- [ ] Validierung: Font-Size nicht negativ, Halo-Radius nicht negativ
- [ ] Golden-Tests: SLD-Fixtures mit Text-Labels aus dem GeoServer Vector Cookbook

### B3: Filter-Modell

- [ ] `Filter` als sealed class (Basis für alle Filtertypen)
- [ ] Vergleichsoperatoren: `PropertyIsEqualTo`, `PropertyIsNotEqualTo`, `PropertyIsLessThan`, `PropertyIsGreaterThan`, `PropertyIsLessThanOrEqualTo`, `PropertyIsGreaterThanOrEqualTo`
- [ ] `PropertyIsBetween` (`lowerBoundary`, `upperBoundary`)
- [ ] `PropertyIsLike` (`pattern`, `wildCard`, `singleChar`, `escapeChar`)
- [ ] `PropertyIsNull`
- [ ] Logische Operatoren: `And`, `Or`, `Not`
- [ ] `Rule.filter` als optionales Feld (additiv zu Scale-Filtern)

### B4: Filter-Parser

- [ ] `FilterParser` — Einstieg über `<ogc:Filter>` / `<Filter>`
- [ ] Vergleichsoperator-Parser
- [ ] Logische Operator-Parser (rekursiv)
- [ ] Integration in `RuleParser`

### B5: Evaluation und Selektion

- [ ] `Filter.evaluate(Map<String, dynamic> properties)` → `bool`
- [ ] `Rule.appliesTo(Map<String, dynamic> properties, {double? scaleDenominator})` → `bool` — kombiniert Filter und Scale-Check
- [ ] `SldDocument.selectMatchingRules(Map<String, dynamic> properties, {double? scaleDenominator})` → `List<Rule>` — gibt die passenden Rules mit vollem Kontext zurück (Regelreihenfolge bleibt erhalten, Symbolizer-Zugriff über `rule.pointSymbolizer`, `rule.lineSymbolizer`, etc.)

**Design-Entscheidung**: Die Selektions-API gibt `Rule`-Objekte zurück, nicht flache Symbolizer-Listen. Gründe:
- Eine Rule kann mehrere Symbolizer-Typen parallel tragen
- Regelreihenfolge hat Semantik (Zeichenreihenfolge)
- Layer-/Style-Kontext bleibt über den Aufrufer nachvollziehbar
- Adapter-Packages können selbst entscheiden, welche Symbolizer sie auswerten

### B6: Tests

- [ ] Unit-Tests pro Expression- und Filtertyp
- [ ] Evaluation-Tests mit Properties-Maps
- [ ] Parser-Tests mit SLD-Fragmenten
- [ ] Golden-Tests: SLD mit filterbasierter Stilzuweisung

---

## Phase C: `flutter_map_sld_flutter_map` Adapter-Package

Flutter-spezifischer Adapter. Braucht einen konkreten Use-Case als Treiber — die folgenden Punkte sind nach Verbindlichkeit gestaffelt.

### Fester Scope (unabhängig vom Use-Case)

#### C1: Package-Setup

- [ ] `packages/flutter_map_sld_flutter_map/` anlegen
- [ ] `pubspec.yaml` (Dependency auf `flutter_map_sld`, `flutter_map`, Flutter SDK)
- [ ] `analysis_options.yaml`
- [ ] Library-Entrypoint

#### C2: Asset-Helfer

- [ ] `SldAsset.parseFromAsset(String assetPath)` → `Future<SldParseResult>` (via `rootBundle`)
- [ ] Flutter-Asset-Zugriff, getrennt vom IO-Package

#### C3: Legend-Widget

- [ ] `SldLegend` Widget — rendert `extractLegend()`-Ergebnis als vertikale Farbskala/Legende
- [ ] Konfigurierbar: Ausrichtung, Größe, Label-Stil
- [ ] Raster-ColorMap-Unterstützung (Ramp, Intervals, ExactValues)

### Offener Scope (use-case-getrieben, noch nicht spezifizierbar)

#### C4: Style-Adapter (Skizze)

Vor einer Implementierung muss geklärt werden:
- **Was ist der Input?** GeoJSON-Features, `flutter_map`-Polygone, oder rohe Geometrien?
- **Wer evaluiert Filter?** Der Adapter, der Aufrufer, oder eine Pipeline?
- **Wie tief geht die Übersetzung?** Nur Farbe/Stroke-Breite, oder auch Graphic/Mark-Rendering?

Mögliche Richtung, aber **kein fester Planpunkt**:
- `SldStyleAdapter` — übersetzt Vektor-Symbolizer in `flutter_map`-kompatible Darstellung
- Dabei gelten die Architekturgrenze (architecture.md: Adapter konsumiert Core-Modell, kein all-or-nothing Rendering) und das flutter_map-Risiko (concept.md: flutter_map ist keine generische OGC-Rendering-Engine)

#### C5: CI und Publish

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

- **v0.3.0** `flutter_map_sld`: Phase A (Geometrie-Symbolizer: Point, Line, Polygon)
- **v0.4.0** `flutter_map_sld`: Phase B (Filter, Expressions, TextSymbolizer)
- **v0.1.0** `flutter_map_sld_flutter_map`: Phase C (Legend-Widget + Asset-Helfer; Style-Adapter nach Use-Case)
- Phase D: Scope und Package-Zuordnung nach Bedarf entscheiden
