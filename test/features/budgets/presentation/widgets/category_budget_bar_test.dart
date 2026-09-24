import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/budgets/presentation/widgets/category_budget_bar.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }

  group('CategoryBudgetBar Widget Tests', () {
    testWidgets('10. Correct progress below 100%', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CategoryBudgetBar(
            title: 'Food & Dining',
            spentInCents: 5000, // 50.00
            allocatedInCents: 10000, // 100.00
          ),
        ),
      );

      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('₹50.00 / ₹100.00'), findsOneWidget);
      expect(find.text('₹50.00 left'), findsOneWidget);

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, equals(0.5));
    });

    testWidgets('11. Progress is capped at 100% when overspent', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CategoryBudgetBar(
            title: 'Shopping',
            spentInCents: 15000, // 150.00
            allocatedInCents: 10000, // 100.00
          ),
        ),
      );

      expect(find.text('Shopping'), findsOneWidget);
      expect(find.text('₹150.00 / ₹100.00'), findsOneWidget);
      expect(find.text('Over by ₹50.00'), findsOneWidget);

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, equals(1.0));
    });

    testWidgets('12. Zero budget does not divide by zero', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CategoryBudgetBar(
            title: 'Empty Budget',
            spentInCents: 0,
            allocatedInCents: 0,
          ),
        ),
      );

      expect(find.text('Empty Budget'), findsOneWidget);
      expect(find.text('₹0.00 / ₹0.00'), findsOneWidget);

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, equals(0.0));
    });

    testWidgets('13. Remaining amount is displayed correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CategoryBudgetBar(
            title: 'Utilities',
            spentInCents: 2500, // 25.00
            allocatedInCents: 10000, // 100.00
          ),
        ),
      );

      expect(find.text('₹75.00 left'), findsOneWidget);
    });
  });
}
