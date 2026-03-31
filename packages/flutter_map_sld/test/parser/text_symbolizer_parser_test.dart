import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:flutter_map_sld/src/parser/parsers/text_symbolizer_parser.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

XmlElement _el(String xml) => XmlDocument.parse(xml).rootElement;

void main() {
  group('parseTextSymbolizer', () {
    test('parses complete text symbolizer', () {
      final el = _el(
        '<TextSymbolizer>'
        '<Label><PropertyName>name</PropertyName></Label>'
        '<Font>'
        '<CssParameter name="font-family">Arial</CssParameter>'
        '<CssParameter name="font-size">14</CssParameter>'
        '<CssParameter name="font-style">italic</CssParameter>'
        '<CssParameter name="font-weight">bold</CssParameter>'
        '</Font>'
        '<Fill><CssParameter name="fill">#000000</CssParameter></Fill>'
        '<Halo>'
        '<Radius>2</Radius>'
        '<Fill><CssParameter name="fill">#FFFFFF</CssParameter></Fill>'
        '</Halo>'
        '</TextSymbolizer>',
      );
      final issues = <SldParseIssue>[];
      final ts = parseTextSymbolizer(el, issues, '/test');

      expect(ts.label, isA<PropertyName>());
      expect((ts.label! as PropertyName).name, 'name');
      expect(ts.font!.family, 'Arial');
      expect(ts.font!.size, 14.0);
      expect(ts.font!.style, 'italic');
      expect(ts.font!.weight, 'bold');
      expect(ts.fill!.colorArgb, 0xFF000000);
      expect(ts.halo!.radius, 2.0);
      expect(ts.halo!.fill!.colorArgb, 0xFFFFFFFF);
      expect(issues, isEmpty);
    });

    test('parses literal label', () {
      final el = _el(
        '<TextSymbolizer>'
        '<Label><Literal>Fixed Label</Literal></Label>'
        '</TextSymbolizer>',
      );
      final issues = <SldParseIssue>[];
      final ts = parseTextSymbolizer(el, issues, '/test');

      expect(ts.label, isA<Literal>());
      expect((ts.label! as Literal).value, 'Fixed Label');
    });

    test('handles empty TextSymbolizer', () {
      final el = _el('<TextSymbolizer/>');
      final issues = <SldParseIssue>[];
      final ts = parseTextSymbolizer(el, issues, '/test');

      expect(ts.label, isNull);
      expect(ts.font, isNull);
      expect(ts.fill, isNull);
      expect(ts.halo, isNull);
    });

    test('parses LabelPlacement with PointPlacement', () {
      final el = _el(
        '<TextSymbolizer>'
        '<Label><PropertyName>name</PropertyName></Label>'
        '<LabelPlacement>'
        '<PointPlacement>'
        '<AnchorPoint>'
        '<AnchorPointX>0.5</AnchorPointX>'
        '<AnchorPointY>1.0</AnchorPointY>'
        '</AnchorPoint>'
        '<Displacement>'
        '<DisplacementX>10</DisplacementX>'
        '<DisplacementY>-5</DisplacementY>'
        '</Displacement>'
        '<Rotation>45</Rotation>'
        '</PointPlacement>'
        '</LabelPlacement>'
        '</TextSymbolizer>',
      );
      final issues = <SldParseIssue>[];
      final ts = parseTextSymbolizer(el, issues, '/test');

      final pp = ts.labelPlacement!.pointPlacement!;
      expect(pp.anchorPointX, 0.5);
      expect(pp.anchorPointY, 1.0);
      expect(pp.displacementX, 10.0);
      expect(pp.displacementY, -5.0);
      expect(pp.rotation, 45.0);
    });

    test('parses LabelPlacement with LinePlacement', () {
      final el = _el(
        '<TextSymbolizer>'
        '<Label><PropertyName>name</PropertyName></Label>'
        '<LabelPlacement>'
        '<LinePlacement>'
        '<PerpendicularOffset>5</PerpendicularOffset>'
        '</LinePlacement>'
        '</LabelPlacement>'
        '</TextSymbolizer>',
      );
      final issues = <SldParseIssue>[];
      final ts = parseTextSymbolizer(el, issues, '/test');

      expect(ts.labelPlacement!.linePlacement!.perpendicularOffset, 5.0);
    });
  });
}
