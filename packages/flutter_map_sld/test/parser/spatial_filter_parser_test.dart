import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:flutter_map_sld/src/parser/parsers/filter_parser.dart';
import 'package:gml4dart/gml4dart.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

XmlElement _el(String xml) => XmlDocument.parse(xml).rootElement;

void main() {
  group('Spatial filter parsing', () {
    test('parses BBOX with Envelope', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<BBOX>'
        '<PropertyName>geom</PropertyName>'
        '<gml:Envelope xmlns:gml="http://www.opengis.net/gml"'
        ' srsName="EPSG:4326">'
        '<gml:lowerCorner>0 0</gml:lowerCorner>'
        '<gml:upperCorner>10 10</gml:upperCorner>'
        '</gml:Envelope>'
        '</BBOX>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');

      expect(f, isA<BBox>());
      final bbox = f! as BBox;
      expect(bbox.propertyName, 'geom');
      final env = bbox.geometry as GmlEnvelope;
      expect(env.lowerCorner.x, 0);
      expect(env.upperCorner.x, 10);
    });

    test('parses Intersects with Point', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<Intersects>'
        '<PropertyName>geom</PropertyName>'
        '<gml:Point xmlns:gml="http://www.opengis.net/gml">'
        '<gml:coordinates>5,5</gml:coordinates>'
        '</gml:Point>'
        '</Intersects>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');

      expect(f, isA<Intersects>());
    });

    test('parses Within with Polygon', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<Within>'
        '<PropertyName>geom</PropertyName>'
        '<gml:Polygon xmlns:gml="http://www.opengis.net/gml">'
        '<gml:outerBoundaryIs><gml:LinearRing>'
        '<gml:coordinates>0,0 10,0 10,10 0,10 0,0</gml:coordinates>'
        '</gml:LinearRing></gml:outerBoundaryIs>'
        '</gml:Polygon>'
        '</Within>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');

      expect(f, isA<Within>());
    });

    test('parses DWithin with distance', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<DWithin>'
        '<PropertyName>geom</PropertyName>'
        '<gml:Point xmlns:gml="http://www.opengis.net/gml">'
        '<gml:coordinates>5,5</gml:coordinates>'
        '</gml:Point>'
        '<Distance units="m">1000</Distance>'
        '</DWithin>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');

      expect(f, isA<DWithin>());
      final dw = f! as DWithin;
      expect(dw.distance, 1000);
      expect(dw.units, 'm');
    });

    test('parses Beyond', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<Beyond>'
        '<PropertyName>geom</PropertyName>'
        '<gml:Point xmlns:gml="http://www.opengis.net/gml">'
        '<gml:coordinates>5,5</gml:coordinates>'
        '</gml:Point>'
        '<Distance units="km">50</Distance>'
        '</Beyond>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');

      expect(f, isA<Beyond>());
      final b = f! as Beyond;
      expect(b.distance, 50);
      expect(b.units, 'km');
    });

    test('parses Contains, Touches, Crosses, Overlaps, Disjoint', () {
      for (final op in ['Contains', 'Touches', 'Crosses', 'Overlaps', 'Disjoint']) {
        final el = _el(
          '<Filter xmlns="http://www.opengis.net/ogc">'
          '<$op>'
          '<PropertyName>geom</PropertyName>'
          '<gml:Point xmlns:gml="http://www.opengis.net/gml">'
          '<gml:coordinates>5,5</gml:coordinates>'
          '</gml:Point>'
          '</$op>'
          '</Filter>',
        );
        final issues = <SldParseIssue>[];
        final f = parseFilter(el, issues, '/test');
        expect(f, isNotNull, reason: '$op should parse');
      }
    });

    test('BBOX without envelope warns', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<BBOX>'
        '<PropertyName>geom</PropertyName>'
        '</BBOX>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');

      expect(f, isNull);
      expect(issues.any((i) => i.code == 'bbox-missing-envelope'), isTrue);
    });

    test('spatial filter without geometry warns', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<Intersects>'
        '<PropertyName>geom</PropertyName>'
        '</Intersects>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');

      expect(f, isNull);
      expect(issues.any((i) => i.code == 'spatial-filter-missing-geometry'),
          isTrue);
    });

    test('DWithin without Distance warns', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<DWithin>'
        '<PropertyName>geom</PropertyName>'
        '<gml:Point xmlns:gml="http://www.opengis.net/gml">'
        '<gml:coordinates>5,5</gml:coordinates>'
        '</gml:Point>'
        '</DWithin>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');

      expect(f, isNull);
      expect(issues.any((i) => i.code == 'distance-filter-missing-distance'),
          isTrue);
    });

    test('BBOX without PropertyName still parses', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<BBOX>'
        '<gml:Envelope xmlns:gml="http://www.opengis.net/gml">'
        '<gml:lowerCorner>0 0</gml:lowerCorner>'
        '<gml:upperCorner>10 10</gml:upperCorner>'
        '</gml:Envelope>'
        '</BBOX>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');

      expect(f, isA<BBox>());
      expect((f! as BBox).propertyName, isNull);
    });
  });
}
