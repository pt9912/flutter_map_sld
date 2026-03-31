import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:flutter_map_sld/src/parser/parsers/raster_symbolizer_parser.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

XmlElement _el(String xml) => XmlDocument.parse(xml).rootElement;

void main() {
  // -----------------------------------------------------------------------
  // ColorMapEntry
  // -----------------------------------------------------------------------
  group('parseColorMapEntry', () {
    test('parses valid entry', () {
      final el = _el(
        '<ColorMapEntry color="#FF0000" quantity="100" '
        'opacity="0.8" label="High"/>',
      );
      final issues = <SldParseIssue>[];
      final entry = parseColorMapEntry(el, issues, '/test');

      expect(entry, isNotNull);
      expect(entry!.colorArgb, 0xFFFF0000);
      expect(entry.quantity, 100.0);
      expect(entry.opacity, 0.8);
      expect(entry.label, 'High');
      expect(issues, isEmpty);
    });

    test('defaults opacity to 1.0', () {
      final el = _el('<ColorMapEntry color="#000000" quantity="0"/>');
      final issues = <SldParseIssue>[];
      final entry = parseColorMapEntry(el, issues, '/test');

      expect(entry!.opacity, 1.0);
    });

    test('returns null and issues error for missing color', () {
      final el = _el('<ColorMapEntry quantity="0"/>');
      final issues = <SldParseIssue>[];
      final entry = parseColorMapEntry(el, issues, '/test');

      expect(entry, isNull);
      expect(issues, hasLength(1));
      expect(issues.first.code, 'invalid-color');
      expect(issues.first.severity, SldIssueSeverity.error);
    });

    test('returns null and issues error for missing quantity', () {
      final el = _el('<ColorMapEntry color="#FF0000"/>');
      final issues = <SldParseIssue>[];
      final entry = parseColorMapEntry(el, issues, '/test');

      expect(entry, isNull);
      expect(issues, hasLength(1));
      expect(issues.first.code, 'invalid-quantity');
    });
  });

  // -----------------------------------------------------------------------
  // ColorMap
  // -----------------------------------------------------------------------
  group('parseColorMap', () {
    test('parses ramp with entries', () {
      final el = _el(
        '<ColorMap>'
        '<ColorMapEntry color="#000000" quantity="0"/>'
        '<ColorMapEntry color="#FFFFFF" quantity="100"/>'
        '</ColorMap>',
      );
      final issues = <SldParseIssue>[];
      final cm = parseColorMap(el, issues, '/test');

      expect(cm, isNotNull);
      expect(cm!.type, ColorMapType.ramp);
      expect(cm.entries, hasLength(2));
      expect(issues, isEmpty);
    });

    test('parses type="intervals"', () {
      final el = _el(
        '<ColorMap type="intervals">'
        '<ColorMapEntry color="#FF0000" quantity="50"/>'
        '</ColorMap>',
      );
      final issues = <SldParseIssue>[];
      final cm = parseColorMap(el, issues, '/test');

      expect(cm!.type, ColorMapType.intervals);
    });

    test('parses type="values"', () {
      final el = _el(
        '<ColorMap type="values">'
        '<ColorMapEntry color="#FF0000" quantity="1"/>'
        '</ColorMap>',
      );
      final issues = <SldParseIssue>[];
      final cm = parseColorMap(el, issues, '/test');

      expect(cm!.type, ColorMapType.exactValues);
    });

    test('defaults to ramp for unknown type', () {
      final el = _el(
        '<ColorMap type="unknown">'
        '<ColorMapEntry color="#FF0000" quantity="1"/>'
        '</ColorMap>',
      );
      final issues = <SldParseIssue>[];
      final cm = parseColorMap(el, issues, '/test');

      expect(cm!.type, ColorMapType.ramp);
    });

    test('reports unknown children in ColorMap', () {
      final el = _el(
        '<ColorMap>'
        '<ColorMapEntry color="#000000" quantity="0"/>'
        '<VendorThing>x</VendorThing>'
        '</ColorMap>',
      );
      final issues = <SldParseIssue>[];
      parseColorMap(el, issues, '/test');

      expect(issues, hasLength(1));
      expect(issues.first.code, 'unknown-element');
      expect(issues.first.severity, SldIssueSeverity.info);
    });

    test('skips invalid entries and continues', () {
      final el = _el(
        '<ColorMap>'
        '<ColorMapEntry color="#000000" quantity="0"/>'
        '<ColorMapEntry quantity="50"/>'
        '<ColorMapEntry color="#FFFFFF" quantity="100"/>'
        '</ColorMap>',
      );
      final issues = <SldParseIssue>[];
      final cm = parseColorMap(el, issues, '/test');

      expect(cm!.entries, hasLength(2));
      expect(issues, hasLength(1));
    });
  });

  // -----------------------------------------------------------------------
  // ContrastEnhancement
  // -----------------------------------------------------------------------
  group('parseContrastEnhancement', () {
    test('parses Normalize with GammaValue', () {
      final el = _el(
        '<ContrastEnhancement>'
        '<Normalize/>'
        '<GammaValue>1.5</GammaValue>'
        '</ContrastEnhancement>',
      );
      final issues = <SldParseIssue>[];
      final ce = parseContrastEnhancement(el, issues, '/test');

      expect(ce.method, ContrastMethod.normalize);
      expect(ce.gammaValue, 1.5);
      expect(issues, isEmpty);
    });

    test('parses Histogram', () {
      final el = _el(
        '<ContrastEnhancement><Histogram/></ContrastEnhancement>',
      );
      final issues = <SldParseIssue>[];
      final ce = parseContrastEnhancement(el, issues, '/test');

      expect(ce.method, ContrastMethod.histogram);
    });

    test('handles missing method', () {
      final el = _el(
        '<ContrastEnhancement>'
        '<GammaValue>2.0</GammaValue>'
        '</ContrastEnhancement>',
      );
      final issues = <SldParseIssue>[];
      final ce = parseContrastEnhancement(el, issues, '/test');

      expect(ce.method, isNull);
      expect(ce.gammaValue, 2.0);
    });

    test('warns on invalid GammaValue', () {
      final el = _el(
        '<ContrastEnhancement>'
        '<GammaValue>abc</GammaValue>'
        '</ContrastEnhancement>',
      );
      final issues = <SldParseIssue>[];
      final ce = parseContrastEnhancement(el, issues, '/test');

      expect(ce.gammaValue, isNull);
      expect(issues, hasLength(1));
      expect(issues.first.code, 'invalid-gamma');
      expect(issues.first.severity, SldIssueSeverity.warning);
    });
  });

  // -----------------------------------------------------------------------
  // ChannelSelection
  // -----------------------------------------------------------------------
  group('parseChannelSelection', () {
    test('parses RGB channels', () {
      final el = _el(
        '<ChannelSelection>'
        '<RedChannel><SourceChannelName>1</SourceChannelName></RedChannel>'
        '<GreenChannel><SourceChannelName>2</SourceChannelName></GreenChannel>'
        '<BlueChannel><SourceChannelName>3</SourceChannelName></BlueChannel>'
        '</ChannelSelection>',
      );
      final issues = <SldParseIssue>[];
      final cs = parseChannelSelection(el, issues, '/test');

      expect(cs.redChannel!.channelName, '1');
      expect(cs.greenChannel!.channelName, '2');
      expect(cs.blueChannel!.channelName, '3');
      expect(cs.grayChannel, isNull);
      expect(issues, isEmpty);
    });

    test('parses gray channel', () {
      final el = _el(
        '<ChannelSelection>'
        '<GrayChannel><SourceChannelName>1</SourceChannelName></GrayChannel>'
        '</ChannelSelection>',
      );
      final issues = <SldParseIssue>[];
      final cs = parseChannelSelection(el, issues, '/test');

      expect(cs.grayChannel!.channelName, '1');
      expect(cs.redChannel, isNull);
    });

    test('parses per-channel contrast enhancement', () {
      final el = _el(
        '<ChannelSelection>'
        '<RedChannel>'
        '<SourceChannelName>1</SourceChannelName>'
        '<ContrastEnhancement>'
        '<Normalize/>'
        '<GammaValue>1.5</GammaValue>'
        '</ContrastEnhancement>'
        '</RedChannel>'
        '<GreenChannel><SourceChannelName>2</SourceChannelName></GreenChannel>'
        '<BlueChannel><SourceChannelName>3</SourceChannelName></BlueChannel>'
        '</ChannelSelection>',
      );
      final issues = <SldParseIssue>[];
      final cs = parseChannelSelection(el, issues, '/test');

      expect(cs.redChannel!.contrastEnhancement!.method,
          ContrastMethod.normalize);
      expect(cs.redChannel!.contrastEnhancement!.gammaValue, 1.5);
      expect(cs.greenChannel!.contrastEnhancement, isNull);
      expect(issues, isEmpty);
    });

    test('warns on missing SourceChannelName', () {
      final el = _el(
        '<ChannelSelection>'
        '<RedChannel></RedChannel>'
        '</ChannelSelection>',
      );
      final issues = <SldParseIssue>[];
      final cs = parseChannelSelection(el, issues, '/test');

      expect(cs.redChannel, isNull);
      expect(issues, hasLength(1));
      expect(issues.first.code, 'missing-channel-name');
    });
  });

  // -----------------------------------------------------------------------
  // ShadedRelief
  // -----------------------------------------------------------------------
  group('parseShadedRelief', () {
    test('parses with all fields', () {
      final el = _el(
        '<ShadedRelief>'
        '<BrightnessOnly>true</BrightnessOnly>'
        '<ReliefFactor>55</ReliefFactor>'
        '</ShadedRelief>',
      );
      final issues = <SldParseIssue>[];
      final sr = parseShadedRelief(el, issues, '/test');

      expect(sr.brightnessOnly, isTrue);
      expect(sr.reliefFactor, 55.0);
      expect(issues, isEmpty);
    });

    test('defaults brightnessOnly to false', () {
      final el = _el(
        '<ShadedRelief>'
        '<ReliefFactor>30</ReliefFactor>'
        '</ShadedRelief>',
      );
      final issues = <SldParseIssue>[];
      final sr = parseShadedRelief(el, issues, '/test');

      expect(sr.brightnessOnly, isFalse);
      expect(sr.reliefFactor, 30.0);
    });

    test('handles empty element', () {
      final el = _el('<ShadedRelief/>');
      final issues = <SldParseIssue>[];
      final sr = parseShadedRelief(el, issues, '/test');

      expect(sr.brightnessOnly, isFalse);
      expect(sr.reliefFactor, isNull);
      expect(issues, isEmpty);
    });

    test('warns on invalid ReliefFactor', () {
      final el = _el(
        '<ShadedRelief>'
        '<ReliefFactor>abc</ReliefFactor>'
        '</ShadedRelief>',
      );
      final issues = <SldParseIssue>[];
      final sr = parseShadedRelief(el, issues, '/test');

      expect(sr.reliefFactor, isNull);
      expect(issues, hasLength(1));
      expect(issues.first.code, 'invalid-relief-factor');
    });

    test('parses BrightnessOnly value "1" as true', () {
      final el = _el(
        '<ShadedRelief>'
        '<BrightnessOnly>1</BrightnessOnly>'
        '</ShadedRelief>',
      );
      final issues = <SldParseIssue>[];
      final sr = parseShadedRelief(el, issues, '/test');

      expect(sr.brightnessOnly, isTrue);
    });
  });

  // -----------------------------------------------------------------------
  // RasterSymbolizer
  // -----------------------------------------------------------------------
  group('parseRasterSymbolizer', () {
    test('parses complete raster symbolizer', () {
      final el = _el(
        '<RasterSymbolizer>'
        '<Opacity>0.75</Opacity>'
        '<ColorMap type="ramp">'
        '<ColorMapEntry color="#000000" quantity="0" opacity="1.0"/>'
        '<ColorMapEntry color="#FFFFFF" quantity="100" opacity="1.0"/>'
        '</ColorMap>'
        '<ContrastEnhancement>'
        '<Normalize/>'
        '<GammaValue>1.2</GammaValue>'
        '</ContrastEnhancement>'
        '</RasterSymbolizer>',
      );
      final issues = <SldParseIssue>[];
      final rs = parseRasterSymbolizer(el, issues, '/test');

      expect(rs.opacity, 0.75);
      expect(rs.colorMap, isNotNull);
      expect(rs.colorMap!.entries, hasLength(2));
      expect(rs.contrastEnhancement?.method, ContrastMethod.normalize);
      expect(rs.contrastEnhancement?.gammaValue, 1.2);
      expect(rs.extensions, isEmpty);
      expect(issues, isEmpty);
    });

    test('handles empty RasterSymbolizer', () {
      final el = _el('<RasterSymbolizer/>');
      final issues = <SldParseIssue>[];
      final rs = parseRasterSymbolizer(el, issues, '/test');

      expect(rs.opacity, isNull);
      expect(rs.colorMap, isNull);
      expect(rs.contrastEnhancement, isNull);
      expect(rs.channelSelection, isNull);
      expect(rs.shadedRelief, isNull);
      expect(issues, isEmpty);
    });

    test('parses ChannelSelection and ShadedRelief', () {
      final el = _el(
        '<RasterSymbolizer>'
        '<ChannelSelection>'
        '<GrayChannel><SourceChannelName>1</SourceChannelName></GrayChannel>'
        '</ChannelSelection>'
        '<ShadedRelief>'
        '<ReliefFactor>55</ReliefFactor>'
        '</ShadedRelief>'
        '</RasterSymbolizer>',
      );
      final issues = <SldParseIssue>[];
      final rs = parseRasterSymbolizer(el, issues, '/test');

      expect(rs.channelSelection!.grayChannel!.channelName, '1');
      expect(rs.shadedRelief!.reliefFactor, 55.0);
      expect(rs.extensions, isEmpty);
      expect(issues, isEmpty);
    });

    test('warns on invalid Opacity', () {
      final el = _el(
        '<RasterSymbolizer><Opacity>abc</Opacity></RasterSymbolizer>',
      );
      final issues = <SldParseIssue>[];
      final rs = parseRasterSymbolizer(el, issues, '/test');

      expect(rs.opacity, isNull);
      expect(issues, hasLength(1));
      expect(issues.first.code, 'invalid-opacity');
    });

    test('captures unknown children as ExtensionNodes', () {
      final el = _el(
        '<RasterSymbolizer>'
        '<Opacity>1.0</Opacity>'
        '<VendorOption name="custom">42</VendorOption>'
        '</RasterSymbolizer>',
      );
      final issues = <SldParseIssue>[];
      final rs = parseRasterSymbolizer(el, issues, '/test');

      expect(rs.extensions, hasLength(1));
      expect(rs.extensions.first.localName, 'VendorOption');
      expect(rs.extensions.first.text, '42');
      expect(rs.extensions.first.attributes['name'], 'custom');
      expect(rs.extensions.first.rawXml, contains('VendorOption'));

      // Info issue reported.
      expect(issues, hasLength(1));
      expect(issues.first.code, 'unknown-element');
      expect(issues.first.severity, SldIssueSeverity.info);
    });

    test('works with se: namespace', () {
      final el = _el(
        '<se:RasterSymbolizer xmlns:se="http://www.opengis.net/se">'
        '<se:Opacity>0.5</se:Opacity>'
        '<se:ColorMap>'
        '<se:ColorMapEntry color="#FF0000" quantity="10"/>'
        '</se:ColorMap>'
        '</se:RasterSymbolizer>',
      );
      final issues = <SldParseIssue>[];
      final rs = parseRasterSymbolizer(el, issues, '/test');

      expect(rs.opacity, 0.5);
      expect(rs.colorMap!.entries, hasLength(1));
      expect(issues, isEmpty);
    });
  });
}
