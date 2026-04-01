import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:flutter_map_sld/src/validation/rules/expression_rules.dart';
import 'package:test/test.dart';

void main() {
  group('validateExpression — Categorize', () {
    test('valid: values.length == thresholds.length + 1', () {
      const expr = Categorize(
        lookupValue: PropertyName('x'),
        thresholds: [Literal(10), Literal(20)],
        values: [Literal('a'), Literal('b'), Literal('c')],
      );
      final issues = <SldValidationIssue>[];
      validateExpression(expr, issues, '/test');
      expect(issues, isEmpty);
    });

    test('invalid: values/thresholds mismatch', () {
      const expr = Categorize(
        lookupValue: PropertyName('x'),
        thresholds: [Literal(10)],
        values: [Literal('a')],
      );
      final issues = <SldValidationIssue>[];
      validateExpression(expr, issues, '/test');
      expect(issues, hasLength(1));
      expect(issues.first.code, 'categorize-values-thresholds-mismatch');
      expect(issues.first.severity, SldIssueSeverity.error);
    });
  });

  group('validateExpression — Interpolate', () {
    test('valid: 2+ sorted data points', () {
      const expr = Interpolate(
        lookupValue: PropertyName('x'),
        dataPoints: [
          InterpolationPoint(data: 0, value: Literal(0)),
          InterpolationPoint(data: 100, value: Literal(1)),
        ],
      );
      final issues = <SldValidationIssue>[];
      validateExpression(expr, issues, '/test');
      expect(issues, isEmpty);
    });

    test('warning: fewer than 2 data points', () {
      const expr = Interpolate(
        lookupValue: PropertyName('x'),
        dataPoints: [
          InterpolationPoint(data: 0, value: Literal(0)),
        ],
      );
      final issues = <SldValidationIssue>[];
      validateExpression(expr, issues, '/test');
      expect(issues, hasLength(1));
      expect(issues.first.code, 'interpolate-insufficient-points');
    });

    test('warning: unsorted data points', () {
      const expr = Interpolate(
        lookupValue: PropertyName('x'),
        dataPoints: [
          InterpolationPoint(data: 100, value: Literal(1)),
          InterpolationPoint(data: 0, value: Literal(0)),
        ],
      );
      final issues = <SldValidationIssue>[];
      validateExpression(expr, issues, '/test');
      expect(issues.any((i) => i.code == 'interpolate-unsorted-points'), isTrue);
    });
  });

  group('validateExpression — Recode', () {
    test('valid: unique input values', () {
      const expr = Recode(
        lookupValue: PropertyName('x'),
        mappings: [
          RecodeMapping(inputValue: Literal('A'), outputValue: Literal('1')),
          RecodeMapping(inputValue: Literal('B'), outputValue: Literal('2')),
        ],
      );
      final issues = <SldValidationIssue>[];
      validateExpression(expr, issues, '/test');
      expect(issues, isEmpty);
    });

    test('warning: duplicate input values', () {
      const expr = Recode(
        lookupValue: PropertyName('x'),
        mappings: [
          RecodeMapping(inputValue: Literal('A'), outputValue: Literal('1')),
          RecodeMapping(inputValue: Literal('A'), outputValue: Literal('2')),
        ],
      );
      final issues = <SldValidationIssue>[];
      validateExpression(expr, issues, '/test');
      expect(issues, hasLength(1));
      expect(issues.first.code, 'recode-duplicate-input');
    });
  });

  group('validateExpression — Concatenate (recursive)', () {
    test('recurses into child expressions', () {
      // Nested Categorize with invalid values/thresholds inside Concatenate.
      const expr = Concatenate(expressions: [
        Literal('prefix: '),
        Categorize(
          lookupValue: PropertyName('x'),
          thresholds: [Literal(10)],
          values: [Literal('a')], // invalid: should be 2 values
        ),
      ]);
      final issues = <SldValidationIssue>[];
      validateExpression(expr, issues, '/test');
      expect(issues, hasLength(1));
      expect(issues.first.code, 'categorize-values-thresholds-mismatch');
    });
  });

  group('validateExpression — FormatNumber (recursive)', () {
    test('recurses into numericValue', () {
      const expr = FormatNumber(
        numericValue: Categorize(
          lookupValue: PropertyName('x'),
          thresholds: [Literal(10)],
          values: [Literal(1)], // invalid
        ),
        pattern: '#.##',
      );
      final issues = <SldValidationIssue>[];
      validateExpression(expr, issues, '/test');
      expect(issues, hasLength(1));
    });
  });

  group('validateExpression — simple expressions', () {
    test('PropertyName produces no issues', () {
      const expr = PropertyName('x');
      final issues = <SldValidationIssue>[];
      validateExpression(expr, issues, '/test');
      expect(issues, isEmpty);
    });

    test('Literal produces no issues', () {
      const expr = Literal(42);
      final issues = <SldValidationIssue>[];
      validateExpression(expr, issues, '/test');
      expect(issues, isEmpty);
    });
  });
}
