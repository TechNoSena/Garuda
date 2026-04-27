import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A playful container with thick Ink Black borders and asymmetric
/// border-radius — inspired by Google's geometric design language.
///
/// Use the named constructors for preset shape flavours, or supply
/// a custom [borderRadius] directly.
class FunkyBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double borderWidth;

  const FunkyBox({
    super.key,
    required this.child,
    required this.color,
    required this.borderRadius,
    this.padding = const EdgeInsets.all(16),
    this.borderWidth = 3,
  });

  // ── Preset shape helpers ──────────────────────────────────

  /// Top-left & bottom-right are large curves, rest are tight.
  factory FunkyBox.diagonal({
    Key? key,
    required Widget child,
    required Color color,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return FunkyBox(
      key: key,
      color: color,
      padding: padding,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(8),
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(32),
      ),
      child: child,
    );
  }

  /// Top is fully rounded, bottom is tight — like a ticket stub.
  factory FunkyBox.topRound({
    Key? key,
    required Widget child,
    required Color color,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return FunkyBox(
      key: key,
      color: color,
      padding: padding,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      ),
      child: child,
    );
  }

  /// Bottom is fully rounded, top is tight — inverted ticket.
  factory FunkyBox.bottomRound({
    Key? key,
    required Widget child,
    required Color color,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return FunkyBox(
      key: key,
      color: color,
      padding: padding,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(8),
        topRight: Radius.circular(8),
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: child,
    );
  }

  /// Left side curved, right side tight — like a tab.
  factory FunkyBox.leftRound({
    Key? key,
    required Widget child,
    required Color color,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return FunkyBox(
      key: key,
      color: color,
      padding: padding,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(8),
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(8),
      ),
      child: child,
    );
  }

  /// Full stadium / pill shape.
  factory FunkyBox.pill({
    Key? key,
    required Widget child,
    required Color color,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
  }) {
    return FunkyBox(
      key: key,
      color: color,
      padding: padding,
      borderRadius: BorderRadius.circular(40),
      child: child,
    );
  }

  /// Only one corner is large (top-right), rest are tight — asymmetric accent.
  factory FunkyBox.cornerAccent({
    Key? key,
    required Widget child,
    required Color color,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return FunkyBox(
      key: key,
      color: color,
      padding: padding,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(8),
        topRight: Radius.circular(40),
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: Border.all(color: GarudaColors.primaryDark, width: borderWidth),
      ),
      child: child,
    );
  }
}
