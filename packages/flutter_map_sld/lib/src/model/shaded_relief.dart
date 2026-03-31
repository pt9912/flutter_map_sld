/// Shaded relief parameters for rendering terrain raster data.
class ShadedRelief {
  const ShadedRelief({
    this.brightnessOnly = false,
    this.reliefFactor,
  });

  /// If `true`, only brightness modulation is applied (no hillshade direction).
  final bool brightnessOnly;

  /// Relief exaggeration factor. Typical values are around 55.
  /// Must be non-negative when specified.
  final double? reliefFactor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadedRelief &&
          brightnessOnly == other.brightnessOnly &&
          reliefFactor == other.reliefFactor;

  @override
  int get hashCode => Object.hash(brightnessOnly, reliefFactor);
}
