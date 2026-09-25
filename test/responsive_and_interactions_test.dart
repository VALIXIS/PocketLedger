import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/core/theme/app_theme.dart';
import 'package:pocketledger/core/theme/responsive_breakpoints.dart';
import 'package:pocketledger/core/widgets/adaptive_navigation_shell.dart';
import 'package:pocketledger/core/widgets/micro_interaction.dart';
import 'package:pocketledger/core/widgets/responsive_scaffold.dart';
import 'package:pocketledger/core/widgets/tablet_navigation_rail.dart';
import 'package:pocketledger/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction.dart';
import 'package:pocketledger/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:pocketledger/features/transactions/presentation/providers/transaction_providers.dart';

class MockTransactionRepository implements TransactionRepository {
  @override
  Future<List<Transaction>> getTransactions() async => [];

  @override
  Future<void> saveTransaction(Transaction transaction) async {}

  @override
  Future<void> deleteTransaction(String id) async {}
}

void main() {
  group('ResponsiveBreakpoints and ResponsiveLayout Tests', () {
    test('classifies widths into accurate ResponsiveLayouts', () {
      expect(ResponsiveLayout.fromWidth(320), ResponsiveLayout.compactPhone);
      expect(ResponsiveLayout.fromWidth(360), ResponsiveLayout.phone);
      expect(ResponsiveLayout.fromWidth(500), ResponsiveLayout.phone);
      expect(ResponsiveLayout.fromWidth(600), ResponsiveLayout.foldable);
      expect(ResponsiveLayout.fromWidth(800), ResponsiveLayout.foldable);
      expect(ResponsiveLayout.fromWidth(840), ResponsiveLayout.tablet);
      expect(ResponsiveLayout.fromWidth(1000), ResponsiveLayout.tablet);
      expect(ResponsiveLayout.fromWidth(1024), ResponsiveLayout.desktop);
      expect(ResponsiveLayout.fromWidth(1280), ResponsiveLayout.desktop);
      expect(ResponsiveLayout.fromWidth(1440), ResponsiveLayout.wideDesktop);
      expect(ResponsiveLayout.fromWidth(1920), ResponsiveLayout.wideDesktop);
    });

    test('verifies layout helper properties', () {
      expect(ResponsiveLayout.compactPhone.isPhone, isTrue);
      expect(ResponsiveLayout.compactPhone.isCompactPhone, isTrue);
      expect(ResponsiveLayout.compactPhone.showNavigationRail, isFalse);

      expect(ResponsiveLayout.phone.isPhone, isTrue);
      expect(ResponsiveLayout.phone.showNavigationRail, isFalse);

      expect(ResponsiveLayout.foldable.isFoldable, isTrue);
      expect(ResponsiveLayout.foldable.isTabletOrLarger, isTrue);
      expect(ResponsiveLayout.foldable.showNavigationRail, isTrue);
      expect(ResponsiveLayout.foldable.isExtendedRail, isFalse);

      expect(ResponsiveLayout.tablet.isTablet, isTrue);
      expect(ResponsiveLayout.tablet.showNavigationRail, isTrue);
      expect(ResponsiveLayout.tablet.isExtendedRail, isFalse);

      expect(ResponsiveLayout.desktop.isDesktop, isTrue);
      expect(ResponsiveLayout.desktop.showNavigationRail, isTrue);
      expect(ResponsiveLayout.desktop.isExtendedRail, isTrue);

      expect(ResponsiveLayout.wideDesktop.isWideDesktop, isTrue);
      expect(ResponsiveLayout.wideDesktop.isExtendedRail, isTrue);
    });
  });

  group('InteractiveScale Tests', () {
    testWidgets('renders child and triggers onTap callback', (tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveScale(
                onTap: () => tapCount++,
                child: const Text('Tap Button'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tap Button'), findsOneWidget);

      await tester.tap(find.text('Tap Button'));
      await tester.pumpAndSettle();
      expect(tapCount, 1);
    });

    testWidgets('respects reduced-motion without animation delay', (
      tester,
    ) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: InteractiveScale(
                  onTap: () => tapCount++,
                  child: const Text('Reduced Motion Button'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Reduced Motion Button'));
      await tester.pump();
      expect(tapCount, 1);
    });
  });

  group('TabletNavigationRail Tests', () {
    testWidgets('renders 5 destinations and notifies on selection', (
      tester,
    ) async {
      int selected = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: TabletNavigationRail(
              selectedIndex: selected,
              onDestinationSelected: (index) => selected = index,
            ),
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('AI Assistant'), findsOneWidget);

      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();
      expect(selected, 1);
    });
  });

  group('AdaptiveNavigationShell Tests', () {
    testWidgets('shows NavigationBar on phone width (< 600)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: AdaptiveNavigationShell.withPlaceholders()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(TabletNavigationRail), findsNothing);
    });

    testWidgets('shows TabletNavigationRail on tablet/desktop width (>= 600)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: AdaptiveNavigationShell.withPlaceholders()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TabletNavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('preserves tab selection across navigation rail interaction', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int changedIndex = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveNavigationShell.withPlaceholders(
            onTabChanged: (index) => changedIndex = index,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();
      expect(changedIndex, 1);
    });
  });

  group('ResponsiveScaffold Tests', () {
    testWidgets('switches between bottom bar and side rail dynamically', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: ResponsiveScaffold(body: Text('Content Area'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Content Area'), findsOneWidget);
      expect(find.byType(TabletNavigationRail), findsNothing);
    });
  });

  group('DashboardPage Responsive Tests', () {
    testWidgets('renders phone single column without overflow (390 x 844)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(
              MockTransactionRepository(),
            ),
          ],
          child: const MaterialApp(home: DashboardPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NET BALANCE'), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'renders tablet/desktop multi-column without overflow (1024 x 768)',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              transactionRepositoryProvider.overrideWithValue(
                MockTransactionRepository(),
              ),
            ],
            child: const MaterialApp(home: DashboardPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('NET BALANCE'), findsOneWidget);
        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
