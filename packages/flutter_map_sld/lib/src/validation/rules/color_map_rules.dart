import '../../model/color_map.dart';
import '../../model/issue.dart';

/// Validates a [ColorMap] against domain rules.
void validateColorMap(
  ColorMap colorMap,
  List<SldValidationIssue> issues,
  String path,
) {
  // ColorMap must have at least one entry.
  if (colorMap.entries.isEmpty) {
    issues.add(SldValidationIssue(
      severity: SldIssueSeverity.error,
      code: 'empty-color-map',
      message: 'ColorMap must have at least one entry',
      location: path,
    ));
    return; // No further checks possible.
  }

  // ColorMap type="intervals" is a GeoServer vendor extension.
  if (colorMap.type == ColorMapType.intervals) {
    issues.add(SldValidationIssue(
      severity: SldIssueSeverity.info,
      code: 'vendor-extension-intervals',
      message: 'ColorMap type="intervals" is a GeoServer vendor extension',
      location: '$path.type',
    ));
  }

  // Quantity values should be ascending.
  for (var i = 1; i < colorMap.entries.length; i++) {
    if (colorMap.entries[i].quantity < colorMap.entries[i - 1].quantity) {
      issues.add(SldValidationIssue(
        severity: SldIssueSeverity.warning,
        code: 'quantity-not-ascending',
        message:
            'Quantity values should be ascending: '
            '${colorMap.entries[i - 1].quantity} followed by '
            '${colorMap.entries[i].quantity}',
        location: '$path.entries[$i].quantity',
      ));
    }
  }

  // Duplicate quantity values.
  final seen = <double>{};
  for (var i = 0; i < colorMap.entries.length; i++) {
    final q = colorMap.entries[i].quantity;
    if (!seen.add(q)) {
      issues.add(SldValidationIssue(
        severity: SldIssueSeverity.warning,
        code: 'duplicate-quantity',
        message: 'Duplicate quantity value: $q',
        location: '$path.entries[$i].quantity',
      ));
    }
  }

  // Entry-level opacity out of range.
  for (var i = 0; i < colorMap.entries.length; i++) {
    final opacity = colorMap.entries[i].opacity;
    if (opacity < 0.0 || opacity > 1.0) {
      issues.add(SldValidationIssue(
        severity: SldIssueSeverity.error,
        code: 'entry-opacity-out-of-range',
        message:
            'ColorMapEntry opacity must be between 0.0 and 1.0, got $opacity',
        location: '$path.entries[$i].opacity',
      ));
    }
  }
}
