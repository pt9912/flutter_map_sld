import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:test/test.dart';

void main() {
  group('SelectedChannel', () {
    test('can be constructed with channel name only', () {
      const sc = SelectedChannel(channelName: '1');
      expect(sc.channelName, '1');
      expect(sc.contrastEnhancement, isNull);
    });

    test('can be constructed with contrast enhancement', () {
      const sc = SelectedChannel(
        channelName: '3',
        contrastEnhancement: ContrastEnhancement(
          method: ContrastMethod.normalize,
          gammaValue: 1.5,
        ),
      );
      expect(sc.channelName, '3');
      expect(sc.contrastEnhancement!.method, ContrastMethod.normalize);
    });

    test('equal instances are ==', () {
      const a = SelectedChannel(channelName: '1');
      const b = SelectedChannel(channelName: '1');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different channel names are not ==', () {
      const a = SelectedChannel(channelName: '1');
      const b = SelectedChannel(channelName: '2');
      expect(a, isNot(equals(b)));
    });
  });

  group('ChannelSelection', () {
    test('can be constructed with RGB channels', () {
      const cs = ChannelSelection(
        redChannel: SelectedChannel(channelName: '1'),
        greenChannel: SelectedChannel(channelName: '2'),
        blueChannel: SelectedChannel(channelName: '3'),
      );
      expect(cs.redChannel!.channelName, '1');
      expect(cs.greenChannel!.channelName, '2');
      expect(cs.blueChannel!.channelName, '3');
      expect(cs.grayChannel, isNull);
    });

    test('can be constructed with gray channel', () {
      const cs = ChannelSelection(
        grayChannel: SelectedChannel(channelName: '1'),
      );
      expect(cs.grayChannel!.channelName, '1');
      expect(cs.redChannel, isNull);
    });

    test('equal instances are ==', () {
      const a = ChannelSelection(
        grayChannel: SelectedChannel(channelName: '1'),
      );
      const b = ChannelSelection(
        grayChannel: SelectedChannel(channelName: '1'),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
