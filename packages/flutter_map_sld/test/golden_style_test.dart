import 'dart:io';

import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:test/test.dart';

/// Reads a fixture file relative to the test directory.
String _fixture(String name) =>
    File('test/fixtures/$name').readAsStringSync();

/// Parses a fixture and asserts no errors.
SldDocument _parseFixture(String name) {
  final result = SldDocument.parseXmlString(_fixture(name));
  expect(result.hasErrors, isFalse, reason: 'Fixture $name has parse errors: '
      '${result.issues.map((i) => i.message).join(', ')}');
  expect(result.document, isNotNull, reason: 'Fixture $name has null document');
  return result.document!;
}

void main() {
  // -----------------------------------------------------------------------
  // 1. Two-Color Gradient
  // -----------------------------------------------------------------------
  group('Two-Color Gradient', () {
    late SldDocument doc;
    setUp(() => doc = _parseFixture('two_color_gradient.sld'));

    test('parses without errors', () {
      expect(doc.version, '1.0.0');
      expect(doc.layers, hasLength(1));
      expect(doc.layers.first.name, 'gtopo');
    });

    test('has one raster symbolizer with 2-entry ramp', () {
      final rs = doc.selectRasterSymbolizers();
      expect(rs, hasLength(1));

      final cm = rs.first.colorMap!;
      expect(cm.type, ColorMapType.ramp);
      expect(cm.entries, hasLength(2));

      expect(cm.entries[0].colorArgb, 0xFF000000);
      expect(cm.entries[0].quantity, 70.0);
      expect(cm.entries[0].opacity, 1.0);

      expect(cm.entries[1].colorArgb, 0xFFFFFFFF);
      expect(cm.entries[1].quantity, 256.0);
    });
  });

  // -----------------------------------------------------------------------
  // 2. Transparent Gradient
  // -----------------------------------------------------------------------
  group('Transparent Gradient', () {
    late SldDocument doc;
    setUp(() => doc = _parseFixture('transparent_gradient.sld'));

    test('has opacity on symbolizer and on entries', () {
      final rs = doc.selectRasterSymbolizers().first;
      expect(rs.opacity, 1.0);

      final cm = rs.colorMap!;
      expect(cm.entries[0].opacity, 0.0);
      expect(cm.entries[1].opacity, 1.0);
    });

    test('colors are black to white', () {
      final cm = doc.selectRasterSymbolizers().first.colorMap!;
      expect(cm.entries[0].colorArgb, 0xFF000000);
      expect(cm.entries[1].colorArgb, 0xFFFFFFFF);
    });
  });

  // -----------------------------------------------------------------------
  // 3. Brightness and Contrast
  // -----------------------------------------------------------------------
  group('Brightness and Contrast', () {
    late SldDocument doc;
    setUp(() => doc = _parseFixture('brightness_and_contrast.sld'));

    test('has contrast enhancement with normalize and gamma', () {
      final rs = doc.selectRasterSymbolizers().first;
      expect(rs.contrastEnhancement, isNotNull);
      expect(rs.contrastEnhancement!.method, ContrastMethod.normalize);
      expect(rs.contrastEnhancement!.gammaValue, 0.5);
    });

    test('has 2-entry color map', () {
      final cm = doc.selectRasterSymbolizers().first.colorMap!;
      expect(cm.entries, hasLength(2));
    });
  });

  // -----------------------------------------------------------------------
  // 4. Three-Color Gradient
  // -----------------------------------------------------------------------
  group('Three-Color Gradient', () {
    late SldDocument doc;
    setUp(() => doc = _parseFixture('three_color_gradient.sld'));

    test('has 3 entries: blue, yellow, red', () {
      final cm = doc.selectRasterSymbolizers().first.colorMap!;
      expect(cm.entries, hasLength(3));

      expect(cm.entries[0].colorArgb, 0xFF0000FF); // blue
      expect(cm.entries[0].quantity, 70.0);

      expect(cm.entries[1].colorArgb, 0xFFFFFF00); // yellow
      expect(cm.entries[1].quantity, 170.0);

      expect(cm.entries[2].colorArgb, 0xFFFF0000); // red
      expect(cm.entries[2].quantity, 256.0);
    });
  });

  // -----------------------------------------------------------------------
  // 5. Alpha Channel
  // -----------------------------------------------------------------------
  group('Alpha Channel', () {
    late SldDocument doc;
    setUp(() => doc = _parseFixture('alpha_channel.sld'));

    test('same color with varying opacity', () {
      final cm = doc.selectRasterSymbolizers().first.colorMap!;
      expect(cm.entries, hasLength(2));

      // Both entries have the same color (#008000 = dark green).
      expect(cm.entries[0].colorArgb, 0xFF008000);
      expect(cm.entries[1].colorArgb, 0xFF008000);

      // Opacity varies from 0 to 1.
      expect(cm.entries[0].opacity, 0.0);
      expect(cm.entries[1].opacity, 1.0);
    });
  });

  // -----------------------------------------------------------------------
  // 6. Discrete Colors (intervals)
  // -----------------------------------------------------------------------
  group('Discrete Colors', () {
    late SldDocument doc;
    setUp(() => doc = _parseFixture('discrete_colors.sld'));

    test('uses intervals type', () {
      final cm = doc.selectRasterSymbolizers().first.colorMap!;
      expect(cm.type, ColorMapType.intervals);
    });

    test('has labeled entries', () {
      final cm = doc.selectRasterSymbolizers().first.colorMap!;
      expect(cm.entries, hasLength(2));

      expect(cm.entries[0].label, 'Low');
      expect(cm.entries[0].colorArgb, 0xFF008000);
      expect(cm.entries[0].quantity, 150.0);

      expect(cm.entries[1].label, 'High');
      expect(cm.entries[1].colorArgb, 0xFF663333);
      expect(cm.entries[1].quantity, 256.0);
    });
  });

  // -----------------------------------------------------------------------
  // 7. Many Color Gradient
  // -----------------------------------------------------------------------
  group('Many Color Gradient', () {
    late SldDocument doc;
    setUp(() => doc = _parseFixture('many_color_gradient.sld'));

    test('has 8 entries', () {
      final cm = doc.selectRasterSymbolizers().first.colorMap!;
      expect(cm.type, ColorMapType.ramp);
      expect(cm.entries, hasLength(8));
    });

    test('quantities are ascending', () {
      final cm = doc.selectRasterSymbolizers().first.colorMap!;
      for (var i = 1; i < cm.entries.length; i++) {
        expect(cm.entries[i].quantity, greaterThan(cm.entries[i - 1].quantity));
      }
    });

    test('first is black, last is white', () {
      final cm = doc.selectRasterSymbolizers().first.colorMap!;
      expect(cm.entries.first.colorArgb, 0xFF000000);
      expect(cm.entries.last.colorArgb, 0xFFFFFFFF);
    });
  });

  // -----------------------------------------------------------------------
  // 8. SLD 1.0 Namespace-Variante (sld:-Präfix)
  // -----------------------------------------------------------------------
  group('SLD 1.0 sld-prefixed', () {
    late SldDocument doc;
    setUp(() => doc = _parseFixture('sld10_prefixed.sld'));

    test('parses without errors', () {
      expect(doc.version, '1.0.0');
      expect(doc.layers.first.name, 'gtopo');
    });

    test('has opacity and 3 labeled entries', () {
      final rs = doc.selectRasterSymbolizers().first;
      expect(rs.opacity, 0.8);

      final cm = rs.colorMap!;
      expect(cm.entries, hasLength(3));
      expect(cm.entries[0].label, 'Low');
      expect(cm.entries[1].label, 'Mid');
      expect(cm.entries[2].label, 'High');
    });
  });

  // -----------------------------------------------------------------------
  // 9. SE/SLD 1.1 Namespace-Variante (se:-Präfix)
  // -----------------------------------------------------------------------
  group('SE/SLD 1.1 se-prefixed', () {
    late SldDocument doc;
    setUp(() => doc = _parseFixture('se11_prefixed.sld'));

    test('parses version 1.1.0', () {
      expect(doc.version, '1.1.0');
      expect(doc.layers.first.name, 'gtopo');
    });

    test('has intervals color map with histogram enhancement', () {
      final rs = doc.selectRasterSymbolizers().first;
      expect(rs.opacity, 0.9);

      final cm = rs.colorMap!;
      expect(cm.type, ColorMapType.intervals);
      expect(cm.entries, hasLength(3));
      expect(cm.entries[0].quantity, 100.0);
      expect(cm.entries[1].quantity, 200.0);
      expect(cm.entries[2].quantity, 300.0);

      expect(rs.contrastEnhancement!.method, ContrastMethod.histogram);
      expect(rs.contrastEnhancement!.gammaValue, 1.2);
    });
  });

  // -----------------------------------------------------------------------
  // 10. Scale-Dependent Rules
  // -----------------------------------------------------------------------
  group('Scale-Dependent Rules', () {
    late SldDocument doc;
    setUp(() => doc = _parseFixture('scale_dependent_rules.sld'));

    test('parses without errors', () {
      expect(doc.version, '1.0.0');
      expect(doc.layers, hasLength(1));
      expect(doc.layers.first.name, 'dem');
    });

    test('has two rules with scale denominators', () {
      final rules =
          doc.layers.first.styles.first.featureTypeStyles.first.rules;
      expect(rules, hasLength(2));

      expect(rules[0].name, 'overview');
      expect(rules[0].minScaleDenominator, isNull);
      expect(rules[0].maxScaleDenominator, 500000);

      expect(rules[1].name, 'detail');
      expect(rules[1].minScaleDenominator, 500000);
      expect(rules[1].maxScaleDenominator, isNull);
    });

    test('selectRasterSymbolizersAtScale returns overview at small scale', () {
      final rs = doc.selectRasterSymbolizersAtScale(10000);
      expect(rs, hasLength(1));
      expect(rs.first.colorMap!.entries, hasLength(2));
    });

    test('selectRasterSymbolizersAtScale returns detail at large scale', () {
      final rs = doc.selectRasterSymbolizersAtScale(1000000);
      expect(rs, hasLength(1));
      expect(rs.first.colorMap!.entries, hasLength(3));
    });

    test('at boundary 500000 only detail matches', () {
      final rs = doc.selectRasterSymbolizersAtScale(500000);
      expect(rs, hasLength(1));
      // 500000 is exclusive upper for overview, inclusive lower for detail
      expect(rs.first.colorMap!.entries, hasLength(3));
    });

    test('validates without errors', () {
      final result = const SldValidator().validate(doc);
      expect(result.hasErrors, isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // 11. Multi-Band RGB with ChannelSelection
  // -----------------------------------------------------------------------
  group('Multi-Band RGB', () {
    late SldDocument doc;
    setUp(() => doc = _parseFixture('multiband_rgb.sld'));

    test('parses without errors', () {
      expect(doc.version, '1.0.0');
      expect(doc.layers.first.name, 'satellite');
    });

    test('has RGB channel selection', () {
      final rs = doc.selectRasterSymbolizers().first;
      final cs = rs.channelSelection!;

      expect(cs.redChannel!.channelName, '1');
      expect(cs.greenChannel!.channelName, '2');
      expect(cs.blueChannel!.channelName, '3');
      expect(cs.grayChannel, isNull);
    });

    test('red channel has per-channel contrast enhancement', () {
      final rs = doc.selectRasterSymbolizers().first;
      final red = rs.channelSelection!.redChannel!;

      expect(red.contrastEnhancement!.method, ContrastMethod.normalize);
      expect(red.contrastEnhancement!.gammaValue, 1.2);
    });

    test('has overall histogram contrast enhancement', () {
      final rs = doc.selectRasterSymbolizers().first;
      expect(rs.contrastEnhancement!.method, ContrastMethod.histogram);
    });

    test('validates without errors', () {
      final result = const SldValidator().validate(doc);
      expect(result.hasErrors, isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // 12. Shaded Relief
  // -----------------------------------------------------------------------
  group('Shaded Relief', () {
    late SldDocument doc;
    setUp(() => doc = _parseFixture('shaded_relief.sld'));

    test('parses without errors', () {
      expect(doc.version, '1.0.0');
      expect(doc.layers.first.name, 'terrain');
    });

    test('has shaded relief parameters', () {
      final rs = doc.selectRasterSymbolizers().first;
      expect(rs.shadedRelief, isNotNull);
      expect(rs.shadedRelief!.brightnessOnly, isFalse);
      expect(rs.shadedRelief!.reliefFactor, 55.0);
    });

    test('has color map alongside shaded relief', () {
      final rs = doc.selectRasterSymbolizers().first;
      expect(rs.colorMap!.entries, hasLength(3));
    });

    test('validates without errors', () {
      final result = const SldValidator().validate(doc);
      expect(result.hasErrors, isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // 13. Vendor Extensions
  // -----------------------------------------------------------------------
  group('Vendor Extensions', () {
    late SldParseResult result;
    late SldDocument doc;
    setUp(() {
      result = SldDocument.parseXmlString(_fixture('vendor_extensions.sld'));
      doc = result.document!;
    });

    test('parses without errors', () {
      expect(result.hasErrors, isFalse);
    });

    test('parses VendorOption elements into typed model', () {
      final rs = doc.selectRasterSymbolizers().first;
      expect(rs.vendorOptions, hasLength(2));

      expect(rs.vendorOptions[0].name, 'renderingMode');
      expect(rs.vendorOptions[0].value, 'quality');

      expect(rs.vendorOptions[1].name, 'customParam');
      expect(rs.vendorOptions[1].value, '42');
    });

    test('VendorOptions are not in extensions', () {
      final rs = doc.selectRasterSymbolizers().first;
      expect(rs.extensions, isEmpty);
    });

    test('no unknown-element issues for VendorOption', () {
      final unknownIssues =
          result.issues.where((i) => i.code == 'unknown-element').toList();
      expect(unknownIssues, isEmpty);
    });

    test('color map is still parsed correctly', () {
      final cm = doc.selectRasterSymbolizers().first.colorMap!;
      expect(cm.entries, hasLength(2));
    });
  });
}
