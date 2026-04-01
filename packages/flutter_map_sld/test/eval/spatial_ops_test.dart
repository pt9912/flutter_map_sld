import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:gml4dart/gml4dart.dart';
import 'package:test/test.dart';

void main() {
  group('geometryEnvelope', () {
    test('point envelope is the point itself', () {
      const p = GmlPoint(coordinate: GmlCoordinate(10, 20));
      final env = geometryEnvelope(p);
      expect(env.lowerCorner.x, 10);
      expect(env.lowerCorner.y, 20);
      expect(env.upperCorner.x, 10);
      expect(env.upperCorner.y, 20);
    });

    test('linestring envelope spans coordinates', () {
      const line = GmlLineString(coordinates: [
        GmlCoordinate(0, 0),
        GmlCoordinate(10, 5),
        GmlCoordinate(3, 8),
      ]);
      final env = geometryEnvelope(line);
      expect(env.lowerCorner.x, 0);
      expect(env.lowerCorner.y, 0);
      expect(env.upperCorner.x, 10);
      expect(env.upperCorner.y, 8);
    });

    test('polygon envelope from exterior ring', () {
      const poly = GmlPolygon(
        exterior: GmlLinearRing(coordinates: [
          GmlCoordinate(0, 0),
          GmlCoordinate(10, 0),
          GmlCoordinate(10, 10),
          GmlCoordinate(0, 10),
          GmlCoordinate(0, 0),
        ]),
      );
      final env = geometryEnvelope(poly);
      expect(env.lowerCorner.x, 0);
      expect(env.upperCorner.x, 10);
    });

    test('envelope returns itself', () {
      const env = GmlEnvelope(
        lowerCorner: GmlCoordinate(1, 2),
        upperCorner: GmlCoordinate(3, 4),
      );
      final result = geometryEnvelope(env);
      expect(result.lowerCorner.x, 1);
      expect(result.upperCorner.x, 3);
    });

    test('box converts to envelope', () {
      const box = GmlBox(
        lowerCorner: GmlCoordinate(1, 2),
        upperCorner: GmlCoordinate(3, 4),
      );
      final env = geometryEnvelope(box);
      expect(env.lowerCorner.x, 1);
      expect(env.upperCorner.x, 3);
    });

    test('multipolygon envelope', () {
      const mp = GmlMultiPolygon(polygons: [
        GmlPolygon(exterior: GmlLinearRing(coordinates: [
          GmlCoordinate(0, 0), GmlCoordinate(5, 5), GmlCoordinate(0, 0),
        ])),
        GmlPolygon(exterior: GmlLinearRing(coordinates: [
          GmlCoordinate(10, 10), GmlCoordinate(20, 20), GmlCoordinate(10, 10),
        ])),
      ]);
      final env = geometryEnvelope(mp);
      expect(env.lowerCorner.x, 0);
      expect(env.upperCorner.x, 20);
    });

    test('multilinestring envelope', () {
      const ml = GmlMultiLineString(lineStrings: [
        GmlLineString(coordinates: [GmlCoordinate(0, 0), GmlCoordinate(5, 5)]),
        GmlLineString(coordinates: [GmlCoordinate(10, 10), GmlCoordinate(15, 15)]),
      ]);
      final env = geometryEnvelope(ml);
      expect(env.lowerCorner.x, 0);
      expect(env.upperCorner.x, 15);
    });

    test('surface envelope', () {
      const surface = GmlSurface(patches: [
        GmlPolygon(exterior: GmlLinearRing(coordinates: [
          GmlCoordinate(0, 0), GmlCoordinate(10, 10), GmlCoordinate(0, 0),
        ])),
      ]);
      final env = geometryEnvelope(surface);
      expect(env.lowerCorner.x, 0);
      expect(env.upperCorner.x, 10);
    });

    test('curve envelope', () {
      const curve = GmlCurve(coordinates: [
        GmlCoordinate(0, 0), GmlCoordinate(5, 10),
      ]);
      final env = geometryEnvelope(curve);
      expect(env.lowerCorner.x, 0);
      expect(env.upperCorner.y, 10);
    });

    test('linearring envelope', () {
      const ring = GmlLinearRing(coordinates: [
        GmlCoordinate(0, 0), GmlCoordinate(10, 10), GmlCoordinate(0, 0),
      ]);
      final env = geometryEnvelope(ring);
      expect(env.lowerCorner.x, 0);
      expect(env.upperCorner.x, 10);
    });

    test('multipoint envelope', () {
      const mp = GmlMultiPoint(points: [
        GmlPoint(coordinate: GmlCoordinate(0, 0)),
        GmlPoint(coordinate: GmlCoordinate(5, 10)),
      ]);
      final env = geometryEnvelope(mp);
      expect(env.lowerCorner.x, 0);
      expect(env.upperCorner.x, 5);
      expect(env.upperCorner.y, 10);
    });
  });

  group('envelopeIntersects', () {
    test('overlapping envelopes', () {
      const a = GmlEnvelope(
          lowerCorner: GmlCoordinate(0, 0), upperCorner: GmlCoordinate(10, 10));
      const b = GmlEnvelope(
          lowerCorner: GmlCoordinate(5, 5), upperCorner: GmlCoordinate(15, 15));
      expect(envelopeIntersects(a, b), isTrue);
    });

    test('non-overlapping envelopes', () {
      const a = GmlEnvelope(
          lowerCorner: GmlCoordinate(0, 0), upperCorner: GmlCoordinate(5, 5));
      const b = GmlEnvelope(
          lowerCorner: GmlCoordinate(10, 10),
          upperCorner: GmlCoordinate(15, 15));
      expect(envelopeIntersects(a, b), isFalse);
    });

    test('touching edges count as intersecting', () {
      const a = GmlEnvelope(
          lowerCorner: GmlCoordinate(0, 0), upperCorner: GmlCoordinate(5, 5));
      const b = GmlEnvelope(
          lowerCorner: GmlCoordinate(5, 0), upperCorner: GmlCoordinate(10, 5));
      expect(envelopeIntersects(a, b), isTrue);
    });
  });

  group('pointInEnvelope', () {
    const env = GmlEnvelope(
        lowerCorner: GmlCoordinate(0, 0), upperCorner: GmlCoordinate(10, 10));

    test('inside', () {
      expect(
          pointInEnvelope(
              const GmlPoint(coordinate: GmlCoordinate(5, 5)), env),
          isTrue);
    });

    test('on boundary', () {
      expect(
          pointInEnvelope(
              const GmlPoint(coordinate: GmlCoordinate(0, 0)), env),
          isTrue);
    });

    test('outside', () {
      expect(
          pointInEnvelope(
              const GmlPoint(coordinate: GmlCoordinate(15, 5)), env),
          isFalse);
    });
  });

  group('pointInPolygon', () {
    const square = GmlPolygon(
      exterior: GmlLinearRing(coordinates: [
        GmlCoordinate(0, 0),
        GmlCoordinate(10, 0),
        GmlCoordinate(10, 10),
        GmlCoordinate(0, 10),
        GmlCoordinate(0, 0),
      ]),
    );

    test('inside', () {
      expect(
          pointInPolygon(
              const GmlPoint(coordinate: GmlCoordinate(5, 5)), square),
          isTrue);
    });

    test('outside', () {
      expect(
          pointInPolygon(
              const GmlPoint(coordinate: GmlCoordinate(15, 5)), square),
          isFalse);
    });

    test('empty ring returns false', () {
      const emptyPoly = GmlPolygon(
        exterior: GmlLinearRing(coordinates: []),
      );
      expect(
          pointInPolygon(
              const GmlPoint(coordinate: GmlCoordinate(0, 0)), emptyPoly),
          isFalse);
    });
  });

  group('distancePointToPoint', () {
    test('same point', () {
      const p = GmlPoint(coordinate: GmlCoordinate(5, 5));
      expect(distancePointToPoint(p, p), 0.0);
    });

    test('known distance', () {
      const a = GmlPoint(coordinate: GmlCoordinate(0, 0));
      const b = GmlPoint(coordinate: GmlCoordinate(3, 4));
      expect(distancePointToPoint(a, b), closeTo(5.0, 0.001));
    });
  });

  group('lineIntersectsEnvelope', () {
    const env = GmlEnvelope(
        lowerCorner: GmlCoordinate(0, 0), upperCorner: GmlCoordinate(10, 10));

    test('line with vertex inside', () {
      const line =
          GmlLineString(coordinates: [GmlCoordinate(5, 5), GmlCoordinate(20, 20)]);
      expect(lineIntersectsEnvelope(line, env), isTrue);
    });

    test('line crossing through envelope', () {
      const line = GmlLineString(
          coordinates: [GmlCoordinate(-5, 5), GmlCoordinate(15, 5)]);
      expect(lineIntersectsEnvelope(line, env), isTrue);
    });

    test('line completely outside', () {
      const line = GmlLineString(
          coordinates: [GmlCoordinate(20, 20), GmlCoordinate(30, 30)]);
      expect(lineIntersectsEnvelope(line, env), isFalse);
    });
  });

  group('geometryIntersects', () {
    test('point in polygon', () {
      const p = GmlPoint(coordinate: GmlCoordinate(5, 5));
      const poly = GmlPolygon(
        exterior: GmlLinearRing(coordinates: [
          GmlCoordinate(0, 0),
          GmlCoordinate(10, 0),
          GmlCoordinate(10, 10),
          GmlCoordinate(0, 10),
          GmlCoordinate(0, 0),
        ]),
      );
      expect(geometryIntersects(p, poly), isTrue);
      expect(geometryIntersects(poly, p), isTrue);
    });

    test('envelope fallback for unsupported combos', () {
      const poly1 = GmlPolygon(
        exterior: GmlLinearRing(coordinates: [
          GmlCoordinate(0, 0),
          GmlCoordinate(5, 0),
          GmlCoordinate(5, 5),
          GmlCoordinate(0, 5),
          GmlCoordinate(0, 0),
        ]),
      );
      const poly2 = GmlPolygon(
        exterior: GmlLinearRing(coordinates: [
          GmlCoordinate(3, 3),
          GmlCoordinate(8, 3),
          GmlCoordinate(8, 8),
          GmlCoordinate(3, 8),
          GmlCoordinate(3, 3),
        ]),
      );
      expect(geometryIntersects(poly1, poly2), isTrue);
    });
  });

  group('geometryWithin', () {
    test('point within envelope', () {
      const p = GmlPoint(coordinate: GmlCoordinate(5, 5));
      const env = GmlEnvelope(
          lowerCorner: GmlCoordinate(0, 0),
          upperCorner: GmlCoordinate(10, 10));
      expect(geometryWithin(p, env), isTrue);
    });

    test('point within polygon', () {
      const p = GmlPoint(coordinate: GmlCoordinate(5, 5));
      const poly = GmlPolygon(
        exterior: GmlLinearRing(coordinates: [
          GmlCoordinate(0, 0),
          GmlCoordinate(10, 0),
          GmlCoordinate(10, 10),
          GmlCoordinate(0, 10),
          GmlCoordinate(0, 0),
        ]),
      );
      expect(geometryWithin(p, poly), isTrue);
    });

    test('point outside polygon', () {
      const p = GmlPoint(coordinate: GmlCoordinate(15, 5));
      const poly = GmlPolygon(
        exterior: GmlLinearRing(coordinates: [
          GmlCoordinate(0, 0),
          GmlCoordinate(10, 0),
          GmlCoordinate(10, 10),
          GmlCoordinate(0, 10),
          GmlCoordinate(0, 0),
        ]),
      );
      expect(geometryWithin(p, poly), isFalse);
    });

    test('envelope within larger envelope (fallback)', () {
      const inner = GmlLineString(
          coordinates: [GmlCoordinate(2, 2), GmlCoordinate(4, 4)]);
      const outer = GmlEnvelope(
          lowerCorner: GmlCoordinate(0, 0),
          upperCorner: GmlCoordinate(10, 10));
      expect(geometryWithin(inner, outer), isTrue);
    });

    test('envelope NOT within smaller envelope (fallback)', () {
      const inner = GmlLineString(
          coordinates: [GmlCoordinate(0, 0), GmlCoordinate(20, 20)]);
      const outer = GmlEnvelope(
          lowerCorner: GmlCoordinate(5, 5),
          upperCorner: GmlCoordinate(10, 10));
      expect(geometryWithin(inner, outer), isFalse);
    });
  });

  group('geometryDistance', () {
    test('distance between non-point geometries uses centroids', () {
      const line = GmlLineString(
          coordinates: [GmlCoordinate(0, 0), GmlCoordinate(10, 0)]);
      const point = GmlPoint(coordinate: GmlCoordinate(5, 0));
      // centroid of line is (5, 0), distance to (5, 0) = 0
      expect(geometryDistance(line, point), closeTo(0.0, 0.001));
    });
  });
}
