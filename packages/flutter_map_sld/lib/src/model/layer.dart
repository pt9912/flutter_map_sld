import '_equality.dart';
import 'style.dart';

/// A named layer within an SLD document.
class SldLayer {
  SldLayer({
    this.name,
    required List<UserStyle> styles,
  }) : styles = List.unmodifiable(styles);

  /// The layer name, corresponding to a WMS layer.
  final String? name;

  /// User styles applied to this layer (unmodifiable).
  final List<UserStyle> styles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SldLayer &&
          name == other.name &&
          deepListEquals(styles, other.styles);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(styles));
}
