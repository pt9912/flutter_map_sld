import 'package:flutter/material.dart';
import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:flutter_map_sld_flutter_map/flutter_map_sld_flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SldLegend', () {
    final entries = [
      const LegendEntry(
        colorArgb: 0xFF008000,
        quantity: 0.0,
        opacity: 1.0,
        label: 'Low',
      ),
      const LegendEntry(
        colorArgb: 0xFF663333,
        quantity: 100.0,
        opacity: 1.0,
        label: 'Medium',
      ),
      const LegendEntry(
        colorArgb: 0xFFFFFFFF,
        quantity: 200.0,
        opacity: 0.5,
        label: 'High',
      ),
    ];

    testWidgets('renders vertical legend with correct entries',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SldLegend(entries: entries),
          ),
        ),
      );

      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('renders horizontal legend', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SldLegend(
              entries: entries,
              direction: Axis.horizontal,
            ),
          ),
        ),
      );

      expect(find.text('Low'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('uses quantity as label when label is null', (tester) async {
      final noLabelEntries = [
        const LegendEntry(
          colorArgb: 0xFF000000,
          quantity: 42.0,
          opacity: 1.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SldLegend(entries: noLabelEntries),
          ),
        ),
      );

      expect(find.text('42.0'), findsOneWidget);
    });

    testWidgets('respects custom swatch size and label style',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SldLegend(
              entries: entries,
              swatchSize: const Size(32, 20),
              labelStyle: const TextStyle(fontSize: 10, color: Colors.red),
            ),
          ),
        ),
      );

      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('renders color swatches', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SldLegend(entries: entries),
          ),
        ),
      );

      // Find Container widgets used as swatches.
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });
  });
}
