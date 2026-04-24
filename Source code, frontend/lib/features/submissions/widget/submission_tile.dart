import 'package:flutter/material.dart';
import 'package:pass_rate/core/extensions/context_extensions.dart';
import '../../../core/common/widgets/custom_svg.dart';
import '../../../core/config/app_sizes.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/utils/enum.dart';

class SubmissionTile extends StatelessWidget {
  final String bodyText;

  final String name;

  final String resultStatus;

  const SubmissionTile({
    super.key,
    required this.bodyText,
    required this.name,
    required this.resultStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primaryColor),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
      ),
      child: Column(
        children: <Widget>[
          Align(
            alignment: Alignment.topRight,
            child: Material(
              color: Colors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                splashColor: Colors.grey,
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: CustomSvgImage(assetName: AppIcons.editIcon, height: 24),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Align(alignment: Alignment.center, child: Text(bodyText)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(name, style: context.txtTheme.titleMedium),
                 Row(
                  spacing: 5,
                  children: <Widget>[
                    CustomSvgImage(
                      assetName:
                      resultStatus == ResultStatus.passed.displayName
                          ? AppIcons.passedIcon
                          : AppIcons.failedIcon,
                      height: 22,
                    ),
                    Text(
                      resultStatus,
                      style: context.txtTheme.headlineMedium?.copyWith(
                        color:
                        resultStatus == ResultStatus.passed.displayName
                            ? AppColors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}