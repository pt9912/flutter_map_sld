# flutter_map_sld: Concept

## Ziel

`flutter_map_sld` soll eine Dart-/Flutter-Bibliothek werden, mit der Styled Layer Descriptor (SLD) und Symbology Encoding (SE) Styles gelesen, validiert und in Flutter-Anwendungen nutzbar gemacht werden können.

Der praktische Fokus liegt auf zwei Einsatzfällen:

1. SLD/SE-Dokumente aus GeoServer- oder OGC-konformen Quellen in Dart einlesen.
2. Die Styles in Flutter weiterverwenden, insbesondere für `flutter_map`-basierte Anwendungen und WMS-nahe Workflows.

## Problem

Im Geo-Umfeld ist SLD/SE ein etablierter Standard zur Beschreibung von Kartenstilen. In Flutter/Dart existiert dafür jedoch keine etablierte Bibliothek, die gleichzeitig:

- OGC-konforme Styles versteht,
- GeoServer-nahe SLD-Dialekte pragmatisch unterstützt,
- eine saubere Dart-API bereitstellt,
- und sich in mobile und Web-Flutter-Anwendungen integrieren lässt.

Gerade für Rasterstile zeigt das GeoServer-Cookbook wichtige Praxisfälle wie:

- Farbverläufe mit `ColorMap`
- Transparenz und Alpha-Verläufe
- `ContrastEnhancement`
- diskrete Klassen statt kontinuierlicher Rampen

Diese Muster sollen zuerst unterstützt werden.

## Standards und fachlicher Rahmen

Die Bibliothek orientiert sich an:

- OGC Symbology Encoding (SE) 1.1.0 als Styling-Sprache
- OGC Styled Layer Descriptor (SLD) 1.0/1.1 als Dokument- und WMS-Kontext
- GeoServer als wichtigem Referenzsystem für reale SLD-Dateien

Wichtige fachliche Einordnung:

- SE beschreibt die Symbolisierung.
- SLD beschreibt, wie Styles auf Layer angewendet und in WMS-Kontexten transportiert werden.
- GeoServer nutzt SLD als primäre Stylesprache und implementiert zusätzlich praxisrelevante Erweiterungen.

## Produktvision

Die Bibliothek soll nicht nur XML parsen, sondern eine belastbare Style-Domäne für Dart bereitstellen.

Das heißt:

- XML rein
- typisierte Dart-Objekte raus
- Validierung und Fehlermeldungen vorhanden
- Weiterverarbeitung für Flutter/`flutter_map` möglich

Langfristig soll das Projekt sowohl servernahe als auch clientseitige Nutzung erlauben:

- SLD lesen und in getrennten Adapter-Packages für WMS-nahe Workflows nutzbar machen
- Legendendaten und Stilinformationen extrahieren
- definierte Teilmengen clientseitig auswerten

Plattformziel:

- der Core soll auf Dart VM sowie Flutter Mobile, Desktop und Web nutzbar sein
- deshalb darf die Kern-API keine verpflichtende Abhängigkeit auf `dart:io`, Flutter oder `flutter_map` enthalten
- das Projekt wird als kleine Package-Familie geplant:
  - `flutter_map_sld` als reiner Dart-Core
  - `flutter_map_sld_io` für Datei-/HTTP-Helfer
  - `flutter_map_sld_flutter_map` für Flutter- und `flutter_map`-spezifische Adapter

## Zielgruppen und Szenarien

- **Flutter-Teams mit GeoServer-Infrastruktur**: Ein Team zeigt WMS-Raster-Layer an und will die Legende aus dem SLD ableiten, statt sie manuell zu pflegen.
- **Anwendungen mit extern definierten Styles**: Eine Umwelt-App bezieht Niederschlagskarten per WMS; die zugehörigen SLD-Styles sollen clientseitig für Legenden und Farbskalen genutzt werden.
- **Interoperabler Style-Austausch**: Ein Kataster-Projekt pflegt Styles zentral im GeoServer und will dieselben Stilinformationen in der Flutter-App verwenden, ohne sie doppelt zu definieren.
- **Geo-Apps mit standardnaher Darstellung**: Eine Monitoring-App stellt Rasterdaten mit GeoServer-Farbverläufen dar und benötigt Zugriff auf `ColorMap`-Einträge für eigene Visualisierungen.

## Scope

Der Scope folgt bewusst einer inkrementellen Releasestrategie: zuerst ein belastbarer Core für Parsing und Validierung, danach gezielte Interop-Packages und später Rendering-nahe Funktionen.

### MVP

Der erste sinnvolle Release sollte raster-first sein und ausschließlich den Pure-Dart-Core umfassen.

Enthalten:

- Einlesen von SLD-XML im Core aus String und Bytes
- Parsing zentraler SLD/SE-Strukturen:
  - `StyledLayerDescriptor`
  - `NamedLayer`
  - `UserStyle`
  - `FeatureTypeStyle`
  - `Rule`
  - `RasterSymbolizer`
- Unterstützung der wichtigsten Rasterelemente:
  - `Opacity`
  - `ColorMap`
  - `ColorMapEntry`
  - `ContrastEnhancement`
- Unterstützung häufiger GeoServer-Praxisfälle:
  - Rampen
  - Alpha-Verläufe
  - diskrete Intervalle via `ColorMap type="intervals"`
- getrennte Parse- und Validation-Ergebnisse
- Dart-API zum Inspizieren und Weiterreichen von Styles
- Legendendaten und Farbskalen aus Rasterstilen ableiten

Explizit nicht Teil des MVP:

- Datei-, Asset- oder HTTP-Helfer im Core
- `flutter_map`-spezifische Adapter
- WMS-Request-Parameter oder Request-Building

### Spätere Ausbaustufen

Bereits umgesetzt:

- ~~`PointSymbolizer`, `LineSymbolizer`, `PolygonSymbolizer`, `TextSymbolizer`~~ (v0.4.0)
- ~~Filter und Expressions~~ (v0.4.0 Basis, v0.5.0 Composite Expressions)
- ~~Maßstabsabhängige Regeln~~ (v0.2.0)
- ~~`ChannelSelection`, `ShadedRelief`~~ (v0.2.0)
- ~~Vendor Options~~ (v0.2.0)
- ~~`flutter_map_sld_io` als separates Adapter-Package~~ (v0.1.0)
- ~~Direkte Adapter für `flutter_map`~~ (v0.1.0)
- ~~WMS-Interop und Request-Helfer~~ (flutter_map_sld_io v0.2.0)
- ~~Legendenerzeugung~~ (v0.1.0)
- ~~Spatial-Filter (BBOX, Intersects, Within, DWithin etc.)~~ (v0.5.0)
- ~~Zusammengesetzte Expressions (Concatenate, Categorize, Interpolate, Recode)~~ (v0.5.0)

Noch offen:

- `ImageOutline`
- Erweiterte Spatial-Operationen (Polygon/Polygon, CRS-Handling)
- Vollständige FormatNumber/DecimalFormat-Kompatibilität
- Style-Vorschau

## Nicht-Ziele für v1

- Vollständige Implementierung des gesamten OGC-Standards
- Vollständige Rendering-Engine für alle Symbolizer in Flutter
- Garantierte 1:1-Reproduktion jedes GeoServer-Stils clientseitig
- Unterstützung beliebiger Vendor Extensions ohne definierte Support-Matrix
- Vermischung von Pure-Dart-Core und Flutter-/I/O-spezifischen Laufzeitabhängigkeiten

## Produktprinzipien

- Standardnah, aber pragmatisch — OGC als Leitlinie, nicht als Dogma
- Fehler transparent machen statt stillschweigend ignorieren
- Erweiterbar für OGC-konforme und GeoServer-spezifische Dialekte

Architekturelle Prinzipien (Trennung Parser/Interop, Core/Adapter, Parse/Validation, Package-Schnitt) sind im Detail in `architecture.md` dokumentiert.

## API-Ziele

Die API soll drei Ebenen anbieten:

1. Parsing
   - SLD-XML in ein Dart-Modell überführen
2. Validierung
   - fachliche und strukturelle Probleme erkennbar machen
3. Interop
   - Styles für Legendendarstellung und spätere Adapter-Packages nutzbar machen

Beispielhafte Ziel-API:

```dart
final parseResult = SldDocument.parseXmlString(xml);

if (parseResult.hasErrors) {
  // Fehlermeldungen anzeigen oder loggen
}

final sld = parseResult.document;
if (sld == null) {
  return;
}

final validation = SldValidator().validate(sld);

if (validation.hasErrors) {
  // Fachliche oder Support-bezogene Probleme behandeln
}

final rasterStyles = sld.selectRasterSymbolizers();
final colorMap = rasterStyles.first.colorMap;
```

## Risiken

- **Fundamentales Rendering-Limit**: Rasterstile (z.B. `ColorMap`-Rampen) lassen sich clientseitig nur dann pixelgenau anwenden, wenn Rohdaten (Pixelwerte) vorliegen. Bei vorgerenderten WMS-Kacheln ist nur die Metadaten-Nutzung (Legende, Farbskala, Stilinformation) möglich — kein clientseitiges Re-Rendering. Dieses Limit beeinflusst den gesamten Interop-Layer und muss bei der API-Kommunikation transparent sein.
- **OGC-Standard-Komplexität**: Der Standard ist umfangreich, inkonsistent implementiert und in der Praxis oft durch Serverdialekte erweitert. Eine vollständige Abdeckung ist unrealistisch; die Support-Matrix muss klar kommunizieren, was unterstützt wird.
- **flutter_map-Grenzen**: `flutter_map` ist keine generische OGC-Rendering-Engine. Die Bibliothek kann Stilinformationen bereitstellen, aber nicht jede SLD-Regel direkt in eine `flutter_map`-Darstellung übersetzen.
- **Paket-Schnitt und Release-Koordination**: Die Trennung in Core- und Adapter-Packages vermeidet falsche Abhängigkeitsmodelle in `pub`, erhöht aber die Notwendigkeit, API-Grenzen und Versionierung sauber zu pflegen.

## Erfolgskriterien

- Die 7 SLD-Beispiele aus dem GeoServer Raster Cookbook (Two-Color Gradient, Transparent Gradient, Brightness and Contrast, Three-Color Gradient, Alpha Channel, Discrete Colors, Many Color Gradient) werden ohne Parse-Fehler eingelesen und validiert.
- Für jede eingelesene `ColorMapEntry` liegen `color` (als ARGB-int), `quantity`, `opacity` und `label` als typisierte Dart-Werte vor.
- Eine SLD mit `opacity > 1.0` erzeugt mindestens eine `SldValidationIssue` mit Severity `error`.
- Eine SLD mit unbekannten Vendor-Elementen erzeugt Parse-Issues der Severity `info` oder `warning`, aber keinen Abbruch.
- Unbekannte Vendor-Teilbäume bleiben im Modell strukturell erhalten und können späteren Adaptern oder Debugging-Tools zur Verfügung gestellt werden.
- SLD-Dokumente in den Namespace-Varianten SLD 1.0 (`sld:`-Präfix) und SE/SLD 1.1 (`se:`-Präfix) werden identisch geparst.
- Das Core-Package `flutter_map_sld` importiert weder `dart:io` noch Flutter-Packages.

## Referenzen

- GeoServer Raster Cookbook: https://docs.geoserver.org/stable/en/user/styling/sld/cookbook/rasters.html
- OGC Symbology Encoding: https://www.ogc.org/standards/se/
- OGC Styled Layer Descriptor: https://www.ogc.org/standards/sld/
