import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utilities/currency_formatter.dart';

/// An accessible, performant animated balance counter for financial dashboards.
///
/// Interpolates smoothly between values using [TweenAnimationBuilder], supports
/// both positive and negative values, and automatically respects user
/// reduced-motion preferences via [MediaQuery.disableAnimations].
class AnimatedBalanceCounter extends StatelessWidget {
  /// The target balance in cents (e.g. 12500000 for ₹1,25,000.00).
  final int balanceInCents;

  /// Optional previous balance to animate from. If null, animates from 0 on first build.
  final int? previousBalanceInCents;

  /// The active currency code (e.g. 'INR', 'USD', 'EUR').
  final String currency;

  /// Custom text style for the counter.
  final TextStyle? style;

  /// Duration of the number interpolation animation. Defaults to 750ms.
  final Duration duration;

  /// Curve for the balance interpolation animation.
  final Curve curve;

  /// Optional prefix to display before the formatted balance.
  final String? prefix;

  const AnimatedBalanceCounter({
    super.key,
    required this.balanceInCents,
    this.previousBalanceInCents,
    this.currency = 'INR',
    this.style,
    this.duration = const Duration(milliseconds: 750),
    this.curve = AppTheme.curveDecelerate,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final effectiveStyle = (style ?? defaultStyle)?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final formattedFinal = CurrencyFormatter.formatCents(
      balanceInCents,
      currency,
    );
    final fullSemanticLabel = prefix != null
        ? '$prefix $formattedFinal'
        : formattedFinal;

    // Accessibility: Respect reduced motion settings immediately
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      return Semantics(
        label: fullSemanticLabel,
        value: formattedFinal,
        excludeSemantics: true,
        child: Text(
          formattedFinal,
          style: effectiveStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final double startVal = (previousBalanceInCents ?? balanceInCents)
        .toDouble();
    final double endVal = balanceInCents.toDouble();

    return Semantics(
      label: fullSemanticLabel,
      value: formattedFinal,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: startVal, end: endVal),
        duration: duration,
        curve: curve,
        builder: (context, currentCents, child) {
          final formattedCurrent = CurrencyFormatter.formatCents(
            currentCents.round(),
            currency,
          );
          return Text(
            formattedCurrent,
            style: effectiveStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
    );
  }
}
