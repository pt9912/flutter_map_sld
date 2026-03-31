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
