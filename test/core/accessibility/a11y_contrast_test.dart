import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/core/accessibility/a11y_colors.dart';
import 'package:pocketledger/core/accessibility/accessible_date_picker.dart';
import 'package:pocketledger/core/accessibility/accessible_dialog.dart';
import 'package:pocketledger/core/accessibility/accessible_text_form_field.dart';
import 'package:pocketledger/core/theme/app_theme.dart';

void main() {
  group('WCAG AAA Contrast Calculations & Token Verification', () {
    test('Calculates relative luminance correctly', () {
      expect(
        A11yColors.calculateRelativeLuminance(Colors.white),
        closeTo(1.0, 0.01),
      );
      expect(
        A11yColors.calculateRelativeLuminance(Colors.black),
        closeTo(0.0, 0.01),
      );
    });

    test('Computes contrast ratio accurately', () {
      final ratio = A11yColors.calculateContrastRatio(
        Colors.white,
        Colors.black,
      );
      expect(ratio, closeTo(21.0, 0.1));
    });

    test(
      'Verifies WCAG AAA contrast for Light mode tokens on white background',
      () {
        const bg = A11yColors.lightBackground;

        // Normal text requires >= 7.0:1 for WCAG AAA
        final textRatio = A11yColors.calculateContrastRatio(
          A11yColors.lightTextPrimary,
          bg,
        );
        expect(
          textRatio,
          greaterThanOrEqualTo(7.0),
          reason:
              'Light textPrimary ($textRatio:1) must meet WCAG AAA >= 7.0:1',
        );

        final purpleRatio = A11yColors.calculateContrastRatio(
          A11yColors.lightPurple,
          bg,
        );
        expect(
          purpleRatio,
          greaterThanOrEqualTo(7.0),
          reason:
              'Light primaryPurple ($purpleRatio:1) must meet WCAG AAA >= 7.0:1',
        );

        final blueRatio = A11yColors.calculateContrastRatio(
          A11yColors.lightBlue,
          bg,
        );
        expect(
          blueRatio,
          greaterThanOrEqualTo(7.0),
          reason:
              'Light primaryBlue ($blueRatio:1) must meet WCAG AAA >= 7.0:1',
        );

        final errorRatio = A11yColors.calculateContrastRatio(
          A11yColors.lightError,
          bg,
        );
        expect(
          errorRatio,
          greaterThanOrEqualTo(7.0),
          reason: 'Light error ($errorRatio:1) must meet WCAG AAA >= 7.0:1',
        );

        // Secondary text and component borders meet WCAG AA/AAA thresholds
        final secondaryRatio = A11yColors.calculateContrastRatio(
          A11yColors.lightTextSecondary,
          bg,
        );
        expect(
          secondaryRatio,
          greaterThanOrEqualTo(4.5),
          reason: 'Light textSecondary ($secondaryRatio:1) must meet >= 4.5:1',
        );

        final borderRatio = A11yColors.calculateContrastRatio(
          A11yColors.lightBorder,
          bg,
        );
        expect(
          borderRatio,
          greaterThanOrEqualTo(3.0),
          reason:
              'Light border ($borderRatio:1) must meet UI component >= 3.0:1',
        );
      },
    );

    test(
      'Verifies WCAG AAA contrast for Dark mode tokens on dark background',
      () {
        const bg = A11yColors.darkBackground;

        // Normal text requires >= 7.0:1 for WCAG AAA
        final textRatio = A11yColors.calculateContrastRatio(
          A11yColors.darkTextPrimary,
          bg,
        );
        expect(
          textRatio,
          greaterThanOrEqualTo(7.0),
          reason: 'Dark textPrimary ($textRatio:1) must meet WCAG AAA >= 7.0:1',
        );

        final purpleRatio = A11yColors.calculateContrastRatio(
          A11yColors.darkPurple,
          bg,
        );
        expect(
          purpleRatio,
          greaterThanOrEqualTo(7.0),
          reason:
              'Dark primaryPurple ($purpleRatio:1) must meet WCAG AAA >= 7.0:1',
        );

        final blueRatio = A11yColors.calculateContrastRatio(
          A11yColors.darkBlue,
          bg,
        );
        expect(
          blueRatio,
          greaterThanOrEqualTo(7.0),
          reason: 'Dark primaryBlue ($blueRatio:1) must meet WCAG AAA >= 7.0:1',
        );

        final errorRatio = A11yColors.calculateContrastRatio(
          A11yColors.darkError,
          bg,
        );
        expect(
          errorRatio,
          greaterThanOrEqualTo(7.0),
          reason: 'Dark error ($errorRatio:1) must meet WCAG AAA >= 7.0:1',
        );

        final secondaryRatio = A11yColors.calculateContrastRatio(
          A11yColors.darkTextSecondary,
          bg,
        );
        expect(
          secondaryRatio,
          greaterThanOrEqualTo(4.5),
          reason: 'Dark textSecondary ($secondaryRatio:1) must meet >= 4.5:1',
        );

        final borderRatio = A11yColors.calculateContrastRatio(
          A11yColors.darkBorder,
          bg,
        );
        expect(
          borderRatio,
          greaterThanOrEqualTo(3.0),
          reason:
              'Dark border ($borderRatio:1) must meet UI component >= 3.0:1',
        );
      },
    );

    test(
      'Verifies OLED mode tokens maintain ultra-high contrast on black background',
      () {
        const bg = A11yColors.oledBackground;

        final textRatio = A11yColors.calculateContrastRatio(
          A11yColors.darkTextPrimary,
          bg,
        );
        expect(
          textRatio,
          greaterThanOrEqualTo(15.0),
          reason: 'OLED textPrimary ($textRatio:1) must exceed 15.0:1',
        );

        final borderRatio = A11yColors.calculateContrastRatio(
          A11yColors.oledBorder,
          bg,
        );
        expect(
          borderRatio,
          greaterThanOrEqualTo(3.0),
          reason:
              'OLED border ($borderRatio:1) must meet UI component >= 3.0:1',
        );
      },
    );
  });

  group('AccessibilityTheme ThemeData Integration', () {
    test('AppTheme produces themes hardened by AccessibilityTheme', () {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;
      final oledTheme = AppTheme.oledTheme;

      expect(lightTheme.inputDecorationTheme.enabledBorder, isNotNull);
      expect(darkTheme.inputDecorationTheme.enabledBorder, isNotNull);
      expect(oledTheme.inputDecorationTheme.enabledBorder, isNotNull);

      // Check dialog themes have accessible properties
      expect(
        lightTheme.dialogTheme.titleTextStyle?.fontWeight,
        FontWeight.w700,
      );
      expect(darkTheme.dialogTheme.titleTextStyle?.fontWeight, FontWeight.w700);
    });
  });

  group('AccessibleTextFormField Widget & Large Text Scaling', () {
    testWidgets(
      'renders correctly and enforces minimum 48dp height constraint',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16.0),
                child: AccessibleTextFormField(
                  label: 'Account Name',
                  hint: 'Enter name',
                  isRequired: true,
                  semanticLabel: 'Enter your bank account name',
                ),
              ),
            ),
          ),
        );

        expect(find.text('Account Name *'), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);

        final box =
            tester.renderObject(find.byType(AccessibleTextFormField))
                as RenderBox;
        expect(box.size.height, greaterThanOrEqualTo(48.0));
      },
    );

    testWidgets(
      'supports large text scale factors (1.5x and 2.0x) without overflow',
      (tester) async {
        for (final scale in [1.0, 1.5, 2.0]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: const Scaffold(
                  body: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          AccessibleTextFormField(
                            label: 'Amount',
                            hint: '0.00',
                            isRequired: true,
                          ),
                          SizedBox(height: 16),
                          AccessibleTextFormField(
                            label: 'Notes',
                            hint: 'Optional notes',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'Should not throw layout exceptions at scale $scale',
          );
        }
      },
    );
  });

  group('Accessible Dialog & Date Picker Invocations', () {
    testWidgets(
      'showAccessibleAlertDialog renders with high contrast and dismisses cleanly',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showAccessibleAlertDialog(
                      context: context,
                      title: 'Confirm Action',
                      contentText: 'This is an accessible message.',
                      isDestructive: true,
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ],
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Confirm Action'), findsOneWidget);
        expect(find.text('This is an accessible message.'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

        // Dismiss dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Confirm Action'), findsNothing);
      },
    );

    testWidgets(
      'showAccessibleDatePicker displays accessible calendar dialog',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showAccessibleDatePicker(
                      context: context,
                      initialDate: DateTime(2025, 1, 15),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                  },
                  child: const Text('Open Date Picker'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Date Picker'));
        await tester.pumpAndSettle();

        expect(find.byType(DatePickerDialog), findsOneWidget);
        expect(find.text('Select Date'), findsOneWidget);

        // Dismiss
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsNothing);
      },
    );
  });
}
