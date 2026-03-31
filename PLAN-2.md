# flutter_map_sld: Plan v0.2.0

Dieser Plan baut auf dem veröffentlichten v0.1.0-MVP auf und erweitert den Core um Skalenauswertung sowie das erste Adapter-Package `flutter_map_sld_io`.

Grundlage: [Concept](docs/concept.md), [Architecture](docs/architecture.md), [PLAN.md](PLAN.md) (v0.1.0, abgeschlossen).

---

## Baseline und Planungsstand

- Öffentliche Baseline auf pub.dev ist `flutter_map_sld` **v0.1.0**.
- Dieser Plan beschreibt die nächsten Schritte auf `main`.
- Bereits auf `main` umgesetzte, aber noch nicht veröffentlichte Fixes werden in diesem Dokument als **bereits im Branch vorhanden** markiert, nicht als eigener veröffentlichter Zwischenstand.
- Entscheidung: **kein separates v0.1.1 nur für den Parser-Fix**. Der bereits umgesetzte Fix wird mit dem nächsten Core-Release mit ausgeliefert.

## Phase A: Maßstabsabhängige Regelauswahl

Die Felder `minScaleDenominator` / `maxScaleDenominator` auf `Rule` sind seit v0.1.0 geparst, aber es gibt keine Auswertungslogik.

- [x] `Rule.appliesAtScale(double scaleDenominator)` → `bool`
  - `true` wenn kein Scale-Filter gesetzt oder der Wert innerhalb der Grenzen liegt
  - Grenzen sind inklusiv-unten, exklusiv-oben (OGC-Konvention)
- [x] `SldDocument.selectRasterSymbolizersAtScale(double scaleDenominator)` → filtert zusätzlich nach Maßstab
- [x] Validierungsregel: `minScaleDenominator >= maxScaleDenominator` als **Error** — ein leerer Bereich bedeutet, dass die Regel nie matchen kann; das ist kein Grenzfall, sondern ein Konfigurationsfehler
- [x] Unit-Tests: ohne Grenzen, nur min, nur max, beide, Grenzwerte (inklusiv/exklusiv), invalide Kombination
- [x] Golden-Test: SLD-Fixture mit maßstabsabhängigen Regeln

## Phase B: Erweiterte Raster-Elemente

Vervollständigt den Raster-Support über das GeoServer Cookbook hinaus.

**Vorarbeit (bereits auf `main` umgesetzt):** Bekannte-aber-nicht-implementierte OGC-Elemente (`ChannelSelection`, `ShadedRelief`, `ImageOutline`, `Geometry`, `OverlapBehavior`) wurden bisher stillschweigend verworfen. Das widersprach dem Erhaltungsprinzip aus `architecture.md`. Dieser Parser-Fix ist bereits im Branch vorhanden: Der Parser unterscheidet jetzt `_parsedRasterChildren` von `_knownButUnimplementedRasterChildren` und konserviert letztere als `ExtensionNode` mit Issue-Code `unsupported-element`. Der Fix wird mit dem nächsten Core-Release veröffentlicht, nicht als separates Zwischenrelease.

- [x] `ChannelSelection` Domain-Modell (`redChannel`, `greenChannel`, `blueChannel`, `grayChannel`)
- [x] `SelectedChannel` (`channelName`, `contrastEnhancement`)
- [x] `ShadedRelief` Domain-Modell (`brightnessOnly`, `reliefFactor`)
- [x] Parser für `ChannelSelection` und `ShadedRelief` — Elemente von `_knownButUnimplemented` nach `_parsed` verschieben
- [x] Felder in `RasterSymbolizer` ergänzen (optional, rückwärtskompatibel)
- [x] Validierungsregeln: reliefFactor-Range, Channel-Vollständigkeit bei RGB
- [x] Unit-Tests und Golden-Tests mit Mehrband-SLD

## Phase C: `flutter_map_sld_io` Adapter-Package

Erstes separates Package für Datei- und HTTP-basiertes Laden. **Nur VM/Server-Umgebungen** — kein Flutter-Asset-Zugriff (der gehört in `flutter_map_sld_flutter_map`, wie in concept.md und architecture.md definiert).

Hinweis zur Schnittstelle: Ein asynchroner Byte-Strom ist im Dart-Core als
`Stream<List<int>>` modellierbar und braucht selbst keine Abhängigkeit auf
`dart:io`. `dart:io` wird erst für konkrete Quellen wie Datei- oder
Socket-Zugriff relevant. Deshalb kann ein optionales
`SldDocument.parseAsyncStream(Stream<List<int>> byteStream)` im Core liegen,
während konkrete Reader weiter im IO-Package bleiben.

Wichtig: Ein solches `parseAsyncStream()` bringt für große Dokumente nur dann
einen echten Speichervorteil, wenn es nicht bloß den Stream einsammelt und
anschließend `parseBytes()` oder `parseXmlString()` aufruft. Falls der
Speicherbedarf großer XML-Dokumente ein Ziel ist, braucht der Core einen
separaten eventbasierten Parserpfad, der XML inkrementell liest und direkt in
das SLD-Domain-Modell überführt.

### Entscheidung: Fehlermodell

I/O-Fehler (Datei nicht gefunden, Netzwerkfehler, HTTP 404) sind keine XML-Parse-Probleme und dürfen nicht als `SldParseIssue` modelliert werden — `SldParseIssue.location` ist ein XPath-Pfad und hat bei Transportfehlern keine Semantik.

Lösung: **`SldLoadResult`** als disjunkte Erfolgs-/Fehler-Union im IO-Package:

```dart
sealed class SldLoadResult {
  const SldLoadResult();
}

final class SldLoadSuccess extends SldLoadResult {
  const SldLoadSuccess(this.parseResult);

  final SldParseResult parseResult;
}

final class SldLoadFailure extends SldLoadResult {
  const SldLoadFailure(this.error);

  final SldLoadError error;
}

class SldLoadError {
  const SldLoadError({
    required this.kind,
    required this.message,
    this.httpStatusCode,
    this.uri,
  });

  final SldLoadErrorKind kind; // fileNotFound, networkError, httpError, encodingError
  final String message;
  final int? httpStatusCode;
  final Uri? uri;
}
```

Bei erfolgreichem Laden liefert das IO-Package `SldLoadSuccess(parseResult)`. Bei Transportfehlern liefert es `SldLoadFailure(error)`. Die API vermeidet damit ungültige Zwischenzustände und hält den Core-Issue-Vertrag sauber.

### C1: Package-Setup
- [x] `packages/flutter_map_sld_io/` anlegen
- [x] `pubspec.yaml` (Dependency auf `flutter_map_sld`, `http`)
- [x] `analysis_options.yaml` (gleiche strikte Regeln wie Core)
- [x] Library-Entrypoint `lib/flutter_map_sld_io.dart`
- [x] `SldLoadResult`, `SldLoadError`, `SldLoadErrorKind` Domain-Typen
- [x] Optionaler Core-Helfer prüfen: `SldDocument.parseAsyncStream(Stream<List<int>> byteStream)` als plattformneutrale Async-API ohne `dart:io`
- [x] Dabei explizit entscheiden: Komfort-Wrapper um den bestehenden DOM-Parser (entschieden: kein eventbasierter Parserpfad, da SLD-Dokumente typischerweise klein)

### C2: Datei-Adapter
- [x] `SldIo.parseFile(String path)` → `Future<SldLoadResult>`
- [x] Fehlerbehandlung: Datei nicht gefunden, Lese-Fehler → `SldLoadError`
- [x] Unit-Tests mit temporären Dateien

### C3: HTTP-Adapter
- [x] `SldIo.parseUrl(Uri uri, {http.Client? client})` → `Future<SldLoadResult>`
- [x] Fehlerbehandlung: Netzwerkfehler → `SldLoadError(kind: networkError)`, HTTP-Status != 200 → `SldLoadError(kind: httpError, httpStatusCode: ...)`
- [x] Unit-Tests mit gemocktem HTTP-Client

### C4: CI und Publish-Vorbereitung
- [x] README.md, CHANGELOG.md, LICENSE im Package
- [x] `dart pub publish --dry-run` erfolgreich
- [x] Dockerfile: eigener Multi-Stage-Build oder erweiterte Targets für IO-Package (analyze, test)
- [x] `.github/workflows/ci.yml` erweitern: analyze/test-Jobs für `flutter_map_sld_io`
- [x] Neuer Publish-Workflow für `flutter_map_sld_io` mit eigenem Tag-Pattern `flutter_map_sld_io-vX.Y.Z`
- [x] `pub.dev`-Automated-Publishing für `flutter_map_sld_io` auf dasselbe Repo konfigurieren, aber mit eigenem Tag-Pattern `flutter_map_sld_io-v{{version}}`

## Phase D: Vendor Options

Strukturiertes Parsing von GeoServer `<VendorOption>` Elementen. Erster Scope: `RasterSymbolizer`. Das Modell wird bewusst so angelegt, dass es später auf beliebige Symbolizer-Typen erweitert werden kann, ohne Breaking Changes.

- [ ] `VendorOption` Domain-Modell (`name`, `value`) — als eigenständige Klasse in `model/vendor_option.dart`, nicht an `RasterSymbolizer` gebunden
- [ ] Parser: `<VendorOption name="...">value</VendorOption>` → typisiertes Modell
- [ ] `VendorOption`-Liste auf `RasterSymbolizer` als erstes Einsatzfeld (additiv zu `extensions`)
- [ ] Rückwärtskompatibel: `ExtensionNode`-Erfassung bleibt für alle nicht als `VendorOption` erkannten Elemente
- [ ] Spätere Erweiterbarkeit: `VendorOption`-Listen können bei Bedarf auf `Rule`, `UserStyle` etc. ergänzt werden — das Domain-Modell ist dafür vorbereitet
- [ ] Unit-Tests

---

## Explizit nicht in diesem Plan

- `flutter_map_sld_flutter_map` (Flutter-Adapter, inkl. Asset-Zugriff) — braucht konkreten Use-Case als Treiber
- Vektor-Symbolizer (`PointSymbolizer`, `LineSymbolizer`, `PolygonSymbolizer`, `TextSymbolizer`)
- Filter und Expressions (`ogc:Filter`, `PropertyIsEqualTo`, etc.)
- WMS-Request-Parameter oder Request-Building
- Client-seitiges Raster-Rendering

## Abhängigkeiten zwischen Phasen

```
Phase A (Skalenauswertung)     ──► unabhängig, kann sofort starten
Phase B (Erweiterte Raster)    ──► unabhängig, Vorarbeit (Parser-Fix) bereits erledigt
Phase C (IO-Package)           ──► unabhängig vom Core-Ausbau
Phase D (Vendor Options)       ──► unabhängig, kann parallel starten
```

Alle vier Phasen sind unabhängig voneinander und können in beliebiger Reihenfolge oder parallel bearbeitet werden.

## Release-Strategie

- **Kein separates v0.1.1**: Der bereits auf `main` vorhandene Parser-Fix wird mit dem nächsten Core-Release gebündelt veröffentlicht.
- **v0.2.0** `flutter_map_sld`: Phase A + B + D sowie der bereits vorhandene Parser-Fix
- **v0.1.0** `flutter_map_sld_io`: Phase C als erstes Adapter-Package
- Core-Releases werden weiter über Tags `flutter_map_sld-vX.Y.Z` veröffentlicht.
- `flutter_map_sld_io` erhält einen eigenen Publish-Workflow und eigene Tags `flutter_map_sld_io-vX.Y.Z`.
- Adapter-Packages definieren eine normale semver-Constraint auf den Core, z.B. `flutter_map_sld: ^0.2.0`, statt eine harte Versionskopplung zu erzwingen.
