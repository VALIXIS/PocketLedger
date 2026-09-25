import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_breakpoints.dart';
import 'tablet_navigation_rail.dart';

/// An adaptive, responsive layout shell that transitions smoothly between
/// a phone bottom [NavigationBar] and a tablet/desktop side [NavigationRail].
class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final double maxContentWidth;
  final bool constrainBody;
  final Widget? customRail;
  final Widget? customNavigationBar;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.maxContentWidth = ResponsiveBreakpoints.maxContentWidth,
    this.constrainBody = false,
    this.customRail,
    this.customNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOled =
        isDark &&
        (theme.scaffoldBackgroundColor == AppColors.oledBackground ||
            theme.scaffoldBackgroundColor == Colors.black);

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = ResponsiveLayout.fromWidth(constraints.maxWidth);
        final showRail = layout.showNavigationRail;

        Widget content = body;
        if (constrainBody) {
          content = Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: content,
            ),
          );
        }

        if (showRail) {
          final isExtended = layout.isExtendedRail;

          final rail =
              customRail ??
              TabletNavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected ?? (_) {},
                isExtended: isExtended,
              );

          final dividerColor = isOled
              ? AppColors.oledBorder
              : isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06);

          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                rail,
                VerticalDivider(width: 1, thickness: 1, color: dividerColor),
                Expanded(child: content),
              ],
            ),
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: floatingActionButtonLocation,
          );
        }

        // Phone Layout with bottom navigation bar
        return Scaffold(
          appBar: appBar,
          body: content,
          bottomNavigationBar: customNavigationBar,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
        );
      },
    );
  }
}
