import 'fill.dart';
import 'stroke.dart';

/// A well-known mark shape.
class Mark {
  const Mark({
    this.wellKnownName,
    this.fill,
    this.stroke,
  });

  /// Shape name: `square`, `circle`, `triangle`, `star`, `cross`, `x`.
  final String? wellKnownName;

  /// Fill styling for the mark interior.
  final Fill? fill;

  /// Stroke styling for the mark outline.
  final Stroke? stroke;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mark &&
          wellKnownName == other.wellKnownName &&
          fill == other.fill &&
          stroke == other.stroke;

  @override
  int get hashCode => Object.hash(wellKnownName, fill, stroke);
}

/// An external image used as a graphic symbol.
class ExternalGraphic {
  const ExternalGraphic({
    required this.onlineResource,
    this.format,
  });

  /// URL or path to the graphic resource.
  final String onlineResource;

  /// MIME type of the graphic (e.g. `image/png`).
  final String? format;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExternalGraphic &&
          onlineResource == other.onlineResource &&
          format == other.format;

  @override
  int get hashCode => Object.hash(onlineResource, format);
}

/// A graphic symbol used in point symbolizers.
class Graphic {
  const Graphic({
    this.mark,
    this.externalGraphic,
    this.size,
    this.rotation,
    this.opacity,
  });

  /// A well-known mark shape.
  final Mark? mark;

  /// An external graphic image.
  final ExternalGraphic? externalGraphic;

  /// Symbol size in pixels.
  final double? size;

  /// Rotation angle in degrees (clockwise).
  final double? rotation;

  /// Graphic opacity from 0.0 (transparent) to 1.0 (opaque).
  final double? opacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Graphic &&
          mark == other.mark &&
          externalGraphic == other.externalGraphic &&
          size == other.size &&
          rotation == other.rotation &&
          opacity == other.opacity;

  @override
  int get hashCode =>
      Object.hash(mark, externalGraphic, size, rotation, opacity);
}
