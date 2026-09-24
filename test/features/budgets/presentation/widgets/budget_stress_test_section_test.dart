import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/budgets/presentation/widgets/budget_stress_test_section.dart';

void main() {
  Widget createWidgetUnderTest({
    required int allocationInCents,
    required int currentSpendingInCents,
  }) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BudgetStressTestSection(
              allocationInCents: allocationInCents,
              currentSpendingInCents: currentSpendingInCents,
            ),
          ),
        ),
      ),
    );
  }

  group('BudgetStressTestSection Widget Tests', () {
    testWidgets(
      '1. Stress Test section renders with initial moderate scenario selected',
      (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            allocationInCents: 1000000, // $10,000.00
            currentSpendingInCents: 800000, // $8,000.00
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Budget Stress Test'), findsOneWidget);
        expect(
          find.byKey(const Key('budget_stress_test_section')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('scenario_chip_moderate')), findsOneWidget);
      },
    );

    testWidgets(
      '2. Scenario selector chip updates selected scenario and calculations',
      (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            allocationInCents: 1000000, // $10,000.00
            currentSpendingInCents: 400000, // $4,000.00
          ),
        );
        await tester.pumpAndSettle();

        // Tap Extreme (+50%) scenario chip
        final extremeChip = find.byKey(const Key('scenario_chip_extreme'));
        expect(extremeChip, findsOneWidget);

        await tester.tap(extremeChip);
        await tester.pumpAndSettle();

        // $4,000 + 50% = $6,000.00
        expect(find.text('\$6000.00'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Exceeded state status badge is rendered when stress exceeds budget',
      (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            allocationInCents: 1000000, // $10,000.00
            currentSpendingInCents: 900000, // $9,000.00 + 20% = $10,800.00
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('EXCEEDED'), findsOneWidget);
        expect(find.text('Over by \$800.00'), findsOneWidget);
      },
    );

    testWidgets('4. LinearProgressIndicator renders utilization progress bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          allocationInCents: 1000000,
          currentSpendingInCents: 500000,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets(
      '5. Satisfies responsive layout boundaries without overflowing',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createWidgetUnderTest(
            allocationInCents: 1000000,
            currentSpendingInCents: 500000,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
