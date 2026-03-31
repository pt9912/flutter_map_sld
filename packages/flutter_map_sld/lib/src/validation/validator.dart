import '../model/issue.dart';
import '../model/sld_document.dart';
import 'rules/color_map_rules.dart';
import 'rules/raster_rules.dart';
import 'rules/scale_rules.dart';
import 'validation_result.dart';

/// Validates a parsed [SldDocument] against domain-level rules.
///
/// The validator operates on successfully parsed models — it does not
/// re-check XML structure. Parser issues and validation issues are
/// reported through separate channels ([SldParseIssue] vs
/// [SldValidationIssue]).
class SldValidator {
  /// Creates a validator with the default rule set.
  const SldValidator();

  /// Validates the given [document] and returns a [SldValidationResult].
  SldValidationResult validate(SldDocument document) {
    final issues = <SldValidationIssue>[];

    for (var li = 0; li < document.layers.length; li++) {
      final layer = document.layers[li];
      final layerPath = 'layers[$li]';

      for (var si = 0; si < layer.styles.length; si++) {
        final style = layer.styles[si];
        final stylePath = '$layerPath.styles[$si]';

        for (var fi = 0; fi < style.featureTypeStyles.length; fi++) {
          final fts = style.featureTypeStyles[fi];
          final ftsPath = '$stylePath.featureTypeStyles[$fi]';

          for (var ri = 0; ri < fts.rules.length; ri++) {
            final rule = fts.rules[ri];
            final rulePath = '$ftsPath.rules[$ri]';

            validateScaleDenominators(rule, issues, rulePath);

            final rs = rule.rasterSymbolizer;
            if (rs != null) {
              final rsPath = '$rulePath.rasterSymbolizer';
              validateRasterSymbolizer(rs, issues, rsPath);

              if (rs.colorMap != null) {
                validateColorMap(rs.colorMap!, issues, '$rsPath.colorMap');
              }
            }
          }
        }
      }
    }

    return SldValidationResult(issues: issues);
  }
}
