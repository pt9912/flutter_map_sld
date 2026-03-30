/// Method used for contrast enhancement of raster data.
enum ContrastMethod {
  /// Stretches pixel values to fill the full range.
  normalize,

  /// Redistributes pixel values for uniform histogram.
  histogram,

  /// No contrast enhancement applied.
  none,
}

/// Contrast enhancement parameters for a `RasterSymbolizer`.
class ContrastEnhancement {
  const ContrastEnhancement({
    this.method,
    this.gammaValue,
  });

  /// The contrast enhancement method. Null if not specified.
  final ContrastMethod? method;

  /// Gamma correction value. Values < 1.0 brighten, > 1.0 darken.
  final double? gammaValue;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContrastEnhancement &&
          method == other.method &&
          gammaValue == other.gammaValue;

  @override
  int get hashCode => Object.hash(method, gammaValue);
}
