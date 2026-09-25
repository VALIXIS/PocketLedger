import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Centralized responsive device classifications for PocketLedger.
///
/// Categorizes available screen width into logical ranges rather than making
/// device-name or platform assumptions.
enum ResponsiveLayout {
  /// Compact phone layouts (< 360px width, e.g. small older devices).
  compactPhone,

  /// Standard phone layouts (360–599px width).
  phone,

  /// Foldable unfolded or small tablet layouts (600–839px width).
  foldable,

  /// Standard tablet or small laptop layouts (840–1023px width).
  tablet,

  /// Desktop and large tablet landscape layouts (1024–1439px width).
  desktop,

  /// Wide desktop and 4K displays (1440px+ width).
  wideDesktop;

  /// Resolves the layout classification from the given logical width.
  static ResponsiveLayout fromWidth(double width) {
    if (width < ResponsiveBreakpoints.compactPhone) {
      return ResponsiveLayout.compactPhone;
    } else if (width < ResponsiveBreakpoints.foldable) {
      return ResponsiveLayout.phone;
    } else if (width < ResponsiveBreakpoints.largeTablet) {
      return ResponsiveLayout.foldable;
    } else if (width < ResponsiveBreakpoints.desktop) {
      return ResponsiveLayout.tablet;
    } else if (width < ResponsiveBreakpoints.wideDesktop) {
      return ResponsiveLayout.desktop;
    } else {
      return ResponsiveLayout.wideDesktop;
    }
  }

  /// Whether width represents a phone layout (< 600px).
  bool get isPhone =>
      this == ResponsiveLayout.compactPhone || this == ResponsiveLayout.phone;

  /// Whether width represents a compact phone (< 360px).
  bool get isCompactPhone => this == ResponsiveLayout.compactPhone;

  /// Whether width represents a foldable or small tablet layout (600–839px).
  bool get isFoldable => this == ResponsiveLayout.foldable;

  /// Whether width represents a standard tablet layout (840–1023px).
  bool get isTablet => this == ResponsiveLayout.tablet;

  /// Whether width represents tablet, foldable, or desktop width (>= 600px).
  bool get isTabletOrLarger => !isPhone;

  /// Whether width represents a desktop display (>= 1024px).
  bool get isDesktop =>
      this == ResponsiveLayout.desktop || this == ResponsiveLayout.wideDesktop;

  /// Whether width represents a wide desktop display (>= 1440px).
  bool get isWideDesktop => this == ResponsiveLayout.wideDesktop;

  /// Whether the navigation shell should display a side [NavigationRail] instead of bottom [NavigationBar].
  bool get showNavigationRail => isTabletOrLarger;

  /// Whether the side [NavigationRail] should automatically show full text labels.
  bool get isExtendedRail => isDesktop;
}

/// Centralized responsive layout constants and helper methods.
abstract final class ResponsiveBreakpoints {
  /// Compact phone width boundary (< 360px).
  static const double compactPhone = 360.0;

  /// Phone to foldable/tablet boundary (600px).
  static const double foldable = AppBreakpoints.tablet; // 600.0

  /// Large tablet boundary (840px).
  static const double largeTablet = 840.0;

  /// Desktop width boundary (1024px).
  static const double desktop = AppBreakpoints.desktop; // 1024.0

  /// Wide desktop width boundary (1440px).
  static const double wideDesktop = AppBreakpoints.wideDesktop; // 1440.0

  /// Maximum content constraint to prevent excessive stretching on wide screens.
  static const double maxContentWidth =
      AppBreakpoints.maxContentWidth; // 1280.0

  /// Resolves the active [ResponsiveLayout] from the provided [BuildContext].
  static ResponsiveLayout of(BuildContext context) {
    return ResponsiveLayout.fromWidth(MediaQuery.sizeOf(context).width);
  }

  /// Resolves the [ResponsiveLayout] from [BoxConstraints].
  static ResponsiveLayout fromConstraints(BoxConstraints constraints) {
    return ResponsiveLayout.fromWidth(constraints.maxWidth);
  }
}

/// Convenience extension on [BuildContext] for responsive layout inspection.
extension ResponsiveContext on BuildContext {
  /// Active responsive device classification based on logical width.
  ResponsiveLayout get responsiveLayout => ResponsiveBreakpoints.of(this);

  /// True if current width is in the phone range (< 600px).
  bool get isPhone => responsiveLayout.isPhone;

  /// True if current width is in the compact phone range (< 360px).
  bool get isCompactPhone => responsiveLayout.isCompactPhone;

  /// True if current width is in the foldable range (600–839px).
  bool get isFoldable => responsiveLayout.isFoldable;

  /// True if current width is in the tablet range (840–1023px).
  bool get isTablet => responsiveLayout.isTablet;

  /// True if current width is tablet, foldable, or desktop (>= 600px).
  bool get isTabletOrLarger => responsiveLayout.isTabletOrLarger;

  /// True if current width is in the desktop or wide desktop range (>= 1024px).
  bool get isDesktop => responsiveLayout.isDesktop;

  /// True if side [NavigationRail] should be used instead of bottom [NavigationBar].
  bool get showNavigationRail => responsiveLayout.showNavigationRail;
}
