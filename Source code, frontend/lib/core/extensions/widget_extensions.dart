import 'package:flutter/material.dart';

extension WidgetExtensions on Widget {
  Widget get centered => Center(child: this);
  Widget visible(bool isVisible) => isVisible ? this : const SizedBox.shrink();
}
