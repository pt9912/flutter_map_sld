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

  // ShadedRelief: reliefFactor must be non-negative.
  final rf = rs.shadedRelief?.reliefFactor;
  if (rf != null && rf < 0.0) {
    issues.add(SldValidationIssue(
      severity: SldIssueSeverity.error,
      code: 'relief-factor-negative',
      message: 'ReliefFactor must be non-negative, got $rf',
      location: '$path.shadedRelief.reliefFactor',
    ));
  }

  // ChannelSelection: RGB requires all three channels.
  final cs = rs.channelSelection;
  if (cs != null) {
    final hasAnyRgb =
        cs.redChannel != null || cs.greenChannel != null || cs.blueChannel != null;
    if (hasAnyRgb) {
      final missing = <String>[];
      if (cs.redChannel == null) missing.add('red');
      if (cs.greenChannel == null) missing.add('green');
      if (cs.blueChannel == null) missing.add('blue');
      if (missing.isNotEmpty) {
        issues.add(SldValidationIssue(
          severity: SldIssueSeverity.error,
          code: 'incomplete-rgb-channels',
          message:
              'RGB ChannelSelection requires all three channels, '
              'missing: ${missing.join(', ')}',
          location: '$path.channelSelection',
        ));
      }
    }
  }
}
