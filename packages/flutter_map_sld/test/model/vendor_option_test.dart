import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:test/test.dart';

void main() {
  group('VendorOption', () {
    test('can be constructed', () {
      const vo = VendorOption(name: 'renderingMode', value: 'quality');
      expect(vo.name, 'renderingMode');
      expect(vo.value, 'quality');
    });

    test('equal instances are ==', () {
      const a = VendorOption(name: 'key', value: 'val');
      const b = VendorOption(name: 'key', value: 'val');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different name means not ==', () {
      const a = VendorOption(name: 'a', value: 'val');
      const b = VendorOption(name: 'b', value: 'val');
      expect(a, isNot(equals(b)));
    });

    test('different value means not ==', () {
      const a = VendorOption(name: 'key', value: '1');
      const b = VendorOption(name: 'key', value: '2');
      expect(a, isNot(equals(b)));
    });
  });
}
