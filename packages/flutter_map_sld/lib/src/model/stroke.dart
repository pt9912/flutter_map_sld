/// Stroke styling for lines and polygon outlines.
class Stroke {
  const Stroke({
    this.colorArgb,
    this.width,
    this.opacity,
    this.dashArray,
    this.lineCap,
    this.lineJoin,
  });

  /// Stroke color as ARGB integer.
  final int? colorArgb;

  /// Stroke width in pixels.
  final double? width;

  /// Stroke opacity from 0.0 (transparent) to 1.0 (opaque).
  final double? opacity;

  /// Dash pattern as alternating dash/gap lengths.
  final List<double>? dashArray;

  /// Line cap style (`butt`, `round`, `square`).
  final String? lineCap;

  /// Line join style (`mitre`, `round`, `bevel`).
  final String? lineJoin;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stroke &&
          colorArgb == other.colorArgb &&
          width == other.width &&
          opacity == other.opacity &&
          _listEquals(dashArray, other.dashArray) &&
          lineCap == other.lineCap &&
          lineJoin == other.lineJoin;

  @override
  int get hashCode => Object.hash(
        colorArgb,
        width,
        opacity,
        dashArray != null ? Object.hashAll(dashArray!) : null,
        lineCap,
        lineJoin,
      );
}

bool _listEquals(List<double>? a, List<double>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
