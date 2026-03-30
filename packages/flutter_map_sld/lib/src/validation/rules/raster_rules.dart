import '../../model/issue.dart';
import '../../model/raster_symbolizer.dart';

/// Validates a [RasterSymbolizer] against domain rules.
void validateRasterSymbolizer(
  RasterSymbolizer rs,
  List<SldValidationIssue> issues,
  String path,
) {
  // Opacity must be between 0.0 and 1.0.
  final opacity = rs.opacity;
  if (opacity != null && (opacity < 0.0 || opacity > 1.0)) {
    issues.add(SldValidationIssue(
      severity: SldIssueSeverity.error,
      code: 'opacity-out-of-range',
      message: 'Opacity must be between 0.0 and 1.0, got $opacity',
      location: '$path.opacity',
    ));
  }

  // ContrastEnhancement gamma should be positive.
  final gamma = rs.contrastEnhancement?.gammaValue;
  if (gamma != null && gamma <= 0.0) {
    issues.add(SldValidationIssue(
      severity: SldIssueSeverity.warning,
      code: 'gamma-not-positive',
      message: 'GammaValue should be positive, got $gamma',
      location: '$path.contrastEnhancement.gammaValue',
    ));
  }
}
