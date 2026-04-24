import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pass_rate/core/extensions/context_extensions.dart';
import 'package:pass_rate/core/extensions/widget_extensions.dart';
import '../../core/config/app_sizes.dart';
import '../../core/design/app_colors.dart';

class CustomAppBar extends StatelessWidget {
  final String label;

  const CustomAppBar({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          onPressed: () {
            Get.back();
          },
          icon: const Icon(CupertinoIcons.back, size: 20, color: AppColors.primaryColor),
        ),
        Expanded(child: Text(label, style: context.txtTheme.labelSmall).centered),
        const SizedBox(width: AppSizes.xxl),
      ],
    );
  }
}
