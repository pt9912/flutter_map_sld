import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:gml4dart/gml4dart.dart';
import 'package:test/test.dart';

void main() {
  const insidePoint = GmlPoint(coordinate: GmlCoordinate(5, 5));
  const outsidePoint = GmlPoint(coordinate: GmlCoordinate(50, 50));
  const envelope = GmlEnvelope(
    lowerCorner: GmlCoordinate(0, 0),
    upperCorner: GmlCoordinate(10, 10),
  );
  const polygon = GmlPolygon(
    exterior: GmlLinearRing(coordinates: [
      GmlCoordinate(0, 0),
      GmlCoordinate(10, 0),
      GmlCoordinate(10, 10),
      GmlCoordinate(0, 10),
      GmlCoordinate(0, 0),
    ]),
  );

  group('BBox', () {
    test('point inside envelope', () {
      final f = BBox(envelope: envelope);
      expect(f.evaluate({}, geometry: insidePoint), isTrue);
    });

    test('point outside envelope', () {
      final f = BBox(envelope: envelope);
      expect(f.evaluate({}, geometry: outsidePoint), isFalse);
    });

    test('null geometry returns false', () {
      final f = BBox(envelope: envelope);
      expect(f.evaluate({}), isFalse);
    });
  });

  group('Intersects', () {
    test('point intersects polygon', () {
      final f = Intersects(geometry: polygon);
      expect(f.evaluate({}, geometry: insidePoint), isTrue);
    });

    test('point outside polygon', () {
      final f = Intersects(geometry: polygon);
      expect(f.evaluate({}, geometry: outsidePoint), isFalse);
    });

    test('null geometry returns false', () {
      final f = Intersects(geometry: polygon);
      expect(f.evaluate({}), isFalse);
    });
  });

  group('Within', () {
    test('point within envelope', () {
      final f = Within(geometry: envelope);
      expect(f.evaluate({}, geometry: insidePoint), isTrue);
    });

    test('point outside envelope', () {
      final f = Within(geometry: envelope);
      expect(f.evaluate({}, geometry: outsidePoint), isFalse);
    });
  });

  group('Contains', () {
    test('polygon contains point', () {
      final f = Contains(geometry: insidePoint);
      expect(f.evaluate({}, geometry: polygon), isTrue);
    });

    test('null geometry returns false', () {
      final f = Contains(geometry: insidePoint);
      expect(f.evaluate({}), isFalse);
    });
  });

  group('Disjoint', () {
    test('disjoint when not intersecting', () {
      final f = Disjoint(geometry: polygon);
      expect(f.evaluate({}, geometry: outsidePoint), isTrue);
    });

    test('not disjoint when intersecting', () {
      final f = Disjoint(geometry: polygon);
      expect(f.evaluate({}, geometry: insidePoint), isFalse);
    });
  });

  group('DWithin', () {
    test('point within distance', () {
      const ref = GmlPoint(coordinate: GmlCoordinate(0, 0));
      const target = GmlPoint(coordinate: GmlCoordinate(3, 4)); // dist = 5
      final f = DWithin(geometry: ref, distance: 6);
      expect(f.evaluate({}, geometry: target), isTrue);
    });

    test('point beyond distance', () {
      const ref = GmlPoint(coordinate: GmlCoordinate(0, 0));
      const target = GmlPoint(coordinate: GmlCoordinate(3, 4)); // dist = 5
      final f = DWithin(geometry: ref, distance: 4);
      expect(f.evaluate({}, geometry: target), isFalse);
    });

    test('null geometry returns false', () {
      const ref = GmlPoint(coordinate: GmlCoordinate(0, 0));
      final f = DWithin(geometry: ref, distance: 10);
      expect(f.evaluate({}), isFalse);
    });
  });

  group('Beyond', () {
    test('point beyond distance', () {
      const ref = GmlPoint(coordinate: GmlCoordinate(0, 0));
      const target = GmlPoint(coordinate: GmlCoordinate(3, 4));
      final f = Beyond(geometry: ref, distance: 4);
      expect(f.evaluate({}, geometry: target), isTrue);
    });

    test('point within distance', () {
      const ref = GmlPoint(coordinate: GmlCoordinate(0, 0));
      const target = GmlPoint(coordinate: GmlCoordinate(3, 4));
      final f = Beyond(geometry: ref, distance: 6);
      expect(f.evaluate({}, geometry: target), isFalse);
    });
  });

  group('Touches / Crosses / SpatialOverlaps', () {
    test('touches uses envelope intersection', () {
      final f = Touches(geometry: polygon);
      expect(f.evaluate({}, geometry: insidePoint), isTrue);
      expect(f.evaluate({}), isFalse);
    });

    test('crosses uses geometry intersection', () {
      final f = Crosses(geometry: polygon);
      expect(f.evaluate({}, geometry: insidePoint), isTrue);
      expect(f.evaluate({}), isFalse);
    });

    test('spatialOverlaps uses geometry intersection', () {
      final f = SpatialOverlaps(geometry: polygon);
      expect(f.evaluate({}, geometry: insidePoint), isTrue);
      expect(f.evaluate({}), isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // Spatial filter equality (non-const to avoid identical short-circuit)
  // -----------------------------------------------------------------------
  group('Spatial filter equality', () {
    test('BBox', () {
      final a = BBox(propertyName: 'geom', envelope: envelope);
      final b = BBox(propertyName: 'geom', envelope: envelope);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Intersects', () {
      final a = Intersects(propertyName: 'geom', geometry: polygon);
      final b = Intersects(propertyName: 'geom', geometry: polygon);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Within', () {
      final a = Within(geometry: envelope);
      final b = Within(geometry: envelope);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Contains', () {
      final a = Contains(geometry: insidePoint);
      final b = Contains(geometry: insidePoint);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Touches', () {
      final a = Touches(geometry: polygon);
      final b = Touches(geometry: polygon);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Crosses', () {
      final a = Crosses(geometry: polygon);
      final b = Crosses(geometry: polygon);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('SpatialOverlaps', () {
      final a = SpatialOverlaps(geometry: polygon);
      final b = SpatialOverlaps(geometry: polygon);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Disjoint', () {
      final a = Disjoint(geometry: polygon);
      final b = Disjoint(geometry: polygon);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('DWithin', () {
      final a = DWithin(geometry: insidePoint, distance: 10, units: 'm');
      final b = DWithin(geometry: insidePoint, distance: 10, units: 'm');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Beyond', () {
      final a = Beyond(geometry: insidePoint, distance: 10, units: 'km');
      final b = Beyond(geometry: insidePoint, distance: 10, units: 'km');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  // -----------------------------------------------------------------------
  // Rule.appliesTo with geometry
  // -----------------------------------------------------------------------
  group('Rule.appliesTo with geometry', () {
    test('spatial filter in rule', () {
      final rule = Rule(
        filter: BBox(envelope: envelope),
      );
      expect(rule.appliesTo({}, geometry: insidePoint), isTrue);
      expect(rule.appliesTo({}, geometry: outsidePoint), isFalse);
      expect(rule.appliesTo({}), isFalse);
    });

    test('combined property + spatial filter', () {
      final rule = Rule(
        filter: And(filters: [
          PropertyIsEqualTo(
              expression1: PropertyName('type'), expression2: Literal('city')),
          BBox(envelope: envelope),
        ]),
      );
      expect(
        rule.appliesTo({'type': 'city'}, geometry: insidePoint),
        isTrue,
      );
      expect(
        rule.appliesTo({'type': 'town'}, geometry: insidePoint),
        isFalse,
      );
      expect(
        rule.appliesTo({'type': 'city'}, geometry: outsidePoint),
        isFalse,
      );
    });
  });
}
