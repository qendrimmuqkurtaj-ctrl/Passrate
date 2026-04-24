import 'package:flutter/material.dart';
import 'package:pass_rate/core/extensions/context_extensions.dart';
import 'package:pass_rate/core/extensions/widget_extensions.dart';
import '../../core/config/app_sizes.dart';
import '../../core/design/app_colors.dart';

class AppButton extends StatelessWidget {
  final String labelText;
  final VoidCallback onTap;

  final Color bgColor;
  final Color textColor;

  const AppButton({
    super.key,
    required this.labelText,
    required this.onTap,
    this.bgColor = AppColors.bgColor,
    this.textColor = AppColors.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),

      color: bgColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        splashColor: textColor.withValues(alpha: 0.2),
        highlightColor: textColor.withValues(alpha: 0.2),
         onTap: onTap,
        child: Container(
          width: context.screenWidth,
          padding: const EdgeInsets.symmetric(vertical: AppSizes.md, horizontal: AppSizes.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            border: Border.all(color: textColor),
          ),
          child:
              Text(
                labelText,
                style: context.txtTheme.headlineMedium?.copyWith(color: textColor),
              ).centered,
        ),
      ),
    );
  }
}
