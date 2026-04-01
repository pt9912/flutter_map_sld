# Implementierungsplan (abgeschlossen)

> **Status:** Beide Phasen wurden in v0.5.0 umgesetzt. Dieses Dokument dient als Referenz für die getroffenen Architekturentscheidungen.

Konkreter Umsetzungsplan für die beiden Roadmap-Phasen.
Bezieht sich auf die bestehende Architektur: `sealed class Expression` / `sealed class Filter`, namespace-aware XML-Parsing, separater Validierungsschritt.

**Konventionen im gesamten Plan:**
- Jede neue Modellklasse implementiert `operator ==` und `hashCode` (wie alle bestehenden Klassen).
- Klassen mit `List`-Feldern nutzen eine Hilfs-Equality analog zu `_filterListEquals()`.
- `const`-Konstruktoren wo möglich.
- Alle neuen öffentlichen Typen werden über `flutter_map_sld.dart` exportiert.

---

## Phase 1: Zusammengesetzte Expressions

### Architekturentscheidungen

**Separate Expression-Typen statt einheitliches Funktionsmodell.**
Begründung: Das bestehende `sealed class Expression`-Pattern erlaubt exhaustive `switch`-Blöcke und ist konsistent mit dem restlichen Codebase.
Jede Funktion wird eine eigene `final class` die `Expression` erweitert.

**Typkonvertierung:**
- `evaluate()` gibt weiterhin `dynamic` zurück.
- Numerische Argumente: `num.tryParse(v.toString())` als Fallback, wenn ein Wert als String vorliegt.
- Bei inkompatiblen Typen: `null` zurückgeben (nicht werfen) — konsistent mit `PropertyName` bei fehlenden Properties.

**Fallback bei unvollständigen Argumenten:**
- Fehlende Argumente → `null`-Rückgabe bei `evaluate()`.
- Parser meldet `SldParseIssue` mit Severity `warning`.

**FormatNumber — eingeschränkter initialer Scope:**
Java DecimalFormat (GeoServer-Kompatibilität) ist komplex. Initiale Umsetzung beschränkt sich auf:
- Dezimalstellen-Rundung (z.B. `#.##` → 2 Nachkommastellen)
- Ganzzahl-Formatierung (z.B. `#` → keine Nachkommastellen)
- Tausendergruppierung wird zunächst **nicht** unterstützt; unbekannte Pattern-Zeichen werden ignoriert.
- Vollständige DecimalFormat-Kompatibilität kann in einem Folgeschritt nachgezogen werden.

### Schritt 1: Model erweitern

**Datei:** `lib/src/model/expression.dart`

Neue Klassen im bestehenden `sealed class Expression`-Baum:

```dart
/// Concatenates the string representations of its child expressions.
final class Concatenate extends Expression {
  const Concatenate({required this.expressions});
  final List<Expression> expressions;

  @override
  dynamic evaluate(Map<String, dynamic> properties) {
    final buf = StringBuffer();
    for (final e in expressions) {
      final v = e.evaluate(properties);
      if (v == null) return null;
      buf.write(v);
    }
    return buf.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Concatenate && _expressionListEquals(expressions, other.expressions);

  @override
  int get hashCode => Object.hashAll(expressions);
}

/// Formats a numeric value using a pattern string.
///
/// Initialer Scope: einfache Dezimalstellen-Rundung (z.B. `#.##`).
/// Tausendergruppierung und vollständige DecimalFormat-Kompatibilität
/// sind für einen Folgeschritt vorgesehen.
final class FormatNumber extends Expression {
  const FormatNumber({required this.numericValue, required this.pattern});
  final Expression numericValue;
  final String pattern;

  @override
  dynamic evaluate(Map<String, dynamic> properties) {
    final v = numericValue.evaluate(properties);
    if (v is! num) return null;
    // Einfache Dezimalstellen-Logik basierend auf pattern.
    // Vollständige DecimalFormat-Semantik folgt später.
    ...
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormatNumber && numericValue == other.numericValue && pattern == other.pattern;

  @override
  int get hashCode => Object.hash(numericValue, pattern);
}

/// Maps a continuous value to discrete categories via thresholds.
final class Categorize extends Expression {
  const Categorize({
    required this.lookupValue,
    required this.thresholds,   // [threshold1, threshold2, ...]
    required this.values,       // [value0, value1, value2, ...] (values.length == thresholds.length + 1)
    this.fallbackValue,
  });
  final Expression lookupValue;
  final List<Expression> thresholds;
  final List<Expression> values;
  final Expression? fallbackValue;

  @override
  dynamic evaluate(Map<String, dynamic> properties) { ... }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Categorize &&
          lookupValue == other.lookupValue &&
          _expressionListEquals(thresholds, other.thresholds) &&
          _expressionListEquals(values, other.values) &&
          fallbackValue == other.fallbackValue;

  @override
  int get hashCode => Object.hash(lookupValue, Object.hashAll(thresholds), Object.hashAll(values), fallbackValue);
}

/// Interpolates between data points.
///
/// Unterstützte Modi gemäß OGC SE 1.1: `linear` und `cubic`.
final class Interpolate extends Expression {
  const Interpolate({
    required this.lookupValue,
    required this.dataPoints,
    this.mode = InterpolateMode.linear,
    this.fallbackValue,
  });
  final Expression lookupValue;
  final List<InterpolationPoint> dataPoints;
  final InterpolateMode mode;
  final Expression? fallbackValue;

  @override
  dynamic evaluate(Map<String, dynamic> properties) { ... }

  @override
  bool operator ==(Object other) => ...;

  @override
  int get hashCode => ...;
}

/// Remaps discrete input values to output values.
final class Recode extends Expression {
  const Recode({
    required this.lookupValue,
    required this.mappings,
    this.fallbackValue,
  });
  final Expression lookupValue;
  final List<RecodeMapping> mappings;
  final Expression? fallbackValue;

  @override
  dynamic evaluate(Map<String, dynamic> properties) { ... }

  @override
  bool operator ==(Object other) => ...;

  @override
  int get hashCode => ...;
}
```

**List-Equality-Helfer** (analog zu `_filterListEquals()` in `filter.dart`):

```dart
bool _expressionListEquals(List<Expression> a, List<Expression> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
```

**Hilfstypen** (gleiche Datei oder eigene Datei `interpolation.dart`):

```dart
final class InterpolationPoint {
  const InterpolationPoint({required this.data, required this.value});
  final num data;
  final Expression value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterpolationPoint && data == other.data && value == other.value;

  @override
  int get hashCode => Object.hash(data, value);
}

/// Interpolationsmodi gemäß OGC SE 1.1.
enum InterpolateMode { linear, cubic }

final class RecodeMapping {
  const RecodeMapping({required this.inputValue, required this.outputValue});
  final Expression inputValue;
  final Expression outputValue;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecodeMapping && inputValue == other.inputValue && outputValue == other.outputValue;

  @override
  int get hashCode => Object.hash(inputValue, outputValue);
}
```

### Schritt 2: Parser erweitern

**Datei:** `lib/src/parser/parsers/expression_parser.dart`

**2a) `parseExpression()` — switch erweitern:**

```
case 'Concatenate':   → _parseConcatenate()
case 'FormatNumber':  → _parseFormatNumber()
case 'Categorize':    → _parseCategorize()
case 'Interpolate':   → _parseInterpolate()
case 'Recode':        → _parseRecode()
```

**2b) `parseFirstExpression()` refactoren:**

Aktuell sucht die Funktion hartcodiert nach `PropertyName` und `Literal`. Das muss auf eine Whitelist umgestellt werden, damit verschachtelte Expressions erkannt werden:

```dart
/// Alle bekannten Expression-Elementnamen.
const _expressionLocalNames = {
  'PropertyName', 'Literal',
  'Concatenate', 'FormatNumber', 'Categorize', 'Interpolate', 'Recode',
};

Expression? parseFirstExpression(
  XmlElement parent, List<SldParseIssue> issues, String path,
) {
  for (final child in parent.childElements) {
    if (_expressionLocalNames.contains(child.localName)) {
      return parseExpression(child, issues, '$path/${child.localName}');
    }
  }
  return null;
}
```

**2c) `parseTwoExpressions()` analog refactoren:**

Gleiche Whitelist-Prüfung statt `child.localName == 'PropertyName' || child.localName == 'Literal'`.

**2d) Neue Hilfsfunktion `parseAllExpressions()`:**

Wird für `Concatenate` benötigt — sammelt alle Expression-Kinder eines Elements:

```dart
List<Expression> parseAllExpressions(
  XmlElement parent, List<SldParseIssue> issues, String path,
) {
  final result = <Expression>[];
  for (final child in parent.childElements) {
    if (_expressionLocalNames.contains(child.localName)) {
      final expr = parseExpression(child, issues, '$path/${child.localName}');
      if (expr != null) result.add(expr);
    }
  }
  return result;
}
```

**Erwartete XML-Strukturen (SE/GeoServer):**

```xml
<Concatenate>
  <PropertyName>vorname</PropertyName>
  <Literal> </Literal>
  <PropertyName>nachname</PropertyName>
</Concatenate>

<Categorize>
  <LookupValue><PropertyName>pop</PropertyName></LookupValue>
  <Value>small</Value>
  <Threshold>10000</Threshold>
  <Value>medium</Value>
  <Threshold>100000</Threshold>
  <Value>large</Value>
</Categorize>

<Interpolate method="linear">
  <LookupValue><PropertyName>elevation</PropertyName></LookupValue>
  <InterpolationPoint><Data>0</Data><Value>#00FF00</Value></InterpolationPoint>
  <InterpolationPoint><Data>1000</Data><Value>#FF0000</Value></InterpolationPoint>
</Interpolate>

<Recode>
  <LookupValue><PropertyName>code</PropertyName></LookupValue>
  <MapItem><Data>A</Data><Value>Alpha</Value></MapItem>
  <MapItem><Data>B</Data><Value>Bravo</Value></MapItem>
</Recode>

<FormatNumber>
  <PropertyName>population</PropertyName>
  <Pattern>#.##</Pattern>
</FormatNumber>
```

### Schritt 3: Exports aktualisieren

**Datei:** `lib/flutter_map_sld.dart`

Die neuen Klassen werden automatisch exportiert, da `expression.dart` bereits exportiert wird. Falls `InterpolationPoint`, `InterpolateMode` und `RecodeMapping` in eine eigene Datei ausgelagert werden, muss ein zusätzlicher `export`-Eintrag hinzugefügt werden.

### Schritt 4: Tests

**Datei:** `test/model/expression_filter_test.dart` — neue `group`-Blöcke:

| Expression    | Testfälle                                                                              |
|---------------|----------------------------------------------------------------------------------------|
| Concatenate   | Zwei Strings, mit PropertyName, null-Argument → null, leere Liste, Equality            |
| FormatNumber  | Ganzzahl, Dezimalstellen-Rundung, nicht-numerischer Wert → null, Equality               |
| Categorize    | Unter erstem Schwellenwert, zwischen Schwellenwerten, über letztem, null-Lookup, Equality|
| Interpolate   | Exakt auf Datenpunkt, zwischen zwei Punkten (linear), unter/über Range, Fallback, Equality|
| Recode        | Bekannter Key → Value, unbekannter Key → Fallback/null, null-Lookup, Equality           |

**Datei:** `test/parser/expression_parser_test.dart` (neu oder erweitern) — XML-Roundtrip-Tests für jede neue Expression, inkl. verschachtelter Expressions.

### Schritt 5: Validierung

**Datei:** `lib/src/validation/rules/vector_rules.dart`

Optionale Validierungsregeln:
- `Categorize`: `values.length == thresholds.length + 1`
- `Interpolate`: mindestens 2 Datenpunkte, aufsteigend sortiert
- `Recode`: keine doppelten Input-Werte (Warnung)

---

## Phase 2: Spatial-Filter

### Architekturentscheidungen

**Geometrie-Repräsentation: `gml4dart` als Dependency.**

Statt eines eigenen Minimalmodells wird das Package [`gml4dart`](https://pub.dev/packages/gml4dart) (`^0.1.0`) als Dependency genutzt. Es ist reines Dart, hat nur `xml` und `collection` als Abhängigkeiten (wobei `xml` bereits eine Abhängigkeit von `flutter_map_sld` ist), und liefert:

- Typisiertes Geometrie-Modell: `GmlPoint`, `GmlLineString`, `GmlPolygon`, `GmlEnvelope`, `GmlMultiPoint`, `GmlMultiPolygon` etc.
- GML 2.x und 3.x Parsing mit Namespace-Handling
- `GmlDocument.parseXmlString()` für das Parsen einzelner GML-Elemente

Damit entfallen:
- ~~Eigenes Geometrie-Modell (`geometry.dart`)~~
- ~~Eigener GML-Parser (`geometry_parser.dart`)~~
- ~~GML-Namespace-Konstanten in `xml_helpers.dart`~~

**Dependency in `pubspec.yaml`:**

```yaml
dependencies:
  xml: ^6.3.0
  gml4dart: ^0.1.0
```

**Integration im Filter-Parser:**

GML-Geometrie-Elemente innerhalb von Spatial-Filtern werden per `gml4dart` geparst. Da der SLD-Parser das XML bereits als `XmlElement` vorliegen hat, wird das Element serialisiert und an `GmlDocument.parseXmlString()` übergeben:

```dart
import 'package:gml4dart/gml4dart.dart';

GmlGeometry? _parseGmlGeometry(XmlElement element, List<SldParseIssue> issues, String path) {
  final result = GmlDocument.parseXmlString(element.toXmlString());
  if (result.hasErrors) {
    for (final issue in result.issues) {
      issues.add(SldParseIssue(
        severity: SldIssueSeverity.warning,
        code: 'gml-parse-error',
        message: issue.message,
        location: path,
      ));
    }
    return null;
  }
  final root = result.document?.root;
  if (root is! GmlGeometry) return null;
  return root;
}
```

**Evaluationskontext: `evaluate()`-Signatur erweitern.**

Die `evaluate()`-Signatur auf `Filter` wird um einen optionalen `GmlGeometry?`-Parameter erweitert:

```dart
sealed class Filter {
  const Filter();
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry});
}
```

- Bestehende nicht-räumliche Filter ignorieren den Parameter (abwärtskompatibel im Verhalten).
- Spatial-Filter nutzen ihn für die Geometrie-Evaluation.
- `Rule.appliesTo()` wird analog erweitert: `bool appliesTo(Map<String, dynamic> properties, {double? scaleDenominator, GmlGeometry? geometry})`.

**Achtung:** Das ist ein **Breaking Change** für Code, der `Filter.evaluate` als Function-Referenz nutzt (z.B. `filters.where(f.evaluate)`). Da `evaluate` aber typischerweise mit einem Map aufgerufen wird und der Parameter optional ist, sind die meisten Aufrufe abwärtskompatibel. Der Break beschränkt sich auf Tearoff-Referenzen.

**CRS-Semantik:** Phase 2 arbeitet ausschließlich mit projizierten Koordinaten (kein CRS-Handling im Core). Distanzoperatoren (`DWithin`, `Beyond`) erwarten Einheiten in Koordinateneinheiten. CRS-Transformation liegt beim Aufrufer.

**Polygon/Polygon-Operationen:** Komplexe topologische Operationen (Polygon/Polygon-Intersection, Touches, Crosses) werden initial nur für einfache Fälle implementiert (Punkt/Polygon, Punkt/Envelope, Linie/Envelope). Nicht unterstützte Geometrie-Kombinationen geben `false` zurück. Das wird als **bekannte Einschränkung** in der API-Dokumentation festgehalten (kein Validierungsfehler, da es ein Laufzeitverhalten ist).

### Schritt 1: Dependency hinzufügen

**Datei:** `pubspec.yaml`

`gml4dart: ^0.1.0` als Dependency aufnehmen.

### Schritt 2: Spatial-Operationen

**Neue Datei:** `lib/src/eval/spatial_ops.dart`

Reine Funktionen für geometrische Berechnungen auf Basis der `gml4dart`-Typen:

```dart
import 'package:gml4dart/gml4dart.dart';

bool envelopeIntersects(GmlEnvelope a, GmlEnvelope b);
bool pointInPolygon(GmlPoint p, GmlPolygon poly);
bool pointInEnvelope(GmlPoint p, GmlEnvelope env);
double distancePointToPoint(GmlPoint a, GmlPoint b);
bool lineIntersectsEnvelope(GmlLineString line, GmlEnvelope env);
GmlEnvelope geometryEnvelope(GmlGeometry geom);
```

### Schritt 3: Filter-Modell erweitern

**Datei:** `lib/src/model/filter.dart`

Neue Klassen im `sealed class Filter`-Baum, mit `gml4dart`-Geometrietypen:

```dart
import 'package:gml4dart/gml4dart.dart';

/// Base for spatial filter operators.
sealed class SpatialFilter extends Filter {
  const SpatialFilter({this.propertyName, required this.geometry});

  /// Optionaler Verweis auf die Geometrie-Spalte des Features.
  /// Wenn null, wird die Default-Geometrie des Features verwendet.
  final String? propertyName;

  /// Die Referenzgeometrie aus dem SLD-Dokument.
  final GmlGeometry geometry;
}

final class BBox extends SpatialFilter {
  const BBox({super.propertyName, required GmlEnvelope envelope})
      : super(geometry: envelope);

  @override
  bool evaluate(Map<String, dynamic> properties, {GmlGeometry? geometry}) {
    if (geometry == null) return false;
    return envelopeIntersects(geometryEnvelope(geometry), this.geometry as GmlEnvelope);
  }

  @override
  bool operator ==(Object other) => ...;

  @override
  int get hashCode => ...;
}

final class Intersects extends SpatialFilter { ... }
final class Within extends SpatialFilter { ... }
final class Contains extends SpatialFilter { ... }
final class Touches extends SpatialFilter { ... }
final class Crosses extends SpatialFilter { ... }
final class SpatialOverlaps extends SpatialFilter { ... }
final class Disjoint extends SpatialFilter { ... }

/// Distance-based spatial filter.
sealed class DistanceFilter extends SpatialFilter {
  const DistanceFilter({
    super.propertyName,
    required super.geometry,
    required this.distance,
    this.units = '',
  });
  final double distance;
  final String units;
}

final class DWithin extends DistanceFilter { ... }
final class Beyond extends DistanceFilter { ... }
```

**Hinweis:** `Overlaps` wird als `SpatialOverlaps` benannt, um Verwechslungen mit etwaigen Flutter-Widget-Namen zu vermeiden.

### Schritt 4: Parser erweitern

**Datei:** `lib/src/parser/parsers/filter_parser.dart`

Den `switch` in `_parseFilterOperator()` erweitern:

```
case 'BBOX':       → _parseBBox()
case 'Intersects':  → _parseSpatialBinary()
case 'Within':      → _parseSpatialBinary()
case 'Contains':    → _parseSpatialBinary()
case 'Touches':     → _parseSpatialBinary()
case 'Crosses':     → _parseSpatialBinary()
case 'Overlaps':    → _parseSpatialBinary()
case 'Disjoint':    → _parseSpatialBinary()
case 'DWithin':     → _parseSpatialDistance()
case 'Beyond':      → _parseSpatialDistance()
```

Die GML-Geometrie-Elemente innerhalb der Spatial-Filter werden per `_parseGmlGeometry()` (siehe oben) an `gml4dart` delegiert. Kein eigener GML-Parser nötig.

### Schritt 5: Bestehende Filter-Signatur migrieren

**Betroffene Dateien:**

| Datei | Änderung |
|-------|----------|
| `lib/src/model/filter.dart` | `evaluate()` um `{GmlGeometry? geometry}` erweitern — alle bestehenden Subklassen ignorieren den Parameter |
| `lib/src/model/rule.dart` | `appliesTo()` um `{GmlGeometry? geometry}` erweitern, an `f.evaluate()` durchreichen |
| `lib/src/model/sld_document.dart` | `selectMatchingRules()` um `{GmlGeometry? geometry}` erweitern |
| `test/model/expression_filter_test.dart` | Bestehende Tests bleiben unverändert (optionaler Parameter) |

### Schritt 6: Exports & Tests

**Exports:** `gml4dart`-Typen werden nicht re-exportiert — Nutzer die Spatial-Filter mit Geometrien evaluieren wollen, importieren `gml4dart` direkt.

**Tests:**

| Bereich          | Testfälle                                                              |
|------------------|------------------------------------------------------------------------|
| Spatial-Ops      | pointInPolygon, pointInEnvelope, envelopeIntersects, Distanzberechnung |
| BBox-Filter      | Punkt innerhalb/außerhalb Envelope, fehlende Geometrie → false         |
| Intersects       | Punkt in Polygon, Linie schneidet Envelope                            |
| Within/Contains  | Punkt innerhalb, Punkt außerhalb                                       |
| DWithin/Beyond   | Innerhalb/außerhalb Distanzschwelle                                    |
| Parser           | Spatial-Filter-XML mit eingebetteter GML-Geometrie                    |
| Integration      | `Rule.appliesTo()` mit Spatial-Filter und Geometrie                   |

---

## Reihenfolge & Abhängigkeiten

```
Phase 1 (Expressions)          Phase 2 (Spatial-Filter)
├── 1. Model                    ├── 1. Dependency (gml4dart)
├── 2. Parser (inkl. Refactor   ├── 2. Spatial-Ops
│      parseFirstExpression)    ├── 3. Filter-Modell
├── 3. Exports                  ├── 4. Parser (delegiert GML an gml4dart)
├── 4. Tests                    ├── 5. evaluate()-Signatur migrieren
└── 5. Validierung              └── 6. Tests
```

Phase 1 hat keine Abhängigkeit zu Phase 2.
Phase 2 hat keine Abhängigkeit zu Phase 1.
Beide können unabhängig umgesetzt werden, aber Phase 1 zuerst ist sinnvoller (siehe Roadmap-Begründung).

**Hinweis:** Wenn Phase 1 zuerst umgesetzt wird, fällt der Breaking Change der `evaluate()`-Signatur erst in Phase 2 an. Wenn beide Phasen in einem Release gebündelt werden, ist nur ein Breaking Change nötig.

---

## Offene Punkte (vor Implementierung klären)

1. **FormatNumber-Tiefe:** Reicht die einfache Dezimalstellen-Rundung als initialer Scope, oder gibt es konkrete SLD-Dokumente die komplexere Patterns brauchen?
2. **Multi-Geometrien:** Sollen `GmlMultiPoint`/`GmlMultiPolygon` in Spatial-Ops unterstützt werden, oder nur einfache Geometrien?
