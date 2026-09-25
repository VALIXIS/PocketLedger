import 'package:flutter/material.dart';

class GoalProgressIndicator extends StatelessWidget {
  final double progress;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final BorderRadius? borderRadius;

  const GoalProgressIndicator({
    super.key,
    required this.progress,
    this.color,
    this.backgroundColor,
    this.height = 10.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clampedProgress = progress.clamp(0.0, 1.0);
    final isCompleted = clampedProgress >= 1.0;

    final barColor =
        color ??
        (isCompleted
            ? Colors.green.shade600
            : (clampedProgress >= 0.75
                  ? Colors.teal.shade600
                  : theme.colorScheme.primary));

    final bgColor =
        backgroundColor ??
        (theme.brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade200);

    final radius = borderRadius ?? BorderRadius.circular(height / 2);
    final percentText = (clampedProgress * 100).toStringAsFixed(1);

    return Semantics(
      label: '$percentText percent of goal completed',
      value: percentText,
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: height,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: clampedProgress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: bgColor,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: height,
              );
            },
          ),
        ),
      ),
    );
  }
}
