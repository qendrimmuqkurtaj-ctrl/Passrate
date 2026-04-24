import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pass_rate/core/extensions/widget_extensions.dart';

import '../design/app_colors.dart';



/// A reusable widget that displays a centered loading spinner using [SpinKitCircle].
///
/// This widget is commonly used to indicate that a page or section is loading.
///
/// Example usage:
/// ```dart
/// CustomPageLoading(); // Default size and color
///
/// CustomPageLoading(
///   size: 80.0,
///   color: Colors.blue,
/// );
/// ```
class CustomLoading extends StatelessWidget {
  /// The size of the loading spinner. Defaults to `60.0` if not specified.
  final double? size;

  /// The color of the loading spinner. Defaults to [AppColors.primaryColor] if not specified.
  final Color? color;

  /// Creates a [CustomPageLoading] widget.
  const CustomLoading({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SpinKitCircle(
      color: color ?? AppColors.white,
      size: size ?? 60.0,
    ).centered;
  }
}
