import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_breakpoints.dart';
import 'tablet_navigation_rail.dart';

/// The flagship adaptive navigation shell for PocketLedger.
///
/// Automatically switches between a bottom [NavigationBar] (phone < 600px)
/// and a side [TabletNavigationRail] (tablet/desktop >= 600px) based on available
/// logical width, while preserving tab state, directional slide/fade transitions,
/// back navigation semantics, and haptic feedback.
class AdaptiveNavigationShell extends StatefulWidget {
  final int initialIndex;
  final List<Widget>? screens;
  final ValueChanged<int>? onTabChanged;
  final bool _useAllPlaceholders;

  const AdaptiveNavigationShell({
    super.key,
    this.initialIndex = 0,
    this.screens,
    this.onTabChanged,
  }) : _useAllPlaceholders = false;

  const AdaptiveNavigationShell.withPlaceholders({
    super.key,
    this.initialIndex = 0,
    this.onTabChanged,
  }) : screens = null,
       _useAllPlaceholders = true;

  @override
  State<AdaptiveNavigationShell> createState() =>
      AdaptiveNavigationShellState();
}

class AdaptiveNavigationShellState extends State<AdaptiveNavigationShell>
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
        _AdaptiveNavigationPlaceholder(
          title: 'Dashboard',
          subtitle: 'Your financial overview',
          icon: Icons.dashboard_outlined,
        ),
        _AdaptiveNavigationPlaceholder(
          title: 'Analytics',
          subtitle: 'Understand your spending and trends',
          icon: Icons.analytics_outlined,
        ),
        _AdaptiveNavigationPlaceholder(
          title: 'Plan',
          subtitle: 'Plan your upcoming finances',
          icon: Icons.event_note_outlined,
        ),
        _AdaptiveNavigationPlaceholder(
          title: 'Search',
          subtitle: 'Find transactions, accounts, and insights',
          icon: Icons.search,
        ),
        _AdaptiveNavigationPlaceholder(
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
      _AdaptiveNavigationPlaceholder(
        title: 'Plan',
        subtitle: 'Plan your upcoming finances',
        icon: Icons.event_note_outlined,
      ),
      _AdaptiveNavigationPlaceholder(
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

    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    setState(() {
      _isMovingForward = newIndex > _currentIndex;
      _previousIndex = _currentIndex;
      _currentIndex = newIndex;
      _isAnimating = !disableAnimations;
    });

    widget.onTabChanged?.call(newIndex);

    if (!disableAnimations) {
      _animationController.forward(from: 0.0);
    } else {
      _isAnimating = false;
      _previousIndex = _currentIndex;
    }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOled =
        isDark &&
        (theme.scaffoldBackgroundColor == AppColors.oledBackground ||
            theme.scaffoldBackgroundColor == Colors.black);

    final dividerColor = isOled
        ? AppColors.oledBorder
        : isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final pageStack = Stack(
      fit: StackFit.expand,
      children: [
        for (int i = 0; i < _pages.length; i++) _buildPageWrapper(i, _pages[i]),
      ],
    );

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          selectTab(0);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = ResponsiveLayout.fromWidth(constraints.maxWidth);
          final showRail = layout.showNavigationRail;

          if (showRail) {
            return Scaffold(
              body: Row(
                children: [
                  TabletNavigationRail(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: selectTab,
                    isExtended: layout.isExtendedRail,
                  ),
                  VerticalDivider(width: 1, thickness: 1, color: dividerColor),
                  Expanded(child: pageStack),
                ],
              ),
            );
          }

          // Phone layout with bottom NavigationBar
          return Scaffold(
            body: pageStack,
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
          );
        },
      ),
    );
  }
}

class _AdaptiveNavigationPlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isAiSpecial;

  const _AdaptiveNavigationPlaceholder({
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
