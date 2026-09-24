import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget_alert.dart';
import 'package:pocketledger/features/budgets/presentation/widgets/budget_alert_banner.dart';

void main() {
  BudgetAlert createTestAlert({
    required String id,
    required String name,
    required BudgetAlertLevel level,
    required double percentage,
    required String message,
  }) {
    return BudgetAlert(
      budgetId: id,
      budgetName: name,
      categoryId: 'cat1',
      level: level,
      spentInCents: (10000 * (percentage / 100)).round(),
      amountInCents: 10000,
      remainingInCents: 10000 - (10000 * (percentage / 100)).round(),
      percentageSpent: percentage,
      message: message,
    );
  }

  Widget createWidgetUnderTest(Widget widget) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16.0), child: widget),
        ),
      ),
    );
  }

  group('BudgetAlertBanner Widget Tests', () {
    testWidgets('1. Renders warning alert banner with badge text WARNING 75%', (
      tester,
    ) async {
      final alert = createTestAlert(
        id: 'b1',
        name: 'Dining',
        level: BudgetAlertLevel.warning,
        percentage: 78.0,
        message: 'Dining budget warning! Spent \$78.00 of \$100.00 (78.0%)',
      );

      await tester.pumpWidget(
        createWidgetUnderTest(BudgetAlertBanner(alert: alert)),
      );
      await tester.pumpAndSettle();

      expect(find.text('WARNING 75%'), findsOneWidget);
      expect(find.text('Dining'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('2. Renders danger alert banner with badge text DANGER 90%', (
      tester,
    ) async {
      final alert = createTestAlert(
        id: 'b2',
        name: 'Travel',
        level: BudgetAlertLevel.danger,
        percentage: 92.0,
        message: 'Travel budget critical! Spent \$92.00 of \$100.00 (92.0%)',
      );

      await tester.pumpWidget(
        createWidgetUnderTest(BudgetAlertBanner(alert: alert)),
      );
      await tester.pumpAndSettle();

      expect(find.text('DANGER 90%'), findsOneWidget);
      expect(find.text('Travel'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets(
      '3. Renders exceeded alert banner with badge text EXCEEDED 100%',
      (tester) async {
        final alert = createTestAlert(
          id: 'b3',
          name: 'Groceries',
          level: BudgetAlertLevel.exceeded,
          percentage: 110.0,
          message:
              'Groceries budget exceeded! Spent \$110.00 of \$100.00 (110.0%)',
        );

        await tester.pumpWidget(
          createWidgetUnderTest(BudgetAlertBanner(alert: alert)),
        );
        await tester.pumpAndSettle();

        expect(find.text('EXCEEDED 100%'), findsOneWidget);
        expect(find.text('Groceries'), findsOneWidget);
        expect(find.byIcon(Icons.gpp_maybe_rounded), findsOneWidget);
      },
    );

    testWidgets('4. Displays message and LinearProgressIndicator', (
      tester,
    ) async {
      final alert = createTestAlert(
        id: 'b1',
        name: 'Bills',
        level: BudgetAlertLevel.warning,
        percentage: 80.0,
        message: 'Bills budget warning!',
      );

      await tester.pumpWidget(
        createWidgetUnderTest(BudgetAlertBanner(alert: alert)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bills budget warning!'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('5. Triggers onDismiss callback when close button is tapped', (
      tester,
    ) async {
      bool dismissed = false;
      final alert = createTestAlert(
        id: 'b1',
        name: 'Shopping',
        level: BudgetAlertLevel.warning,
        percentage: 85.0,
        message: 'Warning',
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          BudgetAlertBanner(
            alert: alert,
            onDismiss: () {
              dismissed = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dismissBtn = find.byKey(const Key('dismiss_alert_b1'));
      expect(dismissBtn, findsOneWidget);

      await tester.tap(dismissBtn);
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('6. Triggers onTap callback when banner card is tapped', (
      tester,
    ) async {
      bool tapped = false;
      final alert = createTestAlert(
        id: 'b1',
        name: 'Shopping',
        level: BudgetAlertLevel.danger,
        percentage: 95.0,
        message: 'Critical',
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          BudgetAlertBanner(
            alert: alert,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('7. BudgetAlertSection renders multiple active alert banners', (
      tester,
    ) async {
      final alerts = [
        createTestAlert(
          id: 'a1',
          name: 'Alert 1',
          level: BudgetAlertLevel.exceeded,
          percentage: 105.0,
          message: 'Exceeded',
        ),
        createTestAlert(
          id: 'a2',
          name: 'Alert 2',
          level: BudgetAlertLevel.warning,
          percentage: 80.0,
          message: 'Warning',
        ),
      ];

      await tester.pumpWidget(
        createWidgetUnderTest(BudgetAlertSection(alerts: alerts)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BudgetAlertBanner), findsNWidgets(2));
      expect(find.text('Alert 1'), findsOneWidget);
      expect(find.text('Alert 2'), findsOneWidget);
    });

    testWidgets(
      '8. BudgetAlertSection renders empty widget when alerts list is empty',
      (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(const BudgetAlertSection(alerts: [])),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BudgetAlertBanner), findsNothing);
        expect(find.byKey(const Key('budget_alert_section')), findsNothing);
      },
    );

    testWidgets(
      '9. BudgetAlertSection displays total count of active alerts in header text',
      (tester) async {
        final alerts = [
          createTestAlert(
            id: 'a1',
            name: 'A1',
            level: BudgetAlertLevel.danger,
            percentage: 92.0,
            message: 'D1',
          ),
          createTestAlert(
            id: 'a2',
            name: 'A2',
            level: BudgetAlertLevel.warning,
            percentage: 76.0,
            message: 'W1',
          ),
        ];

        await tester.pumpWidget(
          createWidgetUnderTest(BudgetAlertSection(alerts: alerts)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Active Budget Alerts (2)'), findsOneWidget);
      },
    );

    testWidgets(
      '10. Renders correctly without dismiss button when onDismiss is null',
      (tester) async {
        final alert = createTestAlert(
          id: 'b1',
          name: 'Utilities',
          level: BudgetAlertLevel.warning,
          percentage: 82.0,
          message: 'Warning',
        );

        await tester.pumpWidget(
          createWidgetUnderTest(BudgetAlertBanner(alert: alert)),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('dismiss_alert_b1')), findsNothing);
      },
    );
  });
}
