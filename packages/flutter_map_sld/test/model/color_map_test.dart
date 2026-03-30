import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:test/test.dart';

void main() {
  group('ColorMapType', () {
    test('has three values', () {
      expect(ColorMapType.values, hasLength(3));
      expect(ColorMapType.values, contains(ColorMapType.ramp));
      expect(ColorMapType.values, contains(ColorMapType.intervals));
      expect(ColorMapType.values, contains(ColorMapType.exactValues));
    });
  });

  group('ColorMapEntry', () {
    test('can be constructed with all fields', () {
      const entry = ColorMapEntry(
        colorArgb: 0xFF00FF00,
        quantity: 100.0,
        opacity: 0.8,
        label: 'Medium',
      );

      expect(entry.colorArgb, 0xFF00FF00);
      expect(entry.quantity, 100.0);
      expect(entry.opacity, 0.8);
      expect(entry.label, 'Medium');
    });

    test('label defaults to null', () {
      const entry = ColorMapEntry(
        colorArgb: 0xFFFF0000,
        quantity: 0.0,
        opacity: 1.0,
      );

      expect(entry.label, isNull);
    });

    test('equal entries are ==', () {
      const a = ColorMapEntry(
        colorArgb: 0xFF00FF00,
        quantity: 50.0,
        opacity: 1.0,
        label: 'L',
      );
      const b = ColorMapEntry(
        colorArgb: 0xFF00FF00,
        quantity: 50.0,
        opacity: 1.0,
        label: 'L',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different entries are not ==', () {
      const a = ColorMapEntry(
        colorArgb: 0xFF00FF00,
        quantity: 50.0,
        opacity: 1.0,
      );
      const b = ColorMapEntry(
        colorArgb: 0xFFFF0000,
        quantity: 50.0,
        opacity: 1.0,
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('ColorMap', () {
    test('can be constructed with entries', () {
      final map = ColorMap(
        type: ColorMapType.ramp,
        entries: [
          const ColorMapEntry(
            colorArgb: 0xFF000000,
            quantity: 0.0,
            opacity: 1.0,
          ),
          const ColorMapEntry(
            colorArgb: 0xFFFFFFFF,
            quantity: 100.0,
            opacity: 1.0,
          ),
        ],
      );

      expect(map.type, ColorMapType.ramp);
      expect(map.entries, hasLength(2));
      expect(map.entries.first.quantity, 0.0);
      expect(map.entries.last.quantity, 100.0);
    });

    test('entries list is unmodifiable', () {
      final map = ColorMap(
        type: ColorMapType.ramp,
        entries: [
          const ColorMapEntry(
            colorArgb: 0xFF000000,
            quantity: 0.0,
            opacity: 1.0,
          ),
        ],
      );

      expect(
        () => map.entries.add(
          const ColorMapEntry(
            colorArgb: 0xFFFFFFFF,
            quantity: 1.0,
            opacity: 1.0,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('mutation of source list does not affect ColorMap', () {
      final source = <ColorMapEntry>[
        const ColorMapEntry(
          colorArgb: 0xFF000000,
          quantity: 0.0,
          opacity: 1.0,
        ),
      ];
      final map = ColorMap(type: ColorMapType.ramp, entries: source);

      source.add(
        const ColorMapEntry(
          colorArgb: 0xFFFFFFFF,
          quantity: 1.0,
          opacity: 1.0,
        ),
      );

      expect(map.entries, hasLength(1));
    });

    test('equal ColorMaps are ==', () {
      final a = ColorMap(
        type: ColorMapType.intervals,
        entries: [
          const ColorMapEntry(
            colorArgb: 0xFF000000,
            quantity: 0.0,
            opacity: 1.0,
          ),
        ],
      );
      final b = ColorMap(
        type: ColorMapType.intervals,
        entries: [
          const ColorMapEntry(
            colorArgb: 0xFF000000,
            quantity: 0.0,
            opacity: 1.0,
          ),
        ],
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
