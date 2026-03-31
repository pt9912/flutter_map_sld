import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:test/test.dart';

void main() {
  group('ShadedRelief', () {
    test('defaults brightnessOnly to false', () {
      const sr = ShadedRelief();
      expect(sr.brightnessOnly, isFalse);
      expect(sr.reliefFactor, isNull);
    });

    test('can be constructed with all fields', () {
      const sr = ShadedRelief(brightnessOnly: true, reliefFactor: 55.0);
      expect(sr.brightnessOnly, isTrue);
      expect(sr.reliefFactor, 55.0);
    });

    test('equal instances are ==', () {
      const a = ShadedRelief(reliefFactor: 55.0);
      const b = ShadedRelief(reliefFactor: 55.0);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different values are not ==', () {
      const a = ShadedRelief(reliefFactor: 55.0);
      const b = ShadedRelief(reliefFactor: 30.0);
      expect(a, isNot(equals(b)));
    });
  });
}
