import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:test/test.dart';

void main() {
  group('RasterSymbolizer', () {
    test('can be constructed with all fields', () {
      final rs = RasterSymbolizer(
        opacity: 0.75,
        colorMap: ColorMap(
          type: ColorMapType.ramp,
          entries: [],
        ),
        contrastEnhancement: const ContrastEnhancement(
          method: ContrastMethod.normalize,
          gammaValue: 1.5,
        ),
      );

      expect(rs.opacity, 0.75);
      expect(rs.colorMap, isNotNull);
      expect(rs.contrastEnhancement?.method, ContrastMethod.normalize);
      expect(rs.contrastEnhancement?.gammaValue, 1.5);
    });

    test('all fields default to null/empty', () {
      final rs = RasterSymbolizer();

      expect(rs.opacity, isNull);
      expect(rs.colorMap, isNull);
      expect(rs.contrastEnhancement, isNull);
      expect(rs.extensions, isEmpty);
    });

    test('extensions list is unmodifiable', () {
      final rs = RasterSymbolizer(
        extensions: [
          ExtensionNode(
            namespaceUri: 'http://geoserver.org',
            localName: 'VendorOption',
          ),
        ],
      );

      expect(
        () => rs.extensions.add(
          ExtensionNode(namespaceUri: '', localName: 'x'),
        ),
        throwsUnsupportedError,
      );
    });

    test('equal RasterSymbolizers are ==', () {
      final a = RasterSymbolizer(
        opacity: 0.5,
        contrastEnhancement: const ContrastEnhancement(
          method: ContrastMethod.histogram,
        ),
      );
      final b = RasterSymbolizer(
        opacity: 0.5,
        contrastEnhancement: const ContrastEnhancement(
          method: ContrastMethod.histogram,
        ),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('ContrastEnhancement', () {
    test('all fields default to null', () {
      const ce = ContrastEnhancement();

      expect(ce.method, isNull);
      expect(ce.gammaValue, isNull);
    });

    test('equal instances are ==', () {
      const a = ContrastEnhancement(
        method: ContrastMethod.normalize,
        gammaValue: 2.0,
      );
      const b = ContrastEnhancement(
        method: ContrastMethod.normalize,
        gammaValue: 2.0,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('ExtensionNode', () {
    test('can represent a nested vendor subtree', () {
      final node = ExtensionNode(
        namespaceUri: 'http://vendor.example',
        localName: 'CustomEffect',
        rawXml: '<v:CustomEffect><v:Param>1</v:Param></v:CustomEffect>',
        children: [
          ExtensionNode(
            namespaceUri: 'http://vendor.example',
            localName: 'Param',
            text: '1',
          ),
        ],
      );

      expect(node.children, hasLength(1));
      expect(node.rawXml, contains('CustomEffect'));
      expect(node.children.first.text, '1');
    });

    test('defaults are safe', () {
      final node = ExtensionNode(
        namespaceUri: '',
        localName: 'Unknown',
      );

      expect(node.attributes, isEmpty);
      expect(node.text, isNull);
      expect(node.rawXml, isEmpty);
      expect(node.children, isEmpty);
    });

    test('attributes map is unmodifiable', () {
      final node = ExtensionNode(
        namespaceUri: '',
        localName: 'X',
        attributes: {'key': 'value'},
      );

      expect(
        () => node.attributes['new'] = 'val',
        throwsUnsupportedError,
      );
    });

    test('children list is unmodifiable', () {
      final node = ExtensionNode(
        namespaceUri: '',
        localName: 'X',
      );

      expect(
        () => node.children.add(
          ExtensionNode(namespaceUri: '', localName: 'Y'),
        ),
        throwsUnsupportedError,
      );
    });

    test('mutation of source map does not affect ExtensionNode', () {
      final source = {'key': 'value'};
      final node = ExtensionNode(
        namespaceUri: '',
        localName: 'X',
        attributes: source,
      );

      source['new'] = 'val';

      expect(node.attributes, hasLength(1));
      expect(node.attributes.containsKey('new'), isFalse);
    });

    test('equal nodes are ==', () {
      final a = ExtensionNode(
        namespaceUri: 'http://example.com',
        localName: 'Foo',
        attributes: {'k': 'v'},
        text: 'bar',
      );
      final b = ExtensionNode(
        namespaceUri: 'http://example.com',
        localName: 'Foo',
        attributes: {'k': 'v'},
        text: 'bar',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
