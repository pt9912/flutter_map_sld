import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:test/test.dart';

void main() {
  // -----------------------------------------------------------------------
  // LegendEntry
  // -----------------------------------------------------------------------
  group('LegendEntry', () {
    test('equality', () {
      const a = LegendEntry(
        colorArgb: 0xFF000000,
        quantity: 0.0,
        opacity: 1.0,
        label: 'Low',
      );
      const b = LegendEntry(
        colorArgb: 0xFF000000,
        quantity: 0.0,
        opacity: 1.0,
        label: 'Low',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality on different label', () {
      const a = LegendEntry(
        colorArgb: 0xFF000000, quantity: 0.0, opacity: 1.0, label: 'A');
      const b = LegendEntry(
        colorArgb: 0xFF000000, quantity: 0.0, opacity: 1.0, label: 'B');

      expect(a, isNot(equals(b)));
    });
  });

  // -----------------------------------------------------------------------
  // ColorScaleStop
  // -----------------------------------------------------------------------
  group('ColorScaleStop', () {
    test('equality', () {
      const a = ColorScaleStop(colorArgb: 0xFFFF0000, quantity: 50.0);
      const b = ColorScaleStop(colorArgb: 0xFFFF0000, quantity: 50.0);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  // -----------------------------------------------------------------------
  // extractLegend
  // -----------------------------------------------------------------------
  group('extractLegend', () {
    test('extracts entries from ramp ColorMap', () {
      final cm = ColorMap(
        type: ColorMapType.ramp,
        entries: [
          const ColorMapEntry(
            colorArgb: 0xFF000000, quantity: 0.0, opacity: 1.0, label: 'Low'),
          const ColorMapEntry(
            colorArgb: 0xFFFFFFFF, quantity: 100.0, opacity: 1.0, label: 'High'),
        ],
      );
      final legend = extractLegend(cm);

      expect(legend, hasLength(2));
      expect(legend[0].colorArgb, 0xFF000000);
      expect(legend[0].label, 'Low');
      expect(legend[1].colorArgb, 0xFFFFFFFF);
      expect(legend[1].label, 'High');
    });

    test('extracts entries from intervals ColorMap', () {
      final cm = ColorMap(
        type: ColorMapType.intervals,
        entries: [
          const ColorMapEntry(
            colorArgb: 0xFF008000, quantity: 150.0, opacity: 1.0, label: 'Low'),
          const ColorMapEntry(
            colorArgb: 0xFF663333, quantity: 256.0, opacity: 1.0, label: 'High'),
        ],
      );
      final legend = extractLegend(cm);

      expect(legend, hasLength(2));
      expect(legend[0].quantity, 150.0);
      expect(legend[1].quantity, 256.0);
    });

    test('extracts entries from exactValues ColorMap', () {
      final cm = ColorMap(
        type: ColorMapType.exactValues,
        entries: [
          const ColorMapEntry(
            colorArgb: 0xFFFF0000, quantity: 1.0, opacity: 1.0, label: 'A'),
          const ColorMapEntry(
            colorArgb: 0xFF00FF00, quantity: 2.0, opacity: 1.0, label: 'B'),
          const ColorMapEntry(
            colorArgb: 0xFF0000FF, quantity: 3.0, opacity: 1.0, label: 'C'),
        ],
      );
      final legend = extractLegend(cm);

      expect(legend, hasLength(3));
      expect(legend[0].label, 'A');
      expect(legend[2].label, 'C');
    });

    test('preserves opacity', () {
      final cm = ColorMap(
        type: ColorMapType.ramp,
        entries: [
          const ColorMapEntry(
            colorArgb: 0xFF000000, quantity: 0.0, opacity: 0.0),
          const ColorMapEntry(
            colorArgb: 0xFF000000, quantity: 100.0, opacity: 0.5),
        ],
      );
      final legend = extractLegend(cm);

      expect(legend[0].opacity, 0.0);
      expect(legend[1].opacity, 0.5);
    });

    test('returns empty for empty ColorMap', () {
      final cm = ColorMap(type: ColorMapType.ramp, entries: []);

      expect(extractLegend(cm), isEmpty);
    });
  });

  // -----------------------------------------------------------------------
  // extractColorScale
  // -----------------------------------------------------------------------
  group('extractColorScale', () {
    test('returns sorted stops', () {
      final cm = ColorMap(
        type: ColorMapType.ramp,
        entries: [
          const ColorMapEntry(
            colorArgb: 0xFF000000, quantity: 0.0, opacity: 1.0),
          const ColorMapEntry(
            colorArgb: 0xFF808080, quantity: 50.0, opacity: 1.0),
          const ColorMapEntry(
            colorArgb: 0xFFFFFFFF, quantity: 100.0, opacity: 1.0),
        ],
      );
      final scale = extractColorScale(cm);

      expect(scale, hasLength(3));
      expect(scale[0].quantity, 0.0);
      expect(scale[1].quantity, 50.0);
      expect(scale[2].quantity, 100.0);
    });

    test('sorts unsorted entries by quantity', () {
      final cm = ColorMap(
        type: ColorMapType.ramp,
        entries: [
          const ColorMapEntry(
            colorArgb: 0xFFFFFFFF, quantity: 100.0, opacity: 1.0),
          const ColorMapEntry(
            colorArgb: 0xFF000000, quantity: 0.0, opacity: 1.0),
        ],
      );
      final scale = extractColorScale(cm);

      expect(scale[0].quantity, 0.0);
      expect(scale[0].colorArgb, 0xFF000000);
      expect(scale[1].quantity, 100.0);
      expect(scale[1].colorArgb, 0xFFFFFFFF);
    });

    test('returns empty for empty ColorMap', () {
      final cm = ColorMap(type: ColorMapType.ramp, entries: []);

      expect(extractColorScale(cm), isEmpty);
    });

    test('works with many-color gradient', () {
      final cm = ColorMap(
        type: ColorMapType.ramp,
        entries: [
          const ColorMapEntry(
            colorArgb: 0xFF000000, quantity: 95.0, opacity: 1.0),
          const ColorMapEntry(
            colorArgb: 0xFF0000FF, quantity: 110.0, opacity: 1.0),
          const ColorMapEntry(
            colorArgb: 0xFF00FF00, quantity: 135.0, opacity: 1.0),
          const ColorMapEntry(
            colorArgb: 0xFFFF0000, quantity: 160.0, opacity: 1.0),
          const ColorMapEntry(
            colorArgb: 0xFFFF00FF, quantity: 185.0, opacity: 1.0),
          const ColorMapEntry(
            colorArgb: 0xFFFFFF00, quantity: 210.0, opacity: 1.0),
          const ColorMapEntry(
            colorArgb: 0xFF00FFFF, quantity: 235.0, opacity: 1.0),
          const ColorMapEntry(
            colorArgb: 0xFFFFFFFF, quantity: 256.0, opacity: 1.0),
        ],
      );
      final scale = extractColorScale(cm);

      expect(scale, hasLength(8));
      expect(scale.first.colorArgb, 0xFF000000);
      expect(scale.last.colorArgb, 0xFFFFFFFF);

      // Verify ascending order.
      for (var i = 1; i < scale.length; i++) {
        expect(scale[i].quantity, greaterThan(scale[i - 1].quantity));
      }
    });
  });
}
