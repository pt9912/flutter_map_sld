# Roadmap

Diese Roadmap sammelt die größeren fachlichen Ausbaupunkte, die nach den bisher umgesetzten Phasen noch offen sind.

Sie ist bewusst knapp gehalten: kein Release-Protokoll, sondern nur die nächsten funktionalen Themenblöcke.

## Umgesetzt

Die folgenden Themen wurden bereits implementiert:

- **Zusammengesetzte Expressions** (v0.5.0): `Concatenate`, `FormatNumber`, `Categorize`, `Interpolate`, `Recode` mit Parsing, Evaluation und Validierung.
- **Spatial-Filter** (v0.5.0): `BBOX`, `Intersects`, `Within`, `Contains`, `Touches`, `Crosses`, `SpatialOverlaps`, `Disjoint`, `DWithin`, `Beyond` mit GML-Geometrie-Parsing via `gml4dart`.

## Offen

### 1. Erweiterte Spatial-Operationen

Aktuelle Einschränkungen der Spatial-Filter:

- Polygon/Polygon-Operationen (Touches, Crosses) nutzen Envelope-Approximation
- Keine CRS-Transformation im Core (projizierte Koordinaten vorausgesetzt)
- Multi-Geometrien werden über Envelope-Fallback abgedeckt, nicht per Einzelgeometrie-Iteration

### 2. Vollständige FormatNumber-Unterstützung

Aktuell nur einfache Dezimalstellen-Rundung (`#.##`). Offen:

- Tausendergruppierung
- Vollständige Java-DecimalFormat-Kompatibilität (GeoServer-Standard)

### 3. Weitere OGC-Funktionen

Vorerst nicht enthalten:

- Vollständige OGC-SE-Funktionsabdeckung
- Rendering-Engine im Core
- Generische Geometriebibliothek als harte Pflicht-Abhängigkeit
