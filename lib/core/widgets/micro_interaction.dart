import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Lightweight micro-interaction widget providing subtle scale-on-press,
/// desktop hover feedback, keyboard focus indicators, and reduced-motion support.
///
/// Designed to feel restrained and premium for fintech user experiences.
class InteractiveScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final double hoverScale;
  final Duration duration;
  final Curve curve;
  final bool enableHaptic;
  final bool enableHover;
  final String? semanticLabel;
  final BorderRadius? borderRadius;

  const InteractiveScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.975,
    this.hoverScale = 1.01,
    this.duration = const Duration(milliseconds: 140),
    this.curve = AppAnimations.curveDecelerate,
    this.enableHaptic = false,
    this.enableHover = true,
    this.semanticLabel,
    this.borderRadius,
  });

  @override
  State<InteractiveScale> createState() => _InteractiveScaleState();
}

class _InteractiveScaleState extends State<InteractiveScale> {
  bool _isPressed = false;
  bool _isHovered = false;
  bool _isFocused = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isPressed) setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (_isPressed) setState(() => _isPressed = false);
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    if (widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    // Calculate effective scale
    double targetScale = 1.0;
    if (!disableAnimations) {
      if (_isPressed) {
        targetScale = widget.scaleDown;
      } else if (_isHovered && widget.enableHover) {
        targetScale = widget.hoverScale;
      }
    }

    final effectiveDuration = disableAnimations
        ? Duration.zero
        : widget.duration;

    Widget result = AnimatedScale(
      scale: targetScale,
      duration: effectiveDuration,
      curve: widget.curve,
      child: widget.child,
    );

    // Keyboard focus outline for desktop/web accessibility
    if (_isFocused) {
      final theme = Theme.of(context);
      result = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius:
              widget.borderRadius ?? BorderRadius.circular(AppRadius.radius12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.8),
            width: 2.0,
          ),
        ),
        child: result,
      );
    }

    final isInteractive = widget.onTap != null || widget.onLongPress != null;

    if (isInteractive) {
      result = FocusableActionDetector(
        enabled: isInteractive,
        onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
        onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _handleTap(),
          ),
        },
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: _handleTap,
          onLongPress: widget.onLongPress,
          behavior: HitTestBehavior.opaque,
          child: result,
        ),
      );
    }

    if (widget.semanticLabel != null || isInteractive) {
      result = Semantics(
        label: widget.semanticLabel,
        button: isInteractive,
        enabled: isInteractive,
        child: result,
      );
    }

    return result;
  }
}

/// Convenience alias for [InteractiveScale].
typedef PressScale = InteractiveScale;
