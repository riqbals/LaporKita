import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget reusable untuk menampilkan logo SVG resmi LaporKita.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.width = 160,
    this.height,
  });

  static const String assetPath = 'assets/images/logo-laporkita.svg';

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticsLabel: 'Logo LaporKita',
    );
  }
}
