# Roadmap

Diese Roadmap sammelt die größeren fachlichen Ausbaupunkte, die nach den bisher umgesetzten Core-, IO- und Flutter-Adapter-Phasen noch offen sind.

Sie ist bewusst knapp gehalten: kein Release-Protokoll, sondern nur die nächsten funktionalen Themenblöcke.

## 1. Spatial-Filter

Ziel: Unterstützung der OGC-Filteroperatoren, die Geometriebeziehungen oder Distanzen auswerten.

Geplanter Scope:
- `BBOX`
- `Intersects`
- `Within`
- `Contains`
- `Touches`
- `Crosses`
- `Overlaps`
- `Disjoint`
- `DWithin`
- `Beyond`

Offene Architekturfragen:
- Geometrie-Repräsentation im Core: eigenes Minimalmodell oder Adapter auf existierende Geometry-Typen
- CRS-/Axis-Order-Semantik für Distanz- und BBOX-Operationen
- Evaluationskontext: wie Geometrien neben `Map<String, dynamic>` an Filter übergeben werden
- Verhalten bei fehlender Geometrie oder inkompatiblen Typen

Voraussichtliche Umsetzung:
- Domain-Modell für Spatial-Filter im Core
- Parser für OGC/SE-Filterelemente
- Evaluations-API mit explizitem Geometrie-Kontext
- Tests mit einfachen Punkt-, Linien- und Polygonfällen

## 2. Zusammengesetzte Expressions

Ziel: Unterstützung typischer SE-/GeoServer-Ausdrucksformen über `PropertyName` und `Literal` hinaus.

Geplanter Scope:
- `Concatenate`
- `FormatNumber`
- `Categorize`
- `Interpolate`
- `Recode`

Offene Architekturfragen:
- einheitliches Funktionsmodell oder separate Expression-Typen
- Typkonvertierung zwischen `String`, `num`, `bool` und `null`
- Fehler- und Fallback-Verhalten bei unvollständigen Argumenten
- Interop-Semantik zu GeoServer bei Kategorisierung und Interpolation

Voraussichtliche Umsetzung:
- Erweiterung des `Expression`-Modells im Core
- Parser für verschachtelte Expressions und Funktionsargumente
- Evaluationssemantik mit klaren Typregeln
- Einsatz in `TextSymbolizer.label` und perspektivisch in Symbolizer-Parametern

## Reihenfolge

Empfohlene Reihenfolge:
1. zusammengesetzte Expressions
2. Spatial-Filter

Begründung:
- Expressions sind für Labeling und symbolizernahe Werte breiter wiederverwendbar.
- Spatial-Filter brauchen zusätzlich einen belastbaren Geometrie- und CRS-Kontext.

## Nicht Teil dieser Roadmap

Vorerst nicht enthalten:
- vollständige OGC-SE-Funktionsabdeckung
- Rendering-Engine im Core
- generische Geometriebibliothek als harte Pflicht-Abhängigkeit
