import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppBackgroundPattern extends StatelessWidget {
  final Color? patternColor;
  final double opacity;

  const AppBackgroundPattern({
    super.key,
    this.patternColor,
    this.opacity = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Opacity(
        opacity: opacity,
        child: SvgPicture.asset(
          'assets/splash_screen/pattern-tile.svg',
          fit: BoxFit.cover,
          colorFilter: patternColor != null
              ? ColorFilter.mode(patternColor!, BlendMode.srcIn)
              : null,
        ),
      ),
    );
  }
}
