import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pass_rate/core/extensions/context_extensions.dart';

 import '../config/app_sizes.dart';
import '../design/app_colors.dart';


class CustomBottomSheet {
  CustomBottomSheet._();

  static void showCustomBottomSheet({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
   }) {
    Get.bottomSheet(
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      isScrollControlled: true,
      PopScope(
        canPop: isDismissible,
        child:  BackdropFilter(
          filter:   ImageFilter.blur(sigmaX:    AppSizes.sm, sigmaY:   AppSizes.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.md),
            constraints: BoxConstraints(
              minWidth: context.screenWidth,
              minHeight: context.screenHeight * 0.25,
            ),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32.0),
                topRight: Radius.circular(32.0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 50.0,
                  height: 6.0,
                  decoration: BoxDecoration(
                    color: AppColors.grey,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
                  ),
                ),
                const SizedBox(height: AppSizes.spaceBetweenSections,),
                child,
                const SizedBox(height: AppSizes.spaceBetweenSections,),
              ],
            ),
          ),
        )
      ),
    );
  }

  static void show(
    BuildContext context, {
      required Widget child,
      bool isScrollControlled = false,
      double? height,
    }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent, 
      barrierColor: Colors.transparent, 
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(60)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }

  static void showCustomFullBottomSheet({required BuildContext context, required Widget child}) {
    Get.bottomSheet(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppSizes.sm, sigmaY: AppSizes.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.md),
          constraints: BoxConstraints(
            minWidth: context.screenWidth,
            minHeight: context.screenHeight * 0.90,
            maxHeight: context.screenHeight * 0.90,
          ),
          decoration: const BoxDecoration(
            // color:isLightMode ? AppColors.blackColor : AppColors.blackColor,
            color: AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppSizes.borderRadiusXxl),
              topRight: Radius.circular(AppSizes.borderRadiusXxl),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 80.0,
                  height: 6.0,
                  decoration: BoxDecoration(
                    color: AppColors.grey,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
                  ),
                ),
                const SizedBox(height: AppSizes.spaceBetweenSections),
                child,
                const SizedBox(height: AppSizes.spaceBetweenSections),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
