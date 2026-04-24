import 'package:flutter/material.dart';

import '../../../core/common/widgets/custom_svg.dart';
import '../../../core/design/app_colors.dart';

class HomeTile extends StatelessWidget {
  final String labelText;
  final String svgPath;
  final VoidCallback onTap;

  const HomeTile({super.key, required this.labelText, required this.svgPath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryColor),
          ),
          child: Row(
            spacing: 12,
            children: <Widget>[
              CustomSvgImage(assetName: svgPath, height: 32),
              Expanded(child: Text(labelText, style: textTheme.titleMedium)),
            ],
          ),
        ),
      ),
    );
  }
}
