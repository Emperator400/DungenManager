import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 24, this.color});

  final double size;

  /// Override color — defaults to C.accent when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo.svg',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
