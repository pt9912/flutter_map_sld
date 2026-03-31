import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:test/test.dart';

void main() {
  group('Stroke', () {
    test('can be constructed with all fields', () {
      const s = Stroke(
        colorArgb: 0xFF000000,
        width: 2.0,
        opacity: 0.8,
        dashArray: [5.0, 3.0],
        lineCap: 'round',
        lineJoin: 'bevel',
      );
      expect(s.colorArgb, 0xFF000000);
      expect(s.width, 2.0);
      expect(s.dashArray, [5.0, 3.0]);
    });

    test('equal instances are ==', () {
      const a = Stroke(colorArgb: 0xFF000000, width: 1.0);
      const b = Stroke(colorArgb: 0xFF000000, width: 1.0);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('dashArray equality', () {
      const a = Stroke(dashArray: [5.0, 3.0]);
      const b = Stroke(dashArray: [5.0, 3.0]);
      const c = Stroke(dashArray: [5.0, 2.0]);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('Fill', () {
    test('can be constructed', () {
      const f = Fill(colorArgb: 0xFFFF0000, opacity: 0.5);
      expect(f.colorArgb, 0xFFFF0000);
      expect(f.opacity, 0.5);
    });

    test('equal instances are ==', () {
      const a = Fill(colorArgb: 0xFFFF0000);
      const b = Fill(colorArgb: 0xFFFF0000);
      expect(a, equals(b));
    });
  });

  group('Mark', () {
    test('can be constructed with fill and stroke', () {
      const m = Mark(
        wellKnownName: 'circle',
        fill: Fill(colorArgb: 0xFFFF0000),
        stroke: Stroke(colorArgb: 0xFF000000),
      );
      expect(m.wellKnownName, 'circle');
      expect(m.fill, isNotNull);
      expect(m.stroke, isNotNull);
    });

    test('equal instances are ==', () {
      const a = Mark(wellKnownName: 'star');
      const b = Mark(wellKnownName: 'star');
      expect(a, equals(b));
    });
  });

  group('ExternalGraphic', () {
    test('can be constructed', () {
      const eg = ExternalGraphic(
        onlineResource: 'http://example.com/icon.png',
        format: 'image/png',
      );
      expect(eg.onlineResource, 'http://example.com/icon.png');
      expect(eg.format, 'image/png');
    });
  });

  group('Graphic', () {
    test('can be constructed with mark', () {
      const g = Graphic(
        mark: Mark(wellKnownName: 'circle'),
        size: 10.0,
        rotation: 45.0,
      );
      expect(g.mark!.wellKnownName, 'circle');
      expect(g.size, 10.0);
      expect(g.rotation, 45.0);
    });
  });

  group('PointSymbolizer', () {
    test('can be constructed', () {
      const ps = PointSymbolizer(
        graphic: Graphic(
          mark: Mark(wellKnownName: 'square'),
          size: 8.0,
        ),
      );
      expect(ps.graphic!.mark!.wellKnownName, 'square');
    });

    test('equal instances are ==', () {
      const a = PointSymbolizer();
      const b = PointSymbolizer();
      expect(a, equals(b));
    });
  });

  group('LineSymbolizer', () {
    test('can be constructed', () {
      const ls = LineSymbolizer(
        stroke: Stroke(colorArgb: 0xFF0000FF, width: 2.0),
      );
      expect(ls.stroke!.width, 2.0);
    });
  });

  group('PolygonSymbolizer', () {
    test('can be constructed with fill and stroke', () {
      const ps = PolygonSymbolizer(
        fill: Fill(colorArgb: 0xFFAAAAAA, opacity: 0.5),
        stroke: Stroke(colorArgb: 0xFF000000, width: 0.5),
      );
      expect(ps.fill!.opacity, 0.5);
      expect(ps.stroke!.width, 0.5);
    });
  });
}
