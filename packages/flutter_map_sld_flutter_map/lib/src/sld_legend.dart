import 'package:flutter/material.dart';
import 'package:flutter_map_sld/flutter_map_sld.dart';

/// A widget that renders a color-map legend from [LegendEntry] data.
///
/// Typically used with [extractLegend] from a [ColorMap]:
/// ```dart
/// final entries = extractLegend(rasterSymbolizer.colorMap!);
/// SldLegend(entries: entries);
/// ```
class SldLegend extends StatelessWidget {
  /// Creates a legend widget from legend entries.
  const SldLegend({
    super.key,
    required this.entries,
    this.direction = Axis.vertical,
    this.swatchSize = const Size(24, 16),
    this.labelStyle,
    this.spacing = 4.0,
  });

  /// The legend entries to display.
  final List<LegendEntry> entries;

  /// Layout direction. Defaults to [Axis.vertical].
  final Axis direction;

  /// Size of each color swatch. Defaults to 24x16.
  final Size swatchSize;

  /// Text style for labels. Uses default if null.
  final TextStyle? labelStyle;

  /// Spacing between entries.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      for (final entry in entries) _buildEntry(context, entry),
    ];

    if (direction == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildEntry(BuildContext context, LegendEntry entry) {
    final color = Color((entry.colorArgb & 0x00FFFFFF) |
        ((entry.opacity * 255).round() << 24));

    final swatch = Container(
      width: swatchSize.width,
      height: swatchSize.height,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black26, width: 0.5),
      ),
    );

    final label = entry.label ?? entry.quantity.toString();

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        SizedBox(width: spacing),
        Text(label, style: labelStyle),
      ],
    );

    if (direction == Axis.vertical && entries.last != entry) {
      return Padding(
        padding: EdgeInsets.only(bottom: spacing),
        child: row,
      );
    }
    if (direction == Axis.horizontal && entries.last != entry) {
      return Padding(
        padding: EdgeInsets.only(right: spacing * 2),
        child: row,
      );
    }
    return row;
  }
}
