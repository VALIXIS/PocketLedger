import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../theme/app_theme.dart';

/// The flagship five-tab main navigation shell for PocketLedger.
///
/// Provides a Material 3 [NavigationBar], animated directional slide and fade
/// page transitions, page state preservation, accessible navigation labels,
/// and subtle haptic feedback on tab changes.
class MainNavigationShell extends StatefulWidget {
  /// The initial tab index to display (0: Dashboard, 1: Analytics, 2: Plan,
  /// 3: Search, 4: AI Assistant). Defaults to 0.
  final int initialIndex;

  /// Optional custom page list for testing, custom routing, or previews.
  /// If null, default feature screens and placeholders are used.
  final List<Widget>? screens;

  /// Optional callback invoked whenever the selected tab changes.
  final ValueChanged<int>? onTabChanged;

  final bool _useAllPlaceholders;

  /// Standard constructor integrating real feature screens where available
  /// and minimal placeholders for upcoming features (Plan, Search).
  const MainNavigationShell({
    super.key,
    this.initialIndex = 0,
    this.screens,
    this.onTabChanged,
  }) : _useAllPlaceholders = false;

  /// Factory constructor configuring lightweight standalone placeholder screens
  /// for all five tabs. Ideal for unit/widget tests and isolated UI previews.
  const MainNavigationShell.withPlaceholders({
    super.key,
    this.initialIndex = 0,
    this.onTabChanged,
  }) : screens = null,
       _useAllPlaceholders = true;

  @override
  State<MainNavigationShell> createState() => MainNavigationShellState();
}

/// State for [MainNavigationShell], exposing [currentIndex] for integration.
class MainNavigationShellState extends State<MainNavigationShell>
    with SingleTickerProviderStateMixin {
  static const int _destinationCount = 5;

  late int _currentIndex;
  late int _previousIndex;
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  late final List<Widget> _pages;
  late final List<GlobalKey> _pageKeys;

  bool _isAnimating = false;
  bool _isMovingForward = true;

  /// Currently selected tab index (0 to 4).
  int get currentIndex => _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _destinationCount - 1);
    _previousIndex = _currentIndex;

    _pageKeys = List.generate(_destinationCount, (_) => GlobalKey());

    _animationController = AnimationController(
      duration: AppTheme.animationNormal,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: AppTheme.curveDefault,
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isAnimating = false;
            _previousIndex = _currentIndex;
          });
        }
      }
    });

    _pages = widget.screens ?? _buildScreens();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Widget> _buildScreens() {
    if (widget._useAllPlaceholders) {
      return const [
        _NavigationPlaceholderScreen(
          title: 'Dashboard',
          subtitle: 'Your financial overview',
          icon: Icons.dashboard_outlined,
        ),
        _NavigationPlaceholderScreen(
          title: 'Analytics',
          subtitle: 'Understand your spending and trends',
          icon: Icons.analytics_outlined,
        ),
        _NavigationPlaceholderScreen(
          title: 'Plan',
          subtitle: 'Plan your upcoming finances',
          icon: Icons.event_note_outlined,
        ),
        _NavigationPlaceholderScreen(
          title: 'Search',
          subtitle: 'Find transactions, accounts, and insights',
          icon: Icons.search,
        ),
        _NavigationPlaceholderScreen(
          title: 'AI Assistant',
          subtitle: 'Your intelligent financial assistant',
          icon: Icons.auto_awesome_outlined,
          isAiSpecial: true,
        ),
      ];
    }

    return const [
      DashboardScreen(),
      AnalyticsScreen(),
      _NavigationPlaceholderScreen(
        title: 'Plan',
        subtitle: 'Plan your upcoming finances',
        icon: Icons.event_note_outlined,
      ),
      _NavigationPlaceholderScreen(
        title: 'Search',
        subtitle: 'Find transactions, accounts, and insights',
        icon: Icons.search,
      ),
      AIAssistantScreen(),
    ];
  }

  /// Changes the active tab index with directional animation and haptics.
  void selectTab(int newIndex) {
    if (newIndex == _currentIndex ||
        newIndex < 0 ||
        newIndex >= _destinationCount) {
      return;
    }

    // Trigger subtle haptic feedback strictly on genuine tab changes
    HapticFeedback.selectionClick();

    setState(() {
      _isMovingForward = newIndex > _currentIndex;
      _previousIndex = _currentIndex;
      _currentIndex = newIndex;
      _isAnimating = true;
    });

    widget.onTabChanged?.call(newIndex);
    _animationController.forward(from: 0.0);
  }

  Widget _buildPageWrapper(int index, Widget child) {
    return KeyedSubtree(
      key: _pageKeys[index],
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, staticChild) {
          final bool isCurrent = index == _currentIndex;
          final bool isPrevious = index == _previousIndex && _isAnimating;
          final bool isVisible = isCurrent || isPrevious;

          double opacity = 1.0;
          Offset slideOffset = Offset.zero;

          if (_isAnimating) {
            final double t = _animation.value;
            if (isCurrent) {
              opacity = t.clamp(0.0, 1.0);
              final double startDx = _isMovingForward ? 0.06 : -0.06;
              slideOffset = Offset(startDx * (1.0 - t), 0.0);
            } else if (isPrevious) {
              opacity = (1.0 - t).clamp(0.0, 1.0);
              final double endDx = _isMovingForward ? -0.06 : 0.06;
              slideOffset = Offset(endDx * t, 0.0);
            }
          }

          return Offstage(
            offstage: !isVisible,
            child: TickerMode(
              enabled: isCurrent,
              child: ExcludeFocus(
                excluding: !isCurrent,
                child: IgnorePointer(
                  ignoring: !isCurrent,
                  child: FractionalTranslation(
                    translation: slideOffset,
                    child: Opacity(opacity: opacity, child: staticChild),
                  ),
                ),
              ),
            ),
          );
        },
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Android back navigation: Non-dashboard tabs return to Dashboard first.
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          selectTab(0);
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            for (int i = 0; i < _pages.length; i++)
              _buildPageWrapper(i, _pages[i]),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: selectTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
              tooltip: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'Analytics',
              tooltip: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note),
              label: 'Plan',
              tooltip: 'Plan',
            ),
            NavigationDestination(
              icon: Icon(Icons.search),
              selectedIcon: Icon(Icons.search),
              label: 'Search',
              tooltip: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'AI Assistant',
              tooltip: 'AI Assistant',
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimal internal placeholder screen used for navigation tabs prior to their
/// dedicated sprint implementation.
class _NavigationPlaceholderScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isAiSpecial;

  const _NavigationPlaceholderScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isAiSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isAiSpecial
                        ? colorScheme.primary.withValues(alpha: 0.15)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.radius20),
                    border: Border.all(
                      color: isAiSpecial
                          ? colorScheme.primary.withValues(alpha: 0.3)
                          : colorScheme.outline.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 36,
                    color: isAiSpecial
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.space20),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
