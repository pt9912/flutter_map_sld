# flutter_map_sld

Dart-/Flutter-Bibliothek zum Lesen, Validieren und Nutzen von **Styled Layer Descriptor (SLD)** und **Symbology Encoding (SE)** Styles.

## Motivation

Im Geo-Umfeld ist SLD/SE der etablierte Standard zur Beschreibung von Kartenstilen. In Flutter/Dart existiert dafür keine Bibliothek, die gleichzeitig OGC-konforme Styles versteht, GeoServer-nahe Dialekte unterstützt und eine saubere Dart-API bereitstellt.

`flutter_map_sld` schließt diese Lücke — zuerst für Rasterstile, später erweiterbar auf Vektor-Symbolizer.

## Packages

Das Projekt ist als Package-Familie aufgebaut:

| Package | Beschreibung | Abhängigkeiten |
|---------|-------------|----------------|
| `flutter_map_sld` | Pure-Dart-Core: Parsing, Domain Model, Validation, Interop | `xml` |
| `flutter_map_sld_io` | Datei-, Asset- und HTTP-Helfer | Core + `dart:io` |
| `flutter_map_sld_flutter_map` | `flutter_map`-Adapter und Widgets | Core + Flutter + `flutter_map` |

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

final rasterStyles = sld.selectRasterSymbolizers();
final colorMap = rasterStyles.first.colorMap;
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

## Dokumentation

- [Concept](docs/concept.md) — Produktvision, Scope und Zielgruppen
- [Architecture](docs/architecture.md) — Schichtmodell, Domain Model und Teststrategie

## Status

In Entwicklung. Noch kein Release auf pub.dev.
