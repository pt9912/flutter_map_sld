import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:test/test.dart';

void main() {
  group('Rule.appliesAtScale', () {
    test('no bounds — always applies', () {
      const rule = Rule();
      expect(rule.appliesAtScale(0), isTrue);
      expect(rule.appliesAtScale(100000), isTrue);
      expect(rule.appliesAtScale(double.maxFinite), isTrue);
    });

    test('only min — applies at and above min', () {
      const rule = Rule(minScaleDenominator: 50000);
      expect(rule.appliesAtScale(49999), isFalse);
      expect(rule.appliesAtScale(50000), isTrue); // inclusive lower
      expect(rule.appliesAtScale(50001), isTrue);
    });

    test('only max — applies below max', () {
      const rule = Rule(maxScaleDenominator: 100000);
      expect(rule.appliesAtScale(99999), isTrue);
      expect(rule.appliesAtScale(100000), isFalse); // exclusive upper
      expect(rule.appliesAtScale(100001), isFalse);
    });

    test('both bounds — inclusive lower, exclusive upper', () {
      const rule = Rule(
        minScaleDenominator: 50000,
        maxScaleDenominator: 100000,
      );
      expect(rule.appliesAtScale(49999), isFalse);
      expect(rule.appliesAtScale(50000), isTrue); // inclusive lower
      expect(rule.appliesAtScale(75000), isTrue);
      expect(rule.appliesAtScale(99999), isTrue);
      expect(rule.appliesAtScale(100000), isFalse); // exclusive upper
    });

    test('equal min and max — never applies', () {
      const rule = Rule(
        minScaleDenominator: 50000,
        maxScaleDenominator: 50000,
      );
      expect(rule.appliesAtScale(49999), isFalse);
      expect(rule.appliesAtScale(50000), isFalse);
      expect(rule.appliesAtScale(50001), isFalse);
    });

    test('inverted bounds (min > max) — never applies', () {
      const rule = Rule(
        minScaleDenominator: 100000,
        maxScaleDenominator: 50000,
      );
      expect(rule.appliesAtScale(75000), isFalse);
    });
  });
}
