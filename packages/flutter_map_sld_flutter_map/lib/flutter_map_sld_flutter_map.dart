/// Flutter and flutter_map adapters for SLD/SE styles.
///
/// Provides [FlutterMapStyleAdapter] for translating parsed SLD rules into
/// flutter_map-friendly style DTOs, [SldAsset] for loading SLD from Flutter
/// asset bundles, and [SldLegend] for rendering ColorMap legends.
library flutter_map_sld_flutter_map;

export 'src/flutter_map_style_adapter.dart';
export 'src/sld_asset.dart';
export 'src/sld_legend.dart';
