import 'fill.dart';
import 'stroke.dart';

/// Styling for polygon features.
class PolygonSymbolizer {
  const PolygonSymbolizer({
    this.fill,
    this.stroke,
  });

  /// The fill styling for the polygon interior.
  final Fill? fill;

  /// The stroke styling for the polygon outline.
  final Stroke? stroke;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolygonSymbolizer &&
          fill == other.fill &&
          stroke == other.stroke;

  @override
  int get hashCode => Object.hash(fill, stroke);
}
