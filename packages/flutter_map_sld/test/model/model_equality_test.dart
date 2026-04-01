import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:test/test.dart';

void main() {
  // -----------------------------------------------------------------------
  // Filter equality
  // -----------------------------------------------------------------------
  group('Filter equality', () {
    test('PropertyIsEqualTo', () {
      const a = PropertyIsEqualTo(
          expression1: PropertyName('x'), expression2: Literal(1));
      const b = PropertyIsEqualTo(
          expression1: PropertyName('x'), expression2: Literal(1));
      const c = PropertyIsEqualTo(
          expression1: PropertyName('y'), expression2: Literal(1));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('PropertyIsNotEqualTo', () {
      const a = PropertyIsNotEqualTo(
          expression1: PropertyName('x'), expression2: Literal(1));
      const b = PropertyIsNotEqualTo(
          expression1: PropertyName('x'), expression2: Literal(1));
      const c = PropertyIsNotEqualTo(
          expression1: PropertyName('x'), expression2: Literal(2));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('PropertyIsLessThan', () {
      const a = PropertyIsLessThan(
          expression1: PropertyName('x'), expression2: Literal(1));
      const b = PropertyIsLessThan(
          expression1: PropertyName('x'), expression2: Literal(1));
      const c = PropertyIsLessThan(
          expression1: PropertyName('x'), expression2: Literal(2));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('PropertyIsGreaterThan (non-const)', () {
      final a = PropertyIsGreaterThan(
          expression1: PropertyName('x'), expression2: Literal(1));
      final b = PropertyIsGreaterThan(
          expression1: PropertyName('x'), expression2: Literal(1));
      final c = PropertyIsGreaterThan(
          expression1: PropertyName('y'), expression2: Literal(1));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('PropertyIsLessThanOrEqualTo (non-const)', () {
      final a = PropertyIsLessThanOrEqualTo(
          expression1: PropertyName('x'), expression2: Literal(1));
      final b = PropertyIsLessThanOrEqualTo(
          expression1: PropertyName('x'), expression2: Literal(1));
      final c = PropertyIsLessThanOrEqualTo(
          expression1: PropertyName('x'), expression2: Literal(2));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('PropertyIsGreaterThanOrEqualTo (non-const)', () {
      final a = PropertyIsGreaterThanOrEqualTo(
          expression1: PropertyName('x'), expression2: Literal(1));
      final b = PropertyIsGreaterThanOrEqualTo(
          expression1: PropertyName('x'), expression2: Literal(1));
      final c = PropertyIsGreaterThanOrEqualTo(
          expression1: PropertyName('y'), expression2: Literal(1));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('PropertyIsBetween', () {
      const a = PropertyIsBetween(
          expression: PropertyName('x'),
          lowerBoundary: Literal(0),
          upperBoundary: Literal(10));
      const b = PropertyIsBetween(
          expression: PropertyName('x'),
          lowerBoundary: Literal(0),
          upperBoundary: Literal(10));
      const c = PropertyIsBetween(
          expression: PropertyName('x'),
          lowerBoundary: Literal(0),
          upperBoundary: Literal(20));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('PropertyIsLike (non-const)', () {
      final a = PropertyIsLike(
          expression: PropertyName('name'),
          pattern: 'Ber*',
          wildCard: '*',
          singleChar: '?',
          escapeChar: '\\');
      final b = PropertyIsLike(
          expression: PropertyName('name'),
          pattern: 'Ber*',
          wildCard: '*',
          singleChar: '?',
          escapeChar: '\\');
      final c = PropertyIsLike(
          expression: PropertyName('name'), pattern: 'Mun*');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('PropertyIsNull', () {
      const a = PropertyIsNull(expression: PropertyName('x'));
      const b = PropertyIsNull(expression: PropertyName('x'));
      const c = PropertyIsNull(expression: PropertyName('y'));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('And', () {
      const a = And(filters: [
        PropertyIsEqualTo(
            expression1: PropertyName('a'), expression2: Literal(1)),
      ]);
      const b = And(filters: [
        PropertyIsEqualTo(
            expression1: PropertyName('a'), expression2: Literal(1)),
      ]);
      const c = And(filters: [
        PropertyIsEqualTo(
            expression1: PropertyName('a'), expression2: Literal(2)),
      ]);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('Or', () {
      const a = Or(filters: [
        PropertyIsEqualTo(
            expression1: PropertyName('a'), expression2: Literal(1)),
      ]);
      const b = Or(filters: [
        PropertyIsEqualTo(
            expression1: PropertyName('a'), expression2: Literal(1)),
      ]);
      const c = Or(filters: [
        PropertyIsEqualTo(
            expression1: PropertyName('b'), expression2: Literal(1)),
      ]);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('Not', () {
      const a = Not(
          filter: PropertyIsEqualTo(
              expression1: PropertyName('a'), expression2: Literal(1)));
      const b = Not(
          filter: PropertyIsEqualTo(
              expression1: PropertyName('a'), expression2: Literal(1)));
      const c = Not(
          filter: PropertyIsEqualTo(
              expression1: PropertyName('b'), expression2: Literal(1)));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  // -----------------------------------------------------------------------
  // Filter evaluate — exercise remaining paths
  // -----------------------------------------------------------------------
  group('Filter evaluate paths', () {
    test('PropertyIsLike with escape character', () {
      const f = PropertyIsLike(
        expression: PropertyName('val'),
        pattern: r'hello\*world',
        wildCard: '*',
        singleChar: '?',
        escapeChar: '\\',
      );
      expect(f.evaluate({'val': 'hello*world'}), isTrue);
      expect(f.evaluate({'val': 'helloXworld'}), isFalse);
    });

    test('PropertyIsLike hashCode', () {
      const a = PropertyIsLike(
          expression: PropertyName('x'), pattern: 'a*');
      expect(a.hashCode, isA<int>());
    });

    test('PropertyIsGreaterThanOrEqualTo evaluate and hashCode', () {
      const f = PropertyIsGreaterThanOrEqualTo(
          expression1: PropertyName('x'), expression2: Literal(5));
      expect(f.evaluate({'x': 5}), isTrue);
      expect(f.hashCode, isA<int>());
    });

    test('PropertyIsLessThanOrEqualTo hashCode', () {
      const f = PropertyIsLessThanOrEqualTo(
          expression1: PropertyName('x'), expression2: Literal(5));
      expect(f.hashCode, isA<int>());
    });
  });

  // -----------------------------------------------------------------------
  // Expression equality for PropertyName and Literal
  // -----------------------------------------------------------------------
  group('Expression equality', () {
    test('PropertyName inequality', () {
      const a = PropertyName('x');
      const b = PropertyName('y');
      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('Literal inequality', () {
      const a = Literal('hello');
      const b = Literal('world');
      expect(a, isNot(equals(b)));
    });
  });

  // -----------------------------------------------------------------------
  // Text symbolizer model equality
  // -----------------------------------------------------------------------
  // NOTE: Use `final` (not `const`) to avoid Dart canonicalization.
  // With `const`, `identical(a, b)` is true, short-circuiting `==`.
  group('TextSymbolizer equality', () {
    test('Font', () {
      final a = Font(family: 'Arial', style: 'normal', weight: 'bold', size: 12);
      final b = Font(family: 'Arial', style: 'normal', weight: 'bold', size: 12);
      final c = Font(family: 'Serif', style: 'normal', weight: 'bold', size: 12);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('PointPlacement', () {
      final a = PointPlacement(
          anchorPointX: 0.5,
          anchorPointY: 0.5,
          displacementX: 10,
          displacementY: 20,
          rotation: 45);
      final b = PointPlacement(
          anchorPointX: 0.5,
          anchorPointY: 0.5,
          displacementX: 10,
          displacementY: 20,
          rotation: 45);
      final c = PointPlacement(anchorPointX: 0.0);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('LabelPlacement', () {
      final a = LabelPlacement(
          pointPlacement: PointPlacement(anchorPointX: 0.5));
      final b = LabelPlacement(
          pointPlacement: PointPlacement(anchorPointX: 0.5));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('TextSymbolizer', () {
      final a = TextSymbolizer(
        label: PropertyName('name'),
        font: Font(family: 'Arial', size: 12),
        fill: Fill(colorArgb: 0xFF000000),
        halo: Halo(radius: 2.0),
        labelPlacement: LabelPlacement(
            pointPlacement: PointPlacement(anchorPointX: 0.5)),
      );
      final b = TextSymbolizer(
        label: PropertyName('name'),
        font: Font(family: 'Arial', size: 12),
        fill: Fill(colorArgb: 0xFF000000),
        halo: Halo(radius: 2.0),
        labelPlacement: LabelPlacement(
            pointPlacement: PointPlacement(anchorPointX: 0.5)),
      );
      final c = TextSymbolizer(label: PropertyName('other'));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  // -----------------------------------------------------------------------
  // Rule equality
  // -----------------------------------------------------------------------
  group('Rule equality', () {
    test('equal rules (non-const to exercise full == path)', () {
      final a = Rule(
        name: 'test',
        minScaleDenominator: 1000,
        maxScaleDenominator: 50000,
        filter: PropertyIsEqualTo(
            expression1: PropertyName('x'), expression2: Literal(1)),
        rasterSymbolizer: RasterSymbolizer(opacity: 0.8),
        pointSymbolizer: PointSymbolizer(
            graphic: Graphic(mark: Mark(wellKnownName: 'circle'), size: 6)),
        lineSymbolizer: LineSymbolizer(stroke: Stroke(width: 1.0)),
        polygonSymbolizer: PolygonSymbolizer(fill: Fill(colorArgb: 0xFFAAAAAA)),
        textSymbolizer: TextSymbolizer(label: PropertyName('name')),
      );
      final b = Rule(
        name: 'test',
        minScaleDenominator: 1000,
        maxScaleDenominator: 50000,
        filter: PropertyIsEqualTo(
            expression1: PropertyName('x'), expression2: Literal(1)),
        rasterSymbolizer: RasterSymbolizer(opacity: 0.8),
        pointSymbolizer: PointSymbolizer(
            graphic: Graphic(mark: Mark(wellKnownName: 'circle'), size: 6)),
        lineSymbolizer: LineSymbolizer(stroke: Stroke(width: 1.0)),
        polygonSymbolizer: PolygonSymbolizer(fill: Fill(colorArgb: 0xFFAAAAAA)),
        textSymbolizer: TextSymbolizer(label: PropertyName('name')),
      );
      final c = Rule(name: 'other');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  // -----------------------------------------------------------------------
  // Graphic model equality
  // -----------------------------------------------------------------------
  group('Graphic equality', () {
    test('Mark (non-const)', () {
      final a = Mark(
          wellKnownName: 'circle',
          fill: Fill(colorArgb: 0xFFFF0000),
          stroke: Stroke(colorArgb: 0xFF000000));
      final b = Mark(
          wellKnownName: 'circle',
          fill: Fill(colorArgb: 0xFFFF0000),
          stroke: Stroke(colorArgb: 0xFF000000));
      final c = Mark(wellKnownName: 'square');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('ExternalGraphic (non-const)', () {
      final a = ExternalGraphic(
          onlineResource: 'http://test/icon.png', format: 'image/png');
      final b = ExternalGraphic(
          onlineResource: 'http://test/icon.png', format: 'image/png');
      final c = ExternalGraphic(onlineResource: 'http://other/icon.png');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('Graphic (non-const)', () {
      final a = Graphic(
          mark: Mark(wellKnownName: 'circle'),
          externalGraphic: ExternalGraphic(onlineResource: 'http://x/y.png'),
          size: 10,
          rotation: 45,
          opacity: 0.8);
      final b = Graphic(
          mark: Mark(wellKnownName: 'circle'),
          externalGraphic: ExternalGraphic(onlineResource: 'http://x/y.png'),
          size: 10,
          rotation: 45,
          opacity: 0.8);
      final c = Graphic(
          mark: Mark(wellKnownName: 'square'), size: 10);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  // -----------------------------------------------------------------------
  // Style / Layer equality
  // -----------------------------------------------------------------------
  group('Style equality', () {
    test('FeatureTypeStyle', () {
      final a = FeatureTypeStyle(rules: const [Rule(name: 'r1')]);
      final b = FeatureTypeStyle(rules: const [Rule(name: 'r1')]);
      final c = FeatureTypeStyle(rules: const [Rule(name: 'r2')]);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('UserStyle', () {
      final a = UserStyle(
          name: 'style1',
          featureTypeStyles: [FeatureTypeStyle(rules: const [Rule()])]);
      final b = UserStyle(
          name: 'style1',
          featureTypeStyles: [FeatureTypeStyle(rules: const [Rule()])]);
      final c = UserStyle(name: 'style2', featureTypeStyles: []);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('SldLayer', () {
      final a = SldLayer(name: 'layer1', styles: [
        UserStyle(featureTypeStyles: [])
      ]);
      final b = SldLayer(name: 'layer1', styles: [
        UserStyle(featureTypeStyles: [])
      ]);
      final c = SldLayer(name: 'layer2', styles: []);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  // -----------------------------------------------------------------------
  // Symbolizer equality
  // -----------------------------------------------------------------------
  group('Symbolizer equality', () {
    test('Fill inequality', () {
      const a = Fill(colorArgb: 0xFFFF0000, opacity: 0.5);
      const b = Fill(colorArgb: 0xFF00FF00, opacity: 0.5);
      expect(a, isNot(equals(b)));
    });

    test('Stroke with dashArray', () {
      const a = Stroke(dashArray: [5.0, 3.0], lineCap: 'round', lineJoin: 'bevel');
      const b = Stroke(dashArray: [5.0, 3.0], lineCap: 'round', lineJoin: 'bevel');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('LineSymbolizer', () {
      const a = LineSymbolizer(stroke: Stroke(width: 2.0));
      const b = LineSymbolizer(stroke: Stroke(width: 2.0));
      const c = LineSymbolizer(stroke: Stroke(width: 3.0));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('PolygonSymbolizer', () {
      const a = PolygonSymbolizer(
          fill: Fill(colorArgb: 0xFFAAAAAA),
          stroke: Stroke(width: 1.0));
      const b = PolygonSymbolizer(
          fill: Fill(colorArgb: 0xFFAAAAAA),
          stroke: Stroke(width: 1.0));
      const c = PolygonSymbolizer(fill: Fill(colorArgb: 0xFFBBBBBB));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('PointSymbolizer', () {
      const a = PointSymbolizer(
          graphic: Graphic(mark: Mark(wellKnownName: 'circle')));
      const b = PointSymbolizer(
          graphic: Graphic(mark: Mark(wellKnownName: 'circle')));
      const c = PointSymbolizer(
          graphic: Graphic(mark: Mark(wellKnownName: 'square')));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  // -----------------------------------------------------------------------
  // Channel selection equality
  // -----------------------------------------------------------------------
  group('ChannelSelection equality', () {
    test('ChannelSelection', () {
      const a = ChannelSelection(
        redChannel: SelectedChannel(channelName: '1'),
        greenChannel: SelectedChannel(channelName: '2'),
        blueChannel: SelectedChannel(channelName: '3'),
      );
      const b = ChannelSelection(
        redChannel: SelectedChannel(channelName: '1'),
        greenChannel: SelectedChannel(channelName: '2'),
        blueChannel: SelectedChannel(channelName: '3'),
      );
      const c = ChannelSelection(
          grayChannel: SelectedChannel(channelName: '1'));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  // -----------------------------------------------------------------------
  // Contrast enhancement equality
  // -----------------------------------------------------------------------
  group('ContrastEnhancement equality', () {
    test('equal instances', () {
      const a = ContrastEnhancement(
          method: ContrastMethod.normalize, gammaValue: 1.5);
      const b = ContrastEnhancement(
          method: ContrastMethod.normalize, gammaValue: 1.5);
      const c = ContrastEnhancement(
          method: ContrastMethod.histogram, gammaValue: 1.5);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  // -----------------------------------------------------------------------
  // ColorMap equality (missing hashCode path)
  // -----------------------------------------------------------------------
  group('ColorMap equality', () {
    test('equal ColorMapEntry instances', () {
      const a = ColorMapEntry(
          colorArgb: 0xFF000000, quantity: 0, opacity: 1.0, label: 'lo');
      const b = ColorMapEntry(
          colorArgb: 0xFF000000, quantity: 0, opacity: 1.0, label: 'lo');
      const c = ColorMapEntry(
          colorArgb: 0xFFFFFFFF, quantity: 0, opacity: 1.0, label: 'hi');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  // -----------------------------------------------------------------------
  // Stroke edge cases
  // -----------------------------------------------------------------------
  group('Stroke edge cases', () {
    test('dashArray null vs non-null', () {
      const a = Stroke(dashArray: [5.0]);
      const b = Stroke(dashArray: null);
      expect(a, isNot(equals(b)));
      // Exercise hashCode for both paths.
      expect(a.hashCode, isA<int>());
      expect(b.hashCode, isA<int>());
    });

    test('dashArray different lengths', () {
      const a = Stroke(dashArray: [5.0, 3.0]);
      const b = Stroke(dashArray: [5.0]);
      expect(a, isNot(equals(b)));
    });
  });

  // -----------------------------------------------------------------------
  // ColorScaleStop equality
  // -----------------------------------------------------------------------
  group('ColorScaleStop equality', () {
    test('equal instances', () {
      const a = ColorScaleStop(colorArgb: 0xFF000000, quantity: 100.0);
      const b = ColorScaleStop(colorArgb: 0xFF000000, quantity: 100.0);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  // -----------------------------------------------------------------------
  // Issue equality
  // -----------------------------------------------------------------------
  group('SldIssue equality', () {
    test('SldParseIssue', () {
      const a = SldParseIssue(
          severity: SldIssueSeverity.error,
          code: 'test',
          message: 'msg',
          location: '/loc');
      const b = SldParseIssue(
          severity: SldIssueSeverity.error,
          code: 'test',
          message: 'msg',
          location: '/loc');
      const c = SldParseIssue(
          severity: SldIssueSeverity.warning,
          code: 'test',
          message: 'msg');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('SldValidationIssue differs from SldParseIssue', () {
      const parse = SldParseIssue(
          severity: SldIssueSeverity.error, code: 'x', message: 'm');
      const validation = SldValidationIssue(
          severity: SldIssueSeverity.error, code: 'x', message: 'm');
      expect(parse, isNot(equals(validation)));
    });
  });
}
