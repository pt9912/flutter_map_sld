import 'contrast_enhancement.dart';

/// A selected channel (band) within a raster dataset.
class SelectedChannel {
  const SelectedChannel({
    required this.channelName,
    this.contrastEnhancement,
  });

  /// The source channel name (typically a band number like `"1"`).
  final String channelName;

  /// Optional per-channel contrast enhancement.
  final ContrastEnhancement? contrastEnhancement;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedChannel &&
          channelName == other.channelName &&
          contrastEnhancement == other.contrastEnhancement;

  @override
  int get hashCode => Object.hash(channelName, contrastEnhancement);
}

/// Channel selection for multi-band raster data.
///
/// Either RGB channels or a single gray channel may be specified, but not both.
class ChannelSelection {
  const ChannelSelection({
    this.redChannel,
    this.greenChannel,
    this.blueChannel,
    this.grayChannel,
  });

  /// Red channel for RGB rendering.
  final SelectedChannel? redChannel;

  /// Green channel for RGB rendering.
  final SelectedChannel? greenChannel;

  /// Blue channel for RGB rendering.
  final SelectedChannel? blueChannel;

  /// Gray channel for single-band rendering.
  final SelectedChannel? grayChannel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelSelection &&
          redChannel == other.redChannel &&
          greenChannel == other.greenChannel &&
          blueChannel == other.blueChannel &&
          grayChannel == other.grayChannel;

  @override
  int get hashCode =>
      Object.hash(redChannel, greenChannel, blueChannel, grayChannel);
}
