import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:test/test.dart';

void main() {
  group('SldIssueSeverity', () {
    test('has three values', () {
      expect(SldIssueSeverity.values, hasLength(3));
    });
  });

  group('SldParseIssue', () {
    test('can be constructed with all fields', () {
      const issue = SldParseIssue(
        severity: SldIssueSeverity.error,
        code: 'invalid-xml',
        message: 'XML is not well-formed',
        location: '/StyledLayerDescriptor',
      );

      expect(issue.severity, SldIssueSeverity.error);
      expect(issue.code, 'invalid-xml');
      expect(issue.message, 'XML is not well-formed');
      expect(issue.location, '/StyledLayerDescriptor');
    });

    test('location defaults to null', () {
      const issue = SldParseIssue(
        severity: SldIssueSeverity.warning,
        code: 'missing-namespace',
        message: 'No namespace found',
      );

      expect(issue.location, isNull);
    });

    test('is an SldIssue', () {
      const SldIssue issue = SldParseIssue(
        severity: SldIssueSeverity.info,
        code: 'test',
        message: 'test',
      );

      expect(issue, isA<SldParseIssue>());
    });
  });

  group('SldValidationIssue', () {
    test('can be constructed', () {
      const issue = SldValidationIssue(
        severity: SldIssueSeverity.error,
        code: 'invalid-opacity',
        message: 'Opacity must be between 0.0 and 1.0',
        location: 'layers[0].styles[0].featureTypeStyles[0].rules[0]'
            '.rasterSymbolizer.opacity',
      );

      expect(issue.severity, SldIssueSeverity.error);
      expect(issue.code, 'invalid-opacity');
      expect(issue.location, contains('rasterSymbolizer.opacity'));
    });
  });

  group('sealed SldIssue', () {
    test('supports exhaustive switch', () {
      const SldIssue issue = SldParseIssue(
        severity: SldIssueSeverity.error,
        code: 'test',
        message: 'test',
      );

      final result = switch (issue) {
        SldParseIssue() => 'parse',
        SldValidationIssue() => 'validation',
      };

      expect(result, 'parse');
    });
  });

  group('SldIssue equality', () {
    test('equal SldParseIssues are ==', () {
      const a = SldParseIssue(
        severity: SldIssueSeverity.error,
        code: 'x',
        message: 'm',
        location: '/root',
      );
      const b = SldParseIssue(
        severity: SldIssueSeverity.error,
        code: 'x',
        message: 'm',
        location: '/root',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different fields are not ==', () {
      const a = SldParseIssue(
        severity: SldIssueSeverity.error,
        code: 'x',
        message: 'm',
      );
      const b = SldParseIssue(
        severity: SldIssueSeverity.warning,
        code: 'x',
        message: 'm',
      );

      expect(a, isNot(equals(b)));
    });

    test('SldParseIssue != SldValidationIssue with same fields', () {
      const parse = SldParseIssue(
        severity: SldIssueSeverity.error,
        code: 'x',
        message: 'm',
      );
      const validation = SldValidationIssue(
        severity: SldIssueSeverity.error,
        code: 'x',
        message: 'm',
      );

      expect(parse, isNot(equals(validation)));
    });
  });
}
