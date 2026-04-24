import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pass_rate/core/common/widgets/custom_svg.dart';
import 'package:pass_rate/core/config/app_constants.dart';
import 'package:pass_rate/core/extensions/context_extensions.dart';
import 'package:pass_rate/core/routes/app_routes.dart';
import 'package:pass_rate/core/utils/logger_utils.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/app_images.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_tile.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// Lower Helping Button ============>
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: helpingButtonWidget(
        context: context,
        onTap: () {
         Get.toNamed(AppRoutes.supportPage);
        },
      ),

      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            /// HomePage top logo =====>
            homeTopWidget(context),
            const SizedBox(height: 32),

            /// HomePage body  =====>
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                spacing: 16,
                children: <Widget>[
                  HomeTile(
                    labelText: AppStrings.submitAssessment,
                    svgPath: AppIcons.submitIcon,
                    onTap: () {
                      Get.toNamed(AppRoutes.submitAssessment);
                    },
                  ),
                  HomeTile(
                    labelText: AppStrings.statistics,
                    svgPath: AppIcons.statisticsIcon,
                    onTap: () {
                      Get.toNamed(AppRoutes.statisticsScreen);
                    },
                  ),
                  HomeTile(
                    labelText: AppStrings.yourSubmissions,
                    svgPath: AppIcons.submissionIcon,
                    onTap: () {
                      Get.toNamed(AppRoutes.submissionPage);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container helpingButtonWidget({required BuildContext context, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      child: Material(
        elevation: 3,
        color: Colors.white,
        borderRadius: BorderRadius.circular(3), // Add borderRadius here

        child: InkWell(
          splashColor: AppColors.green.withValues(alpha: 0.1),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
            width: context.screenWidth * .5,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.green),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
              children: <Widget>[
                CustomSvgImage(assetName: AppIcons.helpIcon, color: AppColors.green, height: 32),
                Text(
                  AppStrings.helpUsGrow.tr,
                  style: context.txtTheme.headlineMedium?.copyWith(color: AppColors.green),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Container homeTopWidget(BuildContext context) {
    return Container(
      width: context.width,
      height: context.height * .25,
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),

        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Image.asset(AppImages.logoWithTextImage, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
