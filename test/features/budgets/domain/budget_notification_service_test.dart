import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget_alert.dart';
import 'package:pocketledger/features/budgets/domain/services/budget_notification_service.dart';

void main() {
  group('BudgetNotificationService Unit Tests', () {
    late BudgetNotificationService service;

    setUp(() {
      service = BudgetNotificationService();
    });

    BudgetAlert createAlert({
      required String budgetId,
      required BudgetAlertLevel level,
      double percentage = 80.0,
    }) {
      return BudgetAlert(
        budgetId: budgetId,
        budgetName: 'Test Budget',
        categoryId: 'cat1',
        level: level,
        spentInCents: 8000,
        amountInCents: 10000,
        remainingInCents: 2000,
        percentageSpent: percentage,
        message: 'Alert message',
      );
    }

    test(
      '1. Initial state transition from none to warning emits notification',
      () {
        final alert = createAlert(
          budgetId: 'b1',
          level: BudgetAlertLevel.warning,
          percentage: 76.0,
        );

        final payload = service.processAlert(alert);

        expect(payload, isNotNull);
        expect(payload!.alert.budgetId, equals('b1'));
        expect(payload.previousLevel, equals(BudgetAlertLevel.none));
        expect(payload.alert.level, equals(BudgetAlertLevel.warning));
        expect(service.notificationLog.length, equals(1));
      },
    );

    test(
      '2. Staying in warning (75% to 80%) emits NO new notification (deduplicated)',
      () {
        final alert1 = createAlert(
          budgetId: 'b1',
          level: BudgetAlertLevel.warning,
          percentage: 76.0,
        );
        final alert2 = createAlert(
          budgetId: 'b1',
          level: BudgetAlertLevel.warning,
          percentage: 80.0,
        );

        final payload1 = service.processAlert(alert1);
        final payload2 = service.processAlert(alert2);

        expect(payload1, isNotNull);
        expect(payload2, isNull); // Deduplicated!
        expect(service.notificationLog.length, equals(1));
      },
    );

    test('3. Escalation from warning to danger emits notification', () {
      final warningAlert = createAlert(
        budgetId: 'b1',
        level: BudgetAlertLevel.warning,
        percentage: 80.0,
      );
      final dangerAlert = createAlert(
        budgetId: 'b1',
        level: BudgetAlertLevel.danger,
        percentage: 92.0,
      );

      service.processAlert(warningAlert);
      final dangerPayload = service.processAlert(dangerAlert);

      expect(dangerPayload, isNotNull);
      expect(dangerPayload!.previousLevel, equals(BudgetAlertLevel.warning));
      expect(dangerPayload.alert.level, equals(BudgetAlertLevel.danger));
      expect(service.notificationLog.length, equals(2));
    });

    test('4. Escalation from danger to exceeded emits notification', () {
      final dangerAlert = createAlert(
        budgetId: 'b1',
        level: BudgetAlertLevel.danger,
        percentage: 95.0,
      );
      final exceededAlert = createAlert(
        budgetId: 'b1',
        level: BudgetAlertLevel.exceeded,
        percentage: 105.0,
      );

      service.processAlert(dangerAlert);
      final exceededPayload = service.processAlert(exceededAlert);

      expect(exceededPayload, isNotNull);
      expect(exceededPayload!.previousLevel, equals(BudgetAlertLevel.danger));
      expect(exceededPayload.alert.level, equals(BudgetAlertLevel.exceeded));
    });

    test('5. Staying in exceeded (105% to 120%) emits NO new notification', () {
      final exceeded1 = createAlert(
        budgetId: 'b1',
        level: BudgetAlertLevel.exceeded,
        percentage: 105.0,
      );
      final exceeded2 = createAlert(
        budgetId: 'b1',
        level: BudgetAlertLevel.exceeded,
        percentage: 120.0,
      );

      service.processAlert(exceeded1);
      final secondPayload = service.processAlert(exceeded2);

      expect(secondPayload, isNull);
      expect(service.notificationLog.length, equals(1));
    });

    test(
      '6. De-escalation to none (refund) resets tracking state without emitting notification',
      () {
        final warningAlert = createAlert(
          budgetId: 'b1',
          level: BudgetAlertLevel.warning,
          percentage: 80.0,
        );
        final noneAlert = createAlert(
          budgetId: 'b1',
          level: BudgetAlertLevel.none,
          percentage: 50.0,
        );

        service.processAlert(warningAlert);
        final nonePayload = service.processAlert(noneAlert);

        expect(nonePayload, isNull);
        expect(
          service.getLastNotifiedLevel('b1'),
          equals(BudgetAlertLevel.none),
        );
      },
    );

    test(
      '7. Re-crossing warning threshold after de-escalation emits new notification',
      () {
        final warning1 = createAlert(
          budgetId: 'b1',
          level: BudgetAlertLevel.warning,
          percentage: 80.0,
        );
        final noneAlert = createAlert(
          budgetId: 'b1',
          level: BudgetAlertLevel.none,
          percentage: 50.0,
        );
        final warning2 = createAlert(
          budgetId: 'b1',
          level: BudgetAlertLevel.warning,
          percentage: 78.0,
        );

        service.processAlert(warning1);
        service.processAlert(noneAlert);
        final reWarningPayload = service.processAlert(warning2);

        expect(reWarningPayload, isNotNull);
        expect(reWarningPayload!.previousLevel, equals(BudgetAlertLevel.none));
        expect(reWarningPayload.alert.level, equals(BudgetAlertLevel.warning));
      },
    );

    test(
      '8. Direct transition from none to exceeded (0% to 110%) emits notification',
      () {
        final exceededAlert = createAlert(
          budgetId: 'b1',
          level: BudgetAlertLevel.exceeded,
          percentage: 110.0,
        );

        final payload = service.processAlert(exceededAlert);

        expect(payload, isNotNull);
        expect(payload!.previousLevel, equals(BudgetAlertLevel.none));
        expect(payload.alert.level, equals(BudgetAlertLevel.exceeded));
      },
    );

    test('9. Independent state tracking across multiple budgets', () {
      final alertB1 = createAlert(
        budgetId: 'b1',
        level: BudgetAlertLevel.warning,
      );
      final alertB2 = createAlert(
        budgetId: 'b2',
        level: BudgetAlertLevel.danger,
      );

      final emitted = service.processAlerts([alertB1, alertB2]);

      expect(emitted.length, equals(2));
      expect(
        service.getLastNotifiedLevel('b1'),
        equals(BudgetAlertLevel.warning),
      );
      expect(
        service.getLastNotifiedLevel('b2'),
        equals(BudgetAlertLevel.danger),
      );
    });

    test('10. clearHistory resets notification tracking and log', () {
      final alert = createAlert(
        budgetId: 'b1',
        level: BudgetAlertLevel.warning,
      );
      service.processAlert(alert);

      expect(service.notificationLog.length, equals(1));

      service.clearHistory();

      expect(service.notificationLog, isEmpty);
      expect(service.getLastNotifiedLevel('b1'), equals(BudgetAlertLevel.none));
    });
  });
}
