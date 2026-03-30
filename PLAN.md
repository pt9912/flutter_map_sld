# flutter_map_sld: Implementierungsplan MVP

Dieser Plan beschreibt die Schritte vom aktuellen Stand (nur Dokumentation) bis zum ersten veröffentlichbaren Release des Pure-Dart-Core-Packages `flutter_map_sld`.

Grundlage: [Concept](docs/concept.md) und [Architecture](docs/architecture.md).

---

## Phase 1: Projekt-Setup

- [x] Monorepo-Verzeichnisstruktur anlegen (`packages/flutter_map_sld/`)
- [x] Root-Dokumentation im Repo-Root belassen; alle Build-/Analyse-/Test-Befehle für den MVP laufen im Package-Verzeichnis `packages/flutter_map_sld/`
- [x] `pubspec.yaml` für Core-Package erstellen (Dart >=3.0.0, Dependency `xml`)
- [x] `analysis_options.yaml` mit strikten Lint-Regeln (`lints` oder `very_good_analysis`)
- [x] Library-Entrypoint `lib/flutter_map_sld.dart` anlegen
- [x] Leere Verzeichnisstruktur unter `lib/src/` gemäß Architektur erstellen
- [x] `dart analyze` und `dart test` laufen ohne Fehler (verifiziert via `docker build --target analyze` / `--target test` mit `dart:stable`; kein lokales Dart SDK vorhanden)

## Phase 2: Domain Model

Immutable Datenklassen — Kern der Bibliothek, keine Abhängigkeit auf XML-Package.

- [x] `SldIssueSeverity` Enum (`error`, `warning`, `info`)
- [x] `sealed class SldIssue` mit Subklassen `SldParseIssue`, `SldValidationIssue`
- [x] `SldParseResult` (`document`, `issues`, `hasErrors`)
- [x] `SldDocument` (`version`, `layers`, `selectRasterSymbolizers()`)
- [x] `SldLayer` (`name`, `styles`)
- [x] `UserStyle` (`name`, `featureTypeStyles`)
- [x] `FeatureTypeStyle` (`rules`)
- [x] `Rule` (`name`, `minScaleDenominator`, `maxScaleDenominator`, `rasterSymbolizer`)
- [x] `RasterSymbolizer` (`opacity`, `colorMap`, `contrastEnhancement`, `extensions`)
- [x] `ColorMapType` Enum (`ramp`, `intervals`, `exactValues`)
- [x] `ColorMap` (`type`, `entries`)
- [x] `ColorMapEntry` (`colorArgb`, `quantity`, `opacity`, `label`)
- [x] `ContrastEnhancement` (`method`, `gammaValue`)
- [x] `ContrastMethod` Enum (`normalize`, `histogram`, `none`)
- [x] `ExtensionNode` (`namespaceUri`, `localName`, `attributes`, `text`, `rawXml`, `children`)
- [x] `==` / `hashCode` auf allen Modellklassen (inkl. deep collection equality via internem Helfer)
- [x] Deep Immutability: alle `List`- und `Map`-Felder via `List.unmodifiable()` / `Map.unmodifiable()` geschützt
- [x] Unit-Tests: 40 Tests (Konstruktion, Feld-Zugriff, Equality, Mutationsschutz, hasErrors, sealed switch, selectRasterSymbolizers)

## Phase 3: XML-Helfer

Wiederverwendbare Utilities für Namespace-Handling und Knotensuche.

- [x] `xml_helpers.dart`: Namespace-aware Element-Suche (SLD 1.0 + SE/SLD 1.1) mit Fallback auf local-name-only
- [x] Unterstützung für `sld:`- und `se:`-Präfixe, Default-Namespace und unpräfixierte Elemente
- [x] Hilfsfunktionen: `childText()`, `stringAttr()`, `doubleAttr()`, `parseColorHex()` (#RRGGBB / #AARRGGBB / 0x → ARGB-int)
- [x] Unit-Tests: 27 Tests (Namespace-Varianten, Farbkonvertierung, fehlende Attribute, Edge Cases)

## Phase 4: Parser

Bottom-up implementieren: Blatt-Parser zuerst, dann Komposition nach oben.

### 4a: RasterSymbolizerParser
- [x] `ColorMapEntry` parsen (color, quantity, opacity, label)
- [x] `ColorMap` parsen (type-Attribut, Einträge sammeln)
- [x] `ContrastEnhancement` parsen (method, gammaValue)
- [x] `RasterSymbolizer` parsen (opacity, colorMap, contrastEnhancement)
- [x] Unbekannte Kind-Elemente als `ExtensionNode` erfassen
- [x] `SldParseIssue` erzeugen bei XML-Strukturfehlern, unlesbaren Zahlenwerten oder irreparabel unvollständigen Knoten
- [x] Unit-Tests mit XML-Fragmenten

### 4b: RuleParser
- [x] `Rule` parsen (name, minScale, maxScale, rasterSymbolizer)
- [x] Delegation an `RasterSymbolizerParser`
- [x] Unit-Tests

### 4c: StyleParser
- [x] `FeatureTypeStyle` parsen (rules sammeln)
- [x] `UserStyle` parsen (name, featureTypeStyles)
- [x] Delegation an `RuleParser`
- [x] Unit-Tests

### 4d: LayerParser
- [x] `NamedLayer` parsen (name, styles)
- [x] Delegation an `StyleParser`
- [x] Unit-Tests

### 4e: SldParser (Orchestrierung)
- [x] `StyledLayerDescriptor` als Root erkennen (SLD 1.0 und 1.1)
- [x] Version-Attribut extrahieren
- [x] Delegation an `LayerParser`
- [x] `SldParseResult` zusammenbauen (document + gesammelte issues)
- [x] Ungültiges XML abfangen → `SldParseIssue` mit Severity `error`, document = null
- [x] Ungültiges UTF-8 abfangen → `SldParseIssue` mit Severity `error`
- [x] Unit-Tests

### 4f: Öffentliche API
- [x] `SldDocument.parseXmlString(String xml)` → `SldParseResult`
- [x] `SldDocument.parseBytes(List<int> bytes)` → `SldParseResult`
- [x] `SldDocument.selectRasterSymbolizers()` Convenience-Methode (Phase 2)
- [x] Integration-Tests: SLD 1.0 unprefixed, sld:-prefixed, SE/SLD 1.1 se:-prefixed, Multi-Layer

## Phase 5: Golden-Style-Tests

Echte SLD-Dateien aus dem GeoServer Raster Cookbook als Testfixtures.

- [x] Testdaten-Verzeichnis `test/fixtures/` mit 10 SLD-Dateien
- [x] Two-Color Gradient SLD
- [x] Transparent Gradient SLD
- [x] Brightness and Contrast SLD
- [x] Three-Color Gradient SLD
- [x] Alpha Channel SLD
- [x] Discrete Colors SLD (intervals)
- [x] Many Color Gradient SLD
- [x] SLD 1.0 Namespace-Variante (`sld:`-Präfix)
- [x] SE/SLD 1.1 Namespace-Variante (`se:`-Präfix)
- [x] SLD mit unbekannten Vendor-Extensions (2 VendorOption-Elemente)
- [x] 21 Golden-Tests: alle Fixtures parsen ohne Fehler, konkrete Modellwerte verifiziert

## Phase 6: Validation

Fachliche Prüfung auf Basis des geparsten Modells.

- [x] `SldValidator` Grundgerüst mit Modellpfad-Traversierung
- [x] `SldValidationResult` (`issues`, `hasErrors`, `hasWarnings`)
- [x] Klare Verantwortungsgrenze dokumentiert (dartdoc auf Validator + ValidationResult)
- [x] Raster-Validierungsregeln:
  - [x] `opacity` muss zwischen 0.0 und 1.0 liegen (`opacity-out-of-range`)
  - [x] `ColorMap` braucht mindestens einen Eintrag (`empty-color-map`)
  - [x] `quantity`-Werte sollten aufsteigend sortiert sein (`quantity-not-ascending`)
  - [x] `ColorMap type="intervals"` als `vendorExtension` markiert (`vendor-extension-intervals`)
  - [x] GammaValue muss positiv sein (`gamma-not-positive`)
- [x] ColorMap-Validierungsregeln:
  - [x] Doppelte `quantity`-Werte erkennen (`duplicate-quantity`)
  - [x] Entry-Opacity außerhalb 0.0–1.0 (`entry-opacity-out-of-range`)
- [x] 18 Unit-Tests: valide/invalide Modelle, Grenzwerte, Mehrfach-Issues, Modellpfad-Prüfung

## Phase 7: Interop (Legenden und Farbskalen)

- [x] `LegendEntry` (`colorArgb`, `label`, `quantity`, `opacity`) mit Equality
- [x] `ColorScaleStop` (`colorArgb`, `quantity`) mit Equality
- [x] `extractLegend(ColorMap)` → geordnete Legendeneinträge
- [x] `extractColorScale(ColorMap)` → nach Quantity sortierte Farbskala
- [x] 12 Unit-Tests: ramp, intervals, exactValues, Sortierung, leere ColorMaps, Many-Color

## Phase 8: API-Finalisierung und Dokumentation

- [ ] Öffentliche Exports in `lib/flutter_map_sld.dart` prüfen und aufräumen
- [ ] dartdoc-Kommentare für alle öffentlichen Klassen und Methoden
- [ ] `example/` Verzeichnis mit minimalem Nutzungsbeispiel
- [ ] `CHANGELOG.md` für v0.1.0
- [ ] `pubspec.yaml` finalisieren (description, homepage, topics)
- [ ] `dart analyze` im Verzeichnis `packages/flutter_map_sld/` ohne Warnungen
- [ ] `dart test` im Verzeichnis `packages/flutter_map_sld/` alle Tests grün
- [ ] `dart doc` im Verzeichnis `packages/flutter_map_sld/` generiert ohne Fehler

## Phase 9: Publish-Vorbereitung

- [ ] `dart pub publish --dry-run` im Verzeichnis `packages/flutter_map_sld/` erfolgreich
- [ ] LICENSE-Datei vorhanden
- [ ] README.md im Core-Package (kann auf Root-README verweisen)
- [ ] Finale Review aller öffentlichen API-Oberflächen

---

## Explizit nicht in diesem Plan

- `flutter_map_sld_io` (Datei/HTTP-Adapter) — separates Package, nach MVP
- `flutter_map_sld_flutter_map` (Flutter-Adapter) — separates Package, nach MVP
- WMS-Request-Parameter oder Request-Building
- Vektor-Symbolizer, Filter, Expressions
- Client-seitiges Raster-Rendering

## Abhängigkeiten zwischen Phasen

```
Phase 1 (Setup)
  └─► Phase 2 (Domain Model)
        ├─► Phase 3 (XML-Helfer)
        │     └─► Phase 4 (Parser) ──► Phase 5 (Golden-Tests)
        └─► Phase 6 (Validation)
              └─► Phase 7 (Interop)
                    └─► Phase 8 (API-Finalisierung)
                          └─► Phase 9 (Publish)
```

Phase 3 und Phase 6 können parallel begonnen werden, sobald Phase 2 steht.
