import 'stroke.dart';

/// Styling for line features.
class LineSymbolizer {
  const LineSymbolizer({
    this.stroke,
  });

  /// The stroke styling for the line.
  final Stroke? stroke;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineSymbolizer && stroke == other.stroke;

  @override
  int get hashCode => stroke.hashCode;
}
