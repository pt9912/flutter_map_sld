import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:flutter_map_sld/src/parser/parsers/vector_symbolizer_parser.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

XmlElement _el(String xml) => XmlDocument.parse(xml).rootElement;

void main() {
  // -----------------------------------------------------------------------
  // Stroke
  // -----------------------------------------------------------------------
  group('parseStroke', () {
    test('parses CssParameter values', () {
      final el = _el(
        '<Stroke>'
        '<CssParameter name="stroke">#0000FF</CssParameter>'
        '<CssParameter name="stroke-width">2.5</CssParameter>'
        '<CssParameter name="stroke-opacity">0.7</CssParameter>'
        '<CssParameter name="stroke-dasharray">5 3</CssParameter>'
        '<CssParameter name="stroke-linecap">round</CssParameter>'
        '<CssParameter name="stroke-linejoin">bevel</CssParameter>'
        '</Stroke>',
      );
      final issues = <SldParseIssue>[];
      final s = parseStroke(el, issues, '/test');

      expect(s.colorArgb, 0xFF0000FF);
      expect(s.width, 2.5);
      expect(s.opacity, 0.7);
      expect(s.dashArray, [5.0, 3.0]);
      expect(s.lineCap, 'round');
      expect(s.lineJoin, 'bevel');
      expect(issues, isEmpty);
    });

    test('parses SvgParameter (SE 1.1)', () {
      final el = _el(
        '<Stroke>'
        '<SvgParameter name="stroke">#FF0000</SvgParameter>'
        '<SvgParameter name="stroke-width">1</SvgParameter>'
        '</Stroke>',
      );
      final issues = <SldParseIssue>[];
      final s = parseStroke(el, issues, '/test');

      expect(s.colorArgb, 0xFFFF0000);
      expect(s.width, 1.0);
    });

    test('handles empty element', () {
      final el = _el('<Stroke/>');
      final issues = <SldParseIssue>[];
      final s = parseStroke(el, issues, '/test');

      expect(s.colorArgb, isNull);
      expect(s.width, isNull);
    });
  });

  // -----------------------------------------------------------------------
  // Fill
  // -----------------------------------------------------------------------
  group('parseFill', () {
    test('parses color and opacity', () {
      final el = _el(
        '<Fill>'
        '<CssParameter name="fill">#00FF00</CssParameter>'
        '<CssParameter name="fill-opacity">0.5</CssParameter>'
        '</Fill>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFill(el, issues, '/test');

      expect(f.colorArgb, 0xFF00FF00);
      expect(f.opacity, 0.5);
    });
  });

  // -----------------------------------------------------------------------
  // Mark
  // -----------------------------------------------------------------------
  group('parseMark', () {
    test('parses WellKnownName with fill and stroke', () {
      final el = _el(
        '<Mark>'
        '<WellKnownName>circle</WellKnownName>'
        '<Fill><CssParameter name="fill">#FF0000</CssParameter></Fill>'
        '<Stroke><CssParameter name="stroke">#000000</CssParameter></Stroke>'
        '</Mark>',
      );
      final issues = <SldParseIssue>[];
      final m = parseMark(el, issues, '/test');

      expect(m.wellKnownName, 'circle');
      expect(m.fill!.colorArgb, 0xFFFF0000);
      expect(m.stroke!.colorArgb, 0xFF000000);
    });
  });

  // -----------------------------------------------------------------------
  // Graphic
  // -----------------------------------------------------------------------
  group('parseGraphic', () {
    test('parses mark with size and rotation', () {
      final el = _el(
        '<Graphic>'
        '<Mark><WellKnownName>star</WellKnownName></Mark>'
        '<Size>16</Size>'
        '<Rotation>45</Rotation>'
        '</Graphic>',
      );
      final issues = <SldParseIssue>[];
      final g = parseGraphic(el, issues, '/test');

      expect(g.mark!.wellKnownName, 'star');
      expect(g.size, 16.0);
      expect(g.rotation, 45.0);
    });

    test('parses external graphic', () {
      final el = _el(
        '<Graphic>'
        '<ExternalGraphic>'
        '<OnlineResource xlink:href="http://example.com/icon.png" '
        'xmlns:xlink="http://www.w3.org/1999/xlink"/>'
        '<Format>image/png</Format>'
        '</ExternalGraphic>'
        '<Size>32</Size>'
        '</Graphic>',
      );
      final issues = <SldParseIssue>[];
      final g = parseGraphic(el, issues, '/test');

      expect(g.externalGraphic!.onlineResource,
          'http://example.com/icon.png');
      expect(g.externalGraphic!.format, 'image/png');
      expect(g.size, 32.0);
    });
  });

  // -----------------------------------------------------------------------
  // PointSymbolizer
  // -----------------------------------------------------------------------
  group('parsePointSymbolizer', () {
    test('parses complete point symbolizer', () {
      final el = _el(
        '<PointSymbolizer>'
        '<Graphic>'
        '<Mark><WellKnownName>circle</WellKnownName></Mark>'
        '<Size>10</Size>'
        '</Graphic>'
        '</PointSymbolizer>',
      );
      final issues = <SldParseIssue>[];
      final ps = parsePointSymbolizer(el, issues, '/test');

      expect(ps.graphic!.mark!.wellKnownName, 'circle');
      expect(ps.graphic!.size, 10.0);
      expect(issues, isEmpty);
    });

    test('handles empty PointSymbolizer', () {
      final el = _el('<PointSymbolizer/>');
      final issues = <SldParseIssue>[];
      final ps = parsePointSymbolizer(el, issues, '/test');

      expect(ps.graphic, isNull);
    });
  });

  // -----------------------------------------------------------------------
  // LineSymbolizer
  // -----------------------------------------------------------------------
  group('parseLineSymbolizer', () {
    test('parses stroke', () {
      final el = _el(
        '<LineSymbolizer>'
        '<Stroke>'
        '<CssParameter name="stroke">#0000FF</CssParameter>'
        '<CssParameter name="stroke-width">3</CssParameter>'
        '</Stroke>'
        '</LineSymbolizer>',
      );
      final issues = <SldParseIssue>[];
      final ls = parseLineSymbolizer(el, issues, '/test');

      expect(ls.stroke!.colorArgb, 0xFF0000FF);
      expect(ls.stroke!.width, 3.0);
    });
  });

  // -----------------------------------------------------------------------
  // PolygonSymbolizer
  // -----------------------------------------------------------------------
  group('parsePolygonSymbolizer', () {
    test('parses fill and stroke', () {
      final el = _el(
        '<PolygonSymbolizer>'
        '<Fill><CssParameter name="fill">#AAAAAA</CssParameter></Fill>'
        '<Stroke>'
        '<CssParameter name="stroke">#000000</CssParameter>'
        '<CssParameter name="stroke-width">0.5</CssParameter>'
        '</Stroke>'
        '</PolygonSymbolizer>',
      );
      final issues = <SldParseIssue>[];
      final ps = parsePolygonSymbolizer(el, issues, '/test');

      expect(ps.fill!.colorArgb, 0xFFAAAAAA);
      expect(ps.stroke!.width, 0.5);
    });

    test('handles fill-only polygon', () {
      final el = _el(
        '<PolygonSymbolizer>'
        '<Fill><CssParameter name="fill">#00FF00</CssParameter></Fill>'
        '</PolygonSymbolizer>',
      );
      final issues = <SldParseIssue>[];
      final ps = parsePolygonSymbolizer(el, issues, '/test');

      expect(ps.fill!.colorArgb, 0xFF00FF00);
      expect(ps.stroke, isNull);
    });
  });
}
