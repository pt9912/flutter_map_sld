import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:test/test.dart';

void main() {
  // -----------------------------------------------------------------------
  // Expressions
  // -----------------------------------------------------------------------
  group('PropertyName', () {
    test('evaluates to property value', () {
      const expr = PropertyName('age');
      expect(expr.evaluate({'age': 25}), 25);
    });

    test('evaluates to null for missing property', () {
      const expr = PropertyName('missing');
      expect(expr.evaluate({'age': 25}), isNull);
    });

    test('equal instances are ==', () {
      const a = PropertyName('name');
      const b = PropertyName('name');
      expect(a, equals(b));
    });
  });

  group('Literal', () {
    test('evaluates to its value', () {
      const expr = Literal('hello');
      expect(expr.evaluate({}), 'hello');
    });

    test('numeric literal', () {
      const expr = Literal(42);
      expect(expr.evaluate({}), 42);
    });
  });

  // -----------------------------------------------------------------------
  // Composite expressions
  // -----------------------------------------------------------------------
  group('Concatenate', () {
    test('concatenates two strings', () {
      const expr = Concatenate(expressions: [
        Literal('hello'),
        Literal(' world'),
      ]);
      expect(expr.evaluate({}), 'hello world');
    });

    test('concatenates with PropertyName', () {
      const expr = Concatenate(expressions: [
        PropertyName('first'),
        Literal(' '),
        PropertyName('last'),
      ]);
      expect(expr.evaluate({'first': 'Max', 'last': 'Müller'}), 'Max Müller');
    });

    test('returns null when any child is null', () {
      const expr = Concatenate(expressions: [
        PropertyName('first'),
        Literal(' '),
        PropertyName('missing'),
      ]);
      expect(expr.evaluate({'first': 'Max'}), isNull);
    });

    test('empty expressions list returns empty string', () {
      const expr = Concatenate(expressions: []);
      expect(expr.evaluate({}), '');
    });

    test('equality and hashCode (non-const)', () {
      final a = Concatenate(expressions: [Literal('a'), Literal('b')]);
      final b = Concatenate(expressions: [Literal('a'), Literal('b')]);
      final c = Concatenate(expressions: [Literal('a'), Literal('c')]);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('FormatNumber', () {
    test('integer format', () {
      const expr = FormatNumber(
        numericValue: Literal(3.7),
        pattern: '#',
      );
      expect(expr.evaluate({}), '4');
    });

    test('two decimal places', () {
      const expr = FormatNumber(
        numericValue: Literal(3.14159),
        pattern: '#.##',
      );
      expect(expr.evaluate({}), '3.14');
    });

    test('zero decimal places with 0-pattern', () {
      const expr = FormatNumber(
        numericValue: Literal(42.567),
        pattern: '0.0',
      );
      expect(expr.evaluate({}), '42.6');
    });

    test('non-numeric value returns null', () {
      const expr = FormatNumber(
        numericValue: Literal('abc'),
        pattern: '#.##',
      );
      expect(expr.evaluate({}), isNull);
    });

    test('string-encoded number is parsed', () {
      const expr = FormatNumber(
        numericValue: PropertyName('pop'),
        pattern: '#.#',
      );
      expect(expr.evaluate({'pop': '123.456'}), '123.5');
    });

    test('equality and hashCode (non-const)', () {
      final a = FormatNumber(numericValue: Literal(1), pattern: '#');
      final b = FormatNumber(numericValue: Literal(1), pattern: '#');
      final c = FormatNumber(numericValue: Literal(2), pattern: '#');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('Categorize', () {
    test('below first threshold', () {
      const expr = Categorize(
        lookupValue: PropertyName('pop'),
        thresholds: [Literal(10000), Literal(100000)],
        values: [Literal('small'), Literal('medium'), Literal('large')],
      );
      expect(expr.evaluate({'pop': 500}), 'small');
    });

    test('between thresholds', () {
      const expr = Categorize(
        lookupValue: PropertyName('pop'),
        thresholds: [Literal(10000), Literal(100000)],
        values: [Literal('small'), Literal('medium'), Literal('large')],
      );
      expect(expr.evaluate({'pop': 50000}), 'medium');
    });

    test('above last threshold', () {
      const expr = Categorize(
        lookupValue: PropertyName('pop'),
        thresholds: [Literal(10000), Literal(100000)],
        values: [Literal('small'), Literal('medium'), Literal('large')],
      );
      expect(expr.evaluate({'pop': 200000}), 'large');
    });

    test('null lookup uses fallback', () {
      const expr = Categorize(
        lookupValue: PropertyName('missing'),
        thresholds: [Literal(10)],
        values: [Literal('lo'), Literal('hi')],
        fallbackValue: Literal('unknown'),
      );
      expect(expr.evaluate({}), 'unknown');
    });

    test('null lookup without fallback returns null', () {
      const expr = Categorize(
        lookupValue: PropertyName('missing'),
        thresholds: [Literal(10)],
        values: [Literal('lo'), Literal('hi')],
      );
      expect(expr.evaluate({}), isNull);
    });

    test('non-numeric threshold returns fallback', () {
      const expr = Categorize(
        lookupValue: PropertyName('x'),
        thresholds: [Literal('not-a-number')],
        values: [Literal('lo'), Literal('hi')],
        fallbackValue: Literal('err'),
      );
      expect(expr.evaluate({'x': 5}), 'err');
    });

    test('equality and hashCode (non-const)', () {
      final a = Categorize(
        lookupValue: PropertyName('x'),
        thresholds: [Literal(5)],
        values: [Literal('a'), Literal('b')],
      );
      final b = Categorize(
        lookupValue: PropertyName('x'),
        thresholds: [Literal(5)],
        values: [Literal('a'), Literal('b')],
      );
      final c = Categorize(
        lookupValue: PropertyName('x'),
        thresholds: [Literal(10)],
        values: [Literal('a'), Literal('b')],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('Interpolate', () {
    test('exact data point', () {
      const expr = Interpolate(
        lookupValue: PropertyName('elev'),
        dataPoints: [
          InterpolationPoint(data: 0, value: Literal(0.0)),
          InterpolationPoint(data: 100, value: Literal(1.0)),
        ],
      );
      expect(expr.evaluate({'elev': 0}), 0.0);
      expect(expr.evaluate({'elev': 100}), 1.0);
    });

    test('linear interpolation between points', () {
      const expr = Interpolate(
        lookupValue: PropertyName('elev'),
        dataPoints: [
          InterpolationPoint(data: 0, value: Literal(0.0)),
          InterpolationPoint(data: 100, value: Literal(1.0)),
        ],
      );
      expect(expr.evaluate({'elev': 50}), closeTo(0.5, 0.001));
    });

    test('below range returns first value', () {
      const expr = Interpolate(
        lookupValue: PropertyName('elev'),
        dataPoints: [
          InterpolationPoint(data: 0, value: Literal(10.0)),
          InterpolationPoint(data: 100, value: Literal(20.0)),
        ],
      );
      expect(expr.evaluate({'elev': -50}), 10.0);
    });

    test('above range returns last value', () {
      const expr = Interpolate(
        lookupValue: PropertyName('elev'),
        dataPoints: [
          InterpolationPoint(data: 0, value: Literal(10.0)),
          InterpolationPoint(data: 100, value: Literal(20.0)),
        ],
      );
      expect(expr.evaluate({'elev': 200}), 20.0);
    });

    test('null lookup uses fallback', () {
      const expr = Interpolate(
        lookupValue: PropertyName('missing'),
        dataPoints: [
          InterpolationPoint(data: 0, value: Literal(0.0)),
        ],
        fallbackValue: Literal(-1.0),
      );
      expect(expr.evaluate({}), -1.0);
    });

    test('non-numeric interpolation values use lower bound', () {
      const expr = Interpolate(
        lookupValue: PropertyName('x'),
        dataPoints: [
          InterpolationPoint(data: 0, value: Literal('low')),
          InterpolationPoint(data: 100, value: Literal('high')),
        ],
      );
      expect(expr.evaluate({'x': 50}), 'low');
    });

    test('equality and hashCode (non-const)', () {
      final a = Interpolate(
        lookupValue: PropertyName('x'),
        dataPoints: [InterpolationPoint(data: 0, value: Literal(0))],
      );
      final b = Interpolate(
        lookupValue: PropertyName('x'),
        dataPoints: [InterpolationPoint(data: 0, value: Literal(0))],
      );
      final c = Interpolate(
        lookupValue: PropertyName('x'),
        dataPoints: [InterpolationPoint(data: 1, value: Literal(0))],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('InterpolationPoint hashCode (non-const)', () {
      final a = InterpolationPoint(data: 5, value: Literal(10));
      final b = InterpolationPoint(data: 5, value: Literal(10));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('Recode', () {
    test('known key returns mapped value', () {
      const expr = Recode(
        lookupValue: PropertyName('code'),
        mappings: [
          RecodeMapping(inputValue: Literal('A'), outputValue: Literal('Alpha')),
          RecodeMapping(inputValue: Literal('B'), outputValue: Literal('Bravo')),
        ],
      );
      expect(expr.evaluate({'code': 'A'}), 'Alpha');
      expect(expr.evaluate({'code': 'B'}), 'Bravo');
    });

    test('unknown key returns fallback', () {
      const expr = Recode(
        lookupValue: PropertyName('code'),
        mappings: [
          RecodeMapping(inputValue: Literal('A'), outputValue: Literal('Alpha')),
        ],
        fallbackValue: Literal('unknown'),
      );
      expect(expr.evaluate({'code': 'Z'}), 'unknown');
    });

    test('unknown key without fallback returns null', () {
      const expr = Recode(
        lookupValue: PropertyName('code'),
        mappings: [
          RecodeMapping(inputValue: Literal('A'), outputValue: Literal('Alpha')),
        ],
      );
      expect(expr.evaluate({'code': 'Z'}), isNull);
    });

    test('null lookup returns fallback', () {
      const expr = Recode(
        lookupValue: PropertyName('missing'),
        mappings: [
          RecodeMapping(inputValue: Literal('A'), outputValue: Literal('Alpha')),
        ],
        fallbackValue: Literal('n/a'),
      );
      expect(expr.evaluate({}), 'n/a');
    });

    test('equality and hashCode (non-const)', () {
      final a = Recode(
        lookupValue: PropertyName('x'),
        mappings: [
          RecodeMapping(inputValue: Literal('A'), outputValue: Literal('1')),
        ],
      );
      final b = Recode(
        lookupValue: PropertyName('x'),
        mappings: [
          RecodeMapping(inputValue: Literal('A'), outputValue: Literal('1')),
        ],
      );
      final c = Recode(
        lookupValue: PropertyName('x'),
        mappings: [
          RecodeMapping(inputValue: Literal('B'), outputValue: Literal('1')),
        ],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('RecodeMapping hashCode (non-const)', () {
      final a = RecodeMapping(inputValue: Literal('A'), outputValue: Literal('1'));
      final b = RecodeMapping(inputValue: Literal('A'), outputValue: Literal('1'));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  // -----------------------------------------------------------------------
  // Comparison filters
  // -----------------------------------------------------------------------
  group('PropertyIsEqualTo', () {
    test('true when values are equal', () {
      const f = PropertyIsEqualTo(
        expression1: PropertyName('type'),
        expression2: Literal('city'),
      );
      expect(f.evaluate({'type': 'city'}), isTrue);
    });

    test('false when values differ', () {
      const f = PropertyIsEqualTo(
        expression1: PropertyName('type'),
        expression2: Literal('city'),
      );
      expect(f.evaluate({'type': 'town'}), isFalse);
    });

    test('false when property is null', () {
      const f = PropertyIsEqualTo(
        expression1: PropertyName('type'),
        expression2: Literal('city'),
      );
      expect(f.evaluate({}), isFalse);
    });
  });

  group('PropertyIsNotEqualTo', () {
    test('true when values differ', () {
      const f = PropertyIsNotEqualTo(
        expression1: PropertyName('type'),
        expression2: Literal('city'),
      );
      expect(f.evaluate({'type': 'town'}), isTrue);
    });

    test('false when values are equal', () {
      const f = PropertyIsNotEqualTo(
        expression1: PropertyName('type'),
        expression2: Literal('city'),
      );
      expect(f.evaluate({'type': 'city'}), isFalse);
    });
  });

  group('PropertyIsLessThan', () {
    test('numeric comparison', () {
      const f = PropertyIsLessThan(
        expression1: PropertyName('pop'),
        expression2: Literal(1000),
      );
      expect(f.evaluate({'pop': 500}), isTrue);
      expect(f.evaluate({'pop': 1000}), isFalse);
      expect(f.evaluate({'pop': 1500}), isFalse);
    });

    test('string comparison', () {
      const f = PropertyIsLessThan(
        expression1: PropertyName('name'),
        expression2: Literal('M'),
      );
      expect(f.evaluate({'name': 'Berlin'}), isTrue);
      expect(f.evaluate({'name': 'Zurich'}), isFalse);
    });

    test('incompatible types return false', () {
      const f = PropertyIsLessThan(
        expression1: PropertyName('name'),
        expression2: Literal(42),
      );
      expect(f.evaluate({'name': 'Berlin'}), isFalse);
    });
  });

  group('PropertyIsGreaterThan', () {
    test('numeric comparison', () {
      const f = PropertyIsGreaterThan(
        expression1: PropertyName('pop'),
        expression2: Literal(1000),
      );
      expect(f.evaluate({'pop': 1500}), isTrue);
      expect(f.evaluate({'pop': 1000}), isFalse);
    });
  });

  group('PropertyIsLessThanOrEqualTo', () {
    test('includes equal', () {
      const f = PropertyIsLessThanOrEqualTo(
        expression1: PropertyName('pop'),
        expression2: Literal(1000),
      );
      expect(f.evaluate({'pop': 1000}), isTrue);
      expect(f.evaluate({'pop': 999}), isTrue);
      expect(f.evaluate({'pop': 1001}), isFalse);
    });
  });

  group('PropertyIsGreaterThanOrEqualTo', () {
    test('includes equal', () {
      const f = PropertyIsGreaterThanOrEqualTo(
        expression1: PropertyName('pop'),
        expression2: Literal(1000),
      );
      expect(f.evaluate({'pop': 1000}), isTrue);
      expect(f.evaluate({'pop': 1001}), isTrue);
      expect(f.evaluate({'pop': 999}), isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // Between, Like, Null
  // -----------------------------------------------------------------------
  group('PropertyIsBetween', () {
    test('true when in range', () {
      const f = PropertyIsBetween(
        expression: PropertyName('temp'),
        lowerBoundary: Literal(10),
        upperBoundary: Literal(30),
      );
      expect(f.evaluate({'temp': 20}), isTrue);
      expect(f.evaluate({'temp': 10}), isTrue);
      expect(f.evaluate({'temp': 30}), isTrue);
    });

    test('false when out of range', () {
      const f = PropertyIsBetween(
        expression: PropertyName('temp'),
        lowerBoundary: Literal(10),
        upperBoundary: Literal(30),
      );
      expect(f.evaluate({'temp': 5}), isFalse);
      expect(f.evaluate({'temp': 35}), isFalse);
    });
  });

  group('PropertyIsLike', () {
    test('wildcard matching', () {
      const f = PropertyIsLike(
        expression: PropertyName('name'),
        pattern: 'Ber*',
      );
      expect(f.evaluate({'name': 'Berlin'}), isTrue);
      expect(f.evaluate({'name': 'Munich'}), isFalse);
    });

    test('single char matching', () {
      const f = PropertyIsLike(
        expression: PropertyName('code'),
        pattern: 'A?C',
      );
      expect(f.evaluate({'code': 'ABC'}), isTrue);
      expect(f.evaluate({'code': 'AXC'}), isTrue);
      expect(f.evaluate({'code': 'ABBC'}), isFalse);
    });

    test('false for non-string', () {
      const f = PropertyIsLike(
        expression: PropertyName('val'),
        pattern: '*',
      );
      expect(f.evaluate({'val': 42}), isFalse);
    });
  });

  group('PropertyIsNull', () {
    test('true when null', () {
      const f = PropertyIsNull(expression: PropertyName('x'));
      expect(f.evaluate({}), isTrue);
    });

    test('false when present', () {
      const f = PropertyIsNull(expression: PropertyName('x'));
      expect(f.evaluate({'x': 'value'}), isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // Logical operators
  // -----------------------------------------------------------------------
  group('And', () {
    test('true when all true', () {
      const f = And(filters: [
        PropertyIsEqualTo(
            expression1: PropertyName('a'), expression2: Literal(1)),
        PropertyIsEqualTo(
            expression1: PropertyName('b'), expression2: Literal(2)),
      ]);
      expect(f.evaluate({'a': 1, 'b': 2}), isTrue);
    });

    test('false when one false', () {
      const f = And(filters: [
        PropertyIsEqualTo(
            expression1: PropertyName('a'), expression2: Literal(1)),
        PropertyIsEqualTo(
            expression1: PropertyName('b'), expression2: Literal(2)),
      ]);
      expect(f.evaluate({'a': 1, 'b': 99}), isFalse);
    });
  });

  group('Or', () {
    test('true when any true', () {
      const f = Or(filters: [
        PropertyIsEqualTo(
            expression1: PropertyName('a'), expression2: Literal(1)),
        PropertyIsEqualTo(
            expression1: PropertyName('a'), expression2: Literal(2)),
      ]);
      expect(f.evaluate({'a': 2}), isTrue);
    });

    test('false when all false', () {
      const f = Or(filters: [
        PropertyIsEqualTo(
            expression1: PropertyName('a'), expression2: Literal(1)),
        PropertyIsEqualTo(
            expression1: PropertyName('a'), expression2: Literal(2)),
      ]);
      expect(f.evaluate({'a': 99}), isFalse);
    });
  });

  group('Not', () {
    test('negates inner filter', () {
      const f = Not(
        filter: PropertyIsEqualTo(
            expression1: PropertyName('a'), expression2: Literal(1)),
      );
      expect(f.evaluate({'a': 1}), isFalse);
      expect(f.evaluate({'a': 2}), isTrue);
    });
  });

  // -----------------------------------------------------------------------
  // Rule.appliesTo
  // -----------------------------------------------------------------------
  group('Rule.appliesTo', () {
    test('combines filter and scale', () {
      const rule = Rule(
        filter: PropertyIsEqualTo(
            expression1: PropertyName('type'),
            expression2: Literal('city')),
        minScaleDenominator: 1000,
        maxScaleDenominator: 50000,
      );

      expect(
          rule.appliesTo({'type': 'city'}, scaleDenominator: 10000), isTrue);
      expect(
          rule.appliesTo({'type': 'town'}, scaleDenominator: 10000), isFalse);
      expect(
          rule.appliesTo({'type': 'city'}, scaleDenominator: 100), isFalse);
    });

    test('no filter means all properties match', () {
      const rule = Rule();
      expect(rule.appliesTo({'anything': true}), isTrue);
    });
  });
}
