import 'expression.dart';
import 'fill.dart';

/// Font styling for text labels.
class Font {
  const Font({
    this.family,
    this.style,
    this.weight,
    this.size,
  });

  /// Font family name (e.g. `"Arial"`, `"Serif"`).
  final String? family;

  /// Font style (`normal`, `italic`, `oblique`).
  final String? style;

  /// Font weight (`normal`, `bold`).
  final String? weight;

  /// Font size in pixels.
  final double? size;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Font &&
          family == other.family &&
          style == other.style &&
          weight == other.weight &&
          size == other.size;

  @override
  int get hashCode => Object.hash(family, style, weight, size);
}

/// Halo (outline) around text labels for readability.
class Halo {
  const Halo({
    this.radius,
    this.fill,
  });

  /// Halo radius in pixels.
  final double? radius;

  /// Fill styling for the halo.
  final Fill? fill;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Halo && radius == other.radius && fill == other.fill;

  @override
  int get hashCode => Object.hash(radius, fill);
}

/// Point-based label placement parameters.
class PointPlacement {
  const PointPlacement({
    this.anchorPointX,
    this.anchorPointY,
    this.displacementX,
    this.displacementY,
    this.rotation,
  });

  /// Anchor point X (0.0 = left, 0.5 = center, 1.0 = right).
  final double? anchorPointX;

  /// Anchor point Y (0.0 = bottom, 0.5 = middle, 1.0 = top).
  final double? anchorPointY;

  /// Displacement X in pixels.
  final double? displacementX;

  /// Displacement Y in pixels.
  final double? displacementY;

  /// Rotation angle in degrees.
  final double? rotation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointPlacement &&
          anchorPointX == other.anchorPointX &&
          anchorPointY == other.anchorPointY &&
          displacementX == other.displacementX &&
          displacementY == other.displacementY &&
          rotation == other.rotation;

  @override
  int get hashCode => Object.hash(
      anchorPointX, anchorPointY, displacementX, displacementY, rotation);
}

/// Line-following label placement parameters.
class LinePlacement {
  const LinePlacement({
    this.perpendicularOffset,
  });

  /// Offset perpendicular to the line in pixels.
  final double? perpendicularOffset;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinePlacement &&
          perpendicularOffset == other.perpendicularOffset;

  @override
  int get hashCode => perpendicularOffset.hashCode;
}

/// Label placement strategy.
class LabelPlacement {
  const LabelPlacement({
    this.pointPlacement,
    this.linePlacement,
  });

  /// Point-based placement parameters.
  final PointPlacement? pointPlacement;

  /// Line-following placement parameters.
  final LinePlacement? linePlacement;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabelPlacement &&
          pointPlacement == other.pointPlacement &&
          linePlacement == other.linePlacement;

  @override
  int get hashCode => Object.hash(pointPlacement, linePlacement);
}

/// Styling for text labels on features.
class TextSymbolizer {
  const TextSymbolizer({
    this.label,
    this.font,
    this.fill,
    this.halo,
    this.labelPlacement,
  });

  /// The label expression (typically a [PropertyName] or [Literal]).
  final Expression? label;

  /// Font parameters.
  final Font? font;

  /// Fill styling for the label text.
  final Fill? fill;

  /// Halo around the label text.
  final Halo? halo;

  /// Label placement strategy.
  final LabelPlacement? labelPlacement;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextSymbolizer &&
          label == other.label &&
          font == other.font &&
          fill == other.fill &&
          halo == other.halo &&
          labelPlacement == other.labelPlacement;

  @override
  int get hashCode => Object.hash(label, font, fill, halo, labelPlacement);
}
