import 'graphic.dart';

/// Styling for point features.
class PointSymbolizer {
  const PointSymbolizer({
    this.graphic,
  });

  /// The graphic symbol to render at the point.
  final Graphic? graphic;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointSymbolizer && graphic == other.graphic;

  @override
  int get hashCode => graphic.hashCode;
}
