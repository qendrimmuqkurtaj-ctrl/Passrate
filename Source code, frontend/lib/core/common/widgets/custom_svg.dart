import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomSvgImage extends StatelessWidget {
  final String assetName;
  final double width;
  final double height;
  final BoxFit fit;
  final Color? color;
  final String? semanticsLabel;
  final bool excludeFromSemantics;

  const CustomSvgImage({
    Key? key,
    required this.assetName,
    this.width = 16.0, // Default responsive width
    this.height = 16.0, // Default responsive height
    this.fit = BoxFit.contain,
    this.color,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetName,
      width: width ,
      // Responsive width
      height: height ,
      // Responsive height
      fit: fit,
      colorFilter:
      color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
    );
  }
}
