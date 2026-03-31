/// Fill styling for polygons and marks.
class Fill {
  const Fill({
    this.colorArgb,
    this.opacity,
  });

  /// Fill color as ARGB integer.
  final int? colorArgb;

  /// Fill opacity from 0.0 (transparent) to 1.0 (opaque).
  final double? opacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fill &&
          colorArgb == other.colorArgb &&
          opacity == other.opacity;

  @override
  int get hashCode => Object.hash(colorArgb, opacity);
}
