import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/core/theme/app_theme.dart';
import 'package:pocketledger/core/widgets/animated_stat_tile.dart';
import 'package:pocketledger/core/widgets/custom_bottom_sheet.dart';
import 'package:pocketledger/core/widgets/custom_card.dart';
import 'package:pocketledger/core/widgets/glassmorphic_card.dart';
import 'package:pocketledger/core/widgets/primary_button.dart';

void main() {
  group('CustomCard Tests', () {
    testWidgets('renders child content and applies padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: CustomCard(
              padding: EdgeInsets.all(24.0),
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('triggers onTap and onLongPress callbacks', (tester) async {
      int tapCount = 0;
      int longPressCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CustomCard(
              onTap: () => tapCount++,
              onLongPress: () => longPressCount++,
              child: const Text('Interactive Card'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Interactive Card'));
      await tester.pumpAndSettle();
      expect(tapCount, 1);

      await tester.longPress(find.text('Interactive Card'));
      await tester.pumpAndSettle();
      expect(longPressCount, 1);
    });

    testWidgets('adapts properly to OLED theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.oled,
          home: const Scaffold(body: CustomCard(child: Text('OLED Card'))),
        ),
      );

      expect(find.text('OLED Card'), findsOneWidget);
    });
  });

  group('GlassmorphicCard Tests', () {
    testWidgets('renders child with BackdropFilter and blur', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: GlassmorphicCard(blur: 14.0, child: Text('Frosted Content')),
          ),
        ),
      );

      expect(find.text('Frosted Content'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('supports onTap interaction and gradient border', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: GlassmorphicCard(
              onTap: () => tapped = true,
              borderGradient: const LinearGradient(
                colors: [Colors.white, Colors.transparent],
              ),
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('PrimaryButton Tests', () {
    testWidgets('renders label, icons, and triggers onPressed', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: PrimaryButton(
              label: 'Submit Action',
              icon: Icons.check,
              trailingIcon: Icons.arrow_forward,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Submit Action'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);

      await tester.tap(find.text('Submit Action'));
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });

    testWidgets(
      'shows CircularProgressIndicator and disables when isLoading is true',
      (tester) async {
        bool pressed = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: PrimaryButton(
                label: 'Loading Action',
                isLoading: true,
                onPressed: () => pressed = true,
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading Action'), findsNothing);

        await tester.tap(find.byType(PrimaryButton));
        await tester.pump(const Duration(milliseconds: 100));
        expect(pressed, isFalse);
      },
    );

    testWidgets('supports custom width and compact mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: PrimaryButton(
              label: 'Compact',
              isFullWidth: false,
              width: 120.0,
              onPressed: null,
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(PrimaryButton);
      expect(tester.getSize(buttonFinder).width, 120.0);
    });
  });

  group('AnimatedStatTile Tests', () {
    testWidgets('animates numeric rollup and formats currency correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AnimatedStatTile(
              title: 'Monthly Savings',
              value: 4500.50,
              prefix: '\$',
              trendPercentage: 12.5,
              trendLabel: 'vs last month',
            ),
          ),
        ),
      );

      expect(find.text('Monthly Savings'), findsOneWidget);
      expect(find.text('vs last month'), findsOneWidget);
      expect(find.text('12.5%'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('\$4,500.50'), findsOneWidget);
    });

    testWidgets('handles negative trend and inverted polarity', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: AnimatedStatTile(
              title: 'Dining Expenses',
              value: 320.00,
              prefix: '\$',
              trendPercentage: -8.0,
              isPositiveGood: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Dining Expenses'), findsOneWidget);
      expect(find.text('8.0%'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    });

    testWidgets('supports reduced motion mode without animation delay', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: AnimatedStatTile(
                title: 'Quick Metric',
                value: 100.0,
                prefix: '€',
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('€100.00'), findsOneWidget);
    });
  });

  group('CustomBottomSheet Tests', () {
    testWidgets('shows modal bottom sheet and dismisses via close button', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    CustomBottomSheet.show(
                      context: context,
                      title: 'Account Options',
                      child: const Text('Sheet Body Content'),
                    );
                  },
                  child: const Text('Open Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Account Options'), findsOneWidget);
      expect(find.text('Sheet Body Content'), findsOneWidget);

      // Dismiss via close button
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Sheet Body Content'), findsNothing);
    });
  });
}
