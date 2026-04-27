import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Decorative animated geometric shapes that float behind content.
/// Wrapped in a blur filter for a frosted-glass depth effect.
class FloatingShapes extends StatelessWidget {
  const FloatingShapes({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
            child: Opacity(
              opacity: 0.55,
              child: Stack(
                children: [
                  // ── Large Pill (top-left) ──
                  Positioned(
                    top: 30,
                    left: -50,
                    child: _pill(180, 65, GarudaColors.primaryLight)
                        .animate(onPlay: (c) => c.repeat())
                        .moveY(begin: -12, end: 12, duration: 5.seconds, curve: Curves.easeInOut)
                        .then()
                        .moveY(begin: 12, end: -12, duration: 5.seconds, curve: Curves.easeInOut),
                  ),

                  // ── Plus sign (top-right) ──
                  Positioned(
                    top: 60,
                    right: 30,
                    child: _plus(55, GarudaColors.warning)
                        .animate(onPlay: (c) => c.repeat())
                        .rotate(duration: 20.seconds)
                        .moveY(begin: -10, end: 10, duration: 4.seconds, curve: Curves.easeInOut)
                        .then()
                        .moveY(begin: 10, end: -10, duration: 4.seconds, curve: Curves.easeInOut),
                  ),

                  // ── Three dots in a row (mid-right) ──
                  Positioned(
                    top: 180,
                    right: -10,
                    child: _dotRow(GarudaColors.consumerColor)
                        .animate(onPlay: (c) => c.repeat())
                        .moveX(begin: 8, end: -8, duration: 4.seconds, curve: Curves.easeInOut)
                        .then()
                        .moveX(begin: -8, end: 8, duration: 4.seconds, curve: Curves.easeInOut),
                  ),

                  // ── Half-moon arc (left) ──
                  Positioned(
                    top: 200,
                    left: -35,
                    child: _halfMoon(100, GarudaColors.danger)
                        .animate(onPlay: (c) => c.repeat())
                        .rotate(begin: 0, end: 0.15, duration: 8.seconds, curve: Curves.easeInOut)
                        .then()
                        .rotate(begin: 0.15, end: 0, duration: 8.seconds, curve: Curves.easeInOut),
                  ),

                  // ── Giant comma (mid) ──
                  Positioned(
                    top: 280,
                    right: 40,
                    child: _textGlyph(',', 90, GarudaColors.deliveryColor)
                        .animate(onPlay: (c) => c.repeat())
                        .moveY(begin: 10, end: -10, duration: 5.seconds, curve: Curves.easeInOut)
                        .then()
                        .moveY(begin: -10, end: 10, duration: 5.seconds, curve: Curves.easeInOut),
                  ),

                  // ── Small square (rotates) ──
                  Positioned(
                    top: 370,
                    left: 30,
                    child: _square(45, GarudaColors.accent)
                        .animate(onPlay: (c) => c.repeat())
                        .rotate(duration: 14.seconds)
                        .moveY(begin: -8, end: 8, duration: 3.seconds, curve: Curves.easeInOut)
                        .then()
                        .moveY(begin: 8, end: -8, duration: 3.seconds, curve: Curves.easeInOut),
                  ),

                  // ── Bracket pair [ ] (bottom-right) ──
                  Positioned(
                    bottom: 140,
                    right: 15,
                    child: _bracketBox(GarudaColors.supplierColor)
                        .animate(onPlay: (c) => c.repeat())
                        .moveY(begin: 12, end: -12, duration: 4.seconds, curve: Curves.easeInOut)
                        .then()
                        .moveY(begin: -12, end: 12, duration: 4.seconds, curve: Curves.easeInOut),
                  ),

                  // ── Arrow → (bottom center-left) ──
                  Positioned(
                    bottom: 90,
                    left: 60,
                    child: _arrowShape(GarudaColors.primary)
                        .animate(onPlay: (c) => c.repeat())
                        .moveX(begin: -10, end: 10, duration: 3.seconds, curve: Curves.easeInOut)
                        .then()
                        .moveX(begin: 10, end: -10, duration: 3.seconds, curve: Curves.easeInOut),
                  ),

                  // ── Large circle (bottom-left, peeking) ──
                  Positioned(
                    bottom: -40,
                    left: -30,
                    child: _circle(110, GarudaColors.primaryLight)
                        .animate(onPlay: (c) => c.repeat())
                        .moveX(begin: -15, end: 15, duration: 7.seconds, curve: Curves.easeInOut)
                        .then()
                        .moveX(begin: 15, end: -15, duration: 7.seconds, curve: Curves.easeInOut),
                  ),

                  // ── Hash # glyph (bottom-right) ──
                  Positioned(
                    bottom: 20,
                    right: -15,
                    child: _textGlyph('#', 70, GarudaColors.info)
                        .animate(onPlay: (c) => c.repeat())
                        .rotate(duration: 25.seconds),
                  ),

                  // ── Squiggle / tilde (top-center) ──
                  Positioned(
                    top: 130,
                    left: 120,
                    child: _textGlyph('~', 60, GarudaColors.consumerColor)
                        .animate(onPlay: (c) => c.repeat())
                        .moveY(begin: -8, end: 8, duration: 3.seconds, curve: Curves.easeInOut)
                        .then()
                        .moveY(begin: 8, end: -8, duration: 3.seconds, curve: Curves.easeInOut),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Shape builders ──────────────────────────────────────────

  Widget _pill(double w, double h, Color color) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(h / 2),
        border: Border.all(color: GarudaColors.primaryDark, width: 3.5),
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: GarudaColors.primaryDark, width: 3.5),
      ),
    );
  }

  Widget _square(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GarudaColors.primaryDark, width: 3.5),
      ),
    );
  }

  Widget _plus(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GarudaColors.primaryDark, width: 3.5),
      ),
      child: Icon(Icons.add_rounded, size: size * 0.65, color: GarudaColors.primaryDark),
    );
  }

  Widget _dotRow(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          width: 28,
          height: 28,
          margin: EdgeInsets.only(left: i > 0 ? 6 : 0),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: GarudaColors.primaryDark, width: 3),
          ),
        );
      }),
    );
  }

  Widget _halfMoon(double size, Color color) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: Align(
          alignment: Alignment.centerRight,
          widthFactor: 0.5,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: GarudaColors.primaryDark, width: 3.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bracketBox(Color color) {
    return Container(
      width: 55,
      height: 75,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(6),
        ),
        border: Border.all(color: GarudaColors.primaryDark, width: 3.5),
      ),
      child: Center(
        child: Text(
          '[ ]',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: GarudaColors.primaryDark,
          ),
        ),
      ),
    );
  }

  Widget _arrowShape(Color color) {
    return Container(
      width: 80,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(color: GarudaColors.primaryDark, width: 3.5),
      ),
      child: Center(
        child: Text(
          '→',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _textGlyph(String glyph, double size, Color color) {
    return Text(
      glyph,
      style: GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color,
        height: 1.0,
        shadows: [
          Shadow(offset: const Offset(2, 2), color: GarudaColors.primaryDark),
          Shadow(offset: const Offset(-2, -2), color: GarudaColors.primaryDark),
          Shadow(offset: const Offset(2, -2), color: GarudaColors.primaryDark),
          Shadow(offset: const Offset(-2, 2), color: GarudaColors.primaryDark),
        ],
      ),
    );
  }
}
