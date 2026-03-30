import 'package:flutter_map_sld/src/parser/xml_helpers.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

/// Parses a fragment and returns the root element.
XmlElement _parse(String xml) => XmlDocument.parse(xml).rootElement;

void main() {
  // -----------------------------------------------------------------------
  // findChild
  // -----------------------------------------------------------------------
  group('findChild', () {
    test('finds unprefixed child', () {
      final root = _parse('<Root><Name>test</Name></Root>');
      final child = findChild(root, 'Name');

      expect(child, isNotNull);
      expect(child!.innerText, 'test');
    });

    test('finds sld-prefixed child', () {
      final root = _parse(
        '<sld:Root xmlns:sld="http://www.opengis.net/sld">'
        '<sld:Name>test</sld:Name>'
        '</sld:Root>',
      );
      final child = findChild(root, 'Name');

      expect(child, isNotNull);
      expect(child!.innerText, 'test');
    });

    test('finds se-prefixed child', () {
      final root = _parse(
        '<sld:Root xmlns:sld="http://www.opengis.net/sld" '
        'xmlns:se="http://www.opengis.net/se">'
        '<se:Name>test</se:Name>'
        '</sld:Root>',
      );
      final child = findChild(root, 'Name');

      expect(child, isNotNull);
      expect(child!.innerText, 'test');
    });

    test('finds child with default SLD namespace', () {
      final root = _parse(
        '<Root xmlns="http://www.opengis.net/sld">'
        '<Name>test</Name>'
        '</Root>',
      );
      final child = findChild(root, 'Name');

      expect(child, isNotNull);
      expect(child!.innerText, 'test');
    });

    test('returns null for missing child', () {
      final root = _parse('<Root><Other>x</Other></Root>');

      expect(findChild(root, 'Name'), isNull);
    });

    test('finds child with unknown prefix by local name', () {
      final root = _parse(
        '<x:Root xmlns:x="http://custom.example">'
        '<x:Name>test</x:Name>'
        '</x:Root>',
      );
      final child = findChild(root, 'Name');

      expect(child, isNotNull);
      expect(child!.innerText, 'test');
    });
  });

  // -----------------------------------------------------------------------
  // findChildren
  // -----------------------------------------------------------------------
  group('findChildren', () {
    test('finds multiple children across namespaces', () {
      final root = _parse(
        '<Root>'
        '<Rule>a</Rule>'
        '<Rule>b</Rule>'
        '</Root>',
      );

      expect(findChildren(root, 'Rule'), hasLength(2));
    });

    test('finds se-prefixed children', () {
      final root = _parse(
        '<sld:Root xmlns:sld="http://www.opengis.net/sld" '
        'xmlns:se="http://www.opengis.net/se">'
        '<se:Rule>a</se:Rule>'
        '<se:Rule>b</se:Rule>'
        '</sld:Root>',
      );

      expect(findChildren(root, 'Rule'), hasLength(2));
    });

    test('returns empty list for no matches', () {
      final root = _parse('<Root><Other/></Root>');

      expect(findChildren(root, 'Rule'), isEmpty);
    });

    test('deduplicates results', () {
      // An unprefixed element in SLD default namespace could match
      // both namespace and local-name-only fallback.
      final root = _parse(
        '<Root xmlns="http://www.opengis.net/sld">'
        '<Name>a</Name>'
        '</Root>',
      );

      expect(findChildren(root, 'Name'), hasLength(1));
    });
  });

  // -----------------------------------------------------------------------
  // childText
  // -----------------------------------------------------------------------
  group('childText', () {
    test('returns trimmed text', () {
      final root = _parse('<Root><Value>  42  </Value></Root>');

      expect(childText(root, 'Value'), '42');
    });

    test('returns null for missing child', () {
      final root = _parse('<Root></Root>');

      expect(childText(root, 'Value'), isNull);
    });

    test('returns null for empty text', () {
      final root = _parse('<Root><Value>   </Value></Root>');

      expect(childText(root, 'Value'), isNull);
    });

    test('works with namespaced elements', () {
      final root = _parse(
        '<sld:Root xmlns:sld="http://www.opengis.net/sld">'
        '<sld:Title>My Title</sld:Title>'
        '</sld:Root>',
      );

      expect(childText(root, 'Title'), 'My Title');
    });
  });

  // -----------------------------------------------------------------------
  // stringAttr / doubleAttr
  // -----------------------------------------------------------------------
  group('stringAttr', () {
    test('returns attribute value', () {
      final el = _parse('<E name="foo"/>');

      expect(stringAttr(el, 'name'), 'foo');
    });

    test('returns null for missing attribute', () {
      final el = _parse('<E/>');

      expect(stringAttr(el, 'name'), isNull);
    });
  });

  group('doubleAttr', () {
    test('parses valid double', () {
      final el = _parse('<E opacity="0.75"/>');

      expect(doubleAttr(el, 'opacity'), 0.75);
    });

    test('parses integer as double', () {
      final el = _parse('<E value="42"/>');

      expect(doubleAttr(el, 'value'), 42.0);
    });

    test('returns null for missing attribute', () {
      final el = _parse('<E/>');

      expect(doubleAttr(el, 'opacity'), isNull);
    });

    test('returns null for non-numeric value', () {
      final el = _parse('<E opacity="abc"/>');

      expect(doubleAttr(el, 'opacity'), isNull);
    });
  });

  // -----------------------------------------------------------------------
  // parseColorHex
  // -----------------------------------------------------------------------
  group('parseColorHex', () {
    test('parses #RRGGBB to 0xFFRRGGBB', () {
      expect(parseColorHex('#FF0000'), 0xFFFF0000);
      expect(parseColorHex('#00FF00'), 0xFF00FF00);
      expect(parseColorHex('#0000FF'), 0xFF0000FF);
      expect(parseColorHex('#000000'), 0xFF000000);
      expect(parseColorHex('#FFFFFF'), 0xFFFFFFFF);
    });

    test('parses #AARRGGBB', () {
      expect(parseColorHex('#80FF0000'), 0x80FF0000);
      expect(parseColorHex('#00000000'), 0x00000000);
    });

    test('parses lowercase hex', () {
      expect(parseColorHex('#ff0000'), 0xFFFF0000);
      expect(parseColorHex('#aabbcc'), 0xFFAABBCC);
    });

    test('parses 0x prefix', () {
      expect(parseColorHex('0xFF0000'), 0xFFFF0000);
      expect(parseColorHex('0x80FF0000'), 0x80FF0000);
    });

    test('handles whitespace', () {
      expect(parseColorHex('  #FF0000  '), 0xFFFF0000);
    });

    test('returns null for null input', () {
      expect(parseColorHex(null), isNull);
    });

    test('returns null for invalid format', () {
      expect(parseColorHex(''), isNull);
      expect(parseColorHex('FF0000'), isNull);
      expect(parseColorHex('#GG0000'), isNull);
      expect(parseColorHex('#FFF'), isNull);
      expect(parseColorHex('#FFFFF'), isNull);
    });
  });
}
