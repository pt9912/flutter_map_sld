# flutter_map_sld

Dart-/Flutter-Bibliothek zum Lesen, Validieren und Nutzen von **Styled Layer Descriptor (SLD)** und **Symbology Encoding (SE)** Styles.

## Motivation

Im Geo-Umfeld ist SLD/SE der etablierte Standard zur Beschreibung von Kartenstilen. In Flutter/Dart existiert dafür keine Bibliothek, die gleichzeitig OGC-konforme Styles versteht, GeoServer-nahe Dialekte unterstützt und eine saubere Dart-API bereitstellt.

`flutter_map_sld` schließt diese Lücke — zuerst für Rasterstile, später erweiterbar auf Vektor-Symbolizer.

## Packages

Das Projekt ist als kleine Package-Familie aufgebaut.

| Package                       | Status     | Beschreibung                                                                  | Abhängigkeiten                 |
| ----------------------------- | ---------- | ----------------------------------------------------------------------------- | ------------------------------ |
| `flutter_map_sld`             | v0.1.0     | Pure-Dart-Core: Parsing, Domain Model, Validation, Legend-/Farbskalen-Interop | `xml`                          |
| `flutter_map_sld_io`          | v0.1.0     | Datei- und HTTP-Helfer für Dart-/VM-Umgebungen                                | Core + `dart:io` + `http`      |
| `flutter_map_sld_flutter_map` | unreleased | Flutter-Asset-Helfer, `flutter_map`-Adapter und Widgets                       | Core + Flutter + `flutter_map` |

Der Core enthält bewusst keine Abhängigkeit auf `dart:io`, Flutter oder `flutter_map` und läuft auf Dart VM, Flutter Mobile, Desktop und Web.

## Beispiel

```dart
import 'package:flutter_map_sld/flutter_map_sld.dart';

final parseResult = SldDocument.parseXmlString(xml);

if (parseResult.hasErrors) {
  for (final issue in parseResult.issues) {
    print('${issue.severity}: ${issue.message}');
  }
  return;
}

final sld = parseResult.document!;
final validation = SldValidator().validate(sld);

if (validation.hasErrors) {
  for (final issue in validation.issues) {
    print('${issue.severity}: ${issue.message}');
  }
  return;
}

final rasterStyles = sld.selectRasterSymbolizers();
if (rasterStyles.isEmpty) {
  return;
}

final colorMap = rasterStyles.first.colorMap;
if (colorMap == null) {
  return;
}

for (final entry in colorMap.entries) {
  print('${entry.label}: ${entry.colorArgb}');
}
```

## MVP-Scope (v1)

Der erste Release ist **raster-first** und umfasst den Pure-Dart-Core:

- Parsing von `StyledLayerDescriptor`, `NamedLayer`, `UserStyle`, `FeatureTypeStyle`, `Rule`, `RasterSymbolizer`
- Rasterelemente: `Opacity`, `ColorMap`, `ColorMapEntry`, `ContrastEnhancement`
- GeoServer-Praxisfälle: Rampen, Alpha-Verläufe, diskrete Intervalle
- Getrennte Parse- und Validation-Ergebnisse
- Legendendaten und Farbskalen aus Rasterstilen

## Standards

- [OGC Symbology Encoding (SE) 1.1.0](https://www.ogc.org/standards/se/)
- [OGC Styled Layer Descriptor (SLD) 1.0/1.1](https://www.ogc.org/standards/sld/)
- [GeoServer Raster Cookbook](https://docs.geoserver.org/stable/en/user/styling/sld/cookbook/rasters.html) als Referenz für Praxisfälle

## Entwicklung

Kein lokales Dart SDK nötig — alle Befehle laufen via Docker:

```bash
# Analyse
docker build --target analyze -t flutter_map_sld:analyze .

# Tests
docker build --target test -t flutter_map_sld:test .

# Dokumentation generieren
docker build --target doc -t flutter_map_sld:doc .

# Publish Dry-Run
docker build --target publish-check -t flutter_map_sld:publish-check .

# IO-Package
docker build --target io-analyze -t flutter_map_sld_io:analyze .
docker build --target io-test -t flutter_map_sld_io:test .
docker build --target io-doc -t flutter_map_sld_io:doc .
docker build --target io-publish-check -t flutter_map_sld_io:publish-check .

# Flutter-Adapter-Package
docker build --target flutter-map-analyze -t flutter_map_sld_flutter_map:analyze .
docker build --target flutter-map-test -t flutter_map_sld_flutter_map:test .
docker build --target flutter-map-doc -t flutter_map_sld_flutter_map:doc .
docker build --target flutter-map-publish-check -t flutter_map_sld_flutter_map:publish-check .
```

### Manueller Publish via Docker

Für den allerersten Publish eines neuen Packages (automatisiertes Publishing erfordert eine existierende Version auf pub.dev):

```bash
# Core
docker build --target publish-check -t flutter_map_sld:publish .
docker run --rm -it --net=host flutter_map_sld:publish sh -c 'dart pub publish'

# IO-Package
docker build --target io-publish-check -t flutter_map_sld_io:publish .
docker run --rm -it --net=host flutter_map_sld_io:publish sh -c 'dart pub publish'

# Flutter-Adapter-Package
docker build --target flutter-map-publish-check -t flutter_map_sld_flutter_map:publish .
docker run --rm -it --net=host flutter_map_sld_flutter_map:publish sh -c 'flutter pub publish'
```

Automated-Publishing-Konfiguration:
- Core: https://pub.dev/packages/flutter_map_sld/admin
- IO: https://pub.dev/packages/flutter_map_sld_io/admin
- Flutter-Adapter: nach dem ersten Publish auf pub.dev ergänzen

Mit lokalem Dart SDK (>=3.0.0):

```bash
# Core
cd packages/flutter_map_sld
dart pub get && dart analyze && dart test

# IO-Package
cd packages/flutter_map_sld_io
dart pub get && dart analyze && dart test
dart pub publish --dry-run

# Flutter-Adapter-Package
cd packages/flutter_map_sld_flutter_map
flutter pub get && flutter analyze && flutter test
flutter pub publish --dry-run
```

## Dokumentation

- [Concept](docs/concept.md) — Produktvision, Scope und Zielgruppen
- [Architecture](docs/architecture.md) — Schichtmodell, Domain Model und Teststrategie

## Status

`flutter_map_sld` v0.2.0 und `flutter_map_sld_io` v0.1.0 sind auf pub.dev veröffentlicht. `flutter_map_sld_flutter_map` ist jetzt im Workspace angelegt, aber noch nicht auf pub.dev veröffentlicht.
