import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pass_rate/core/config/app_constants.dart';
import 'package:pass_rate/core/config/app_sizes.dart';
import 'package:pass_rate/core/design/app_colors.dart';
import 'package:pass_rate/core/extensions/context_extensions.dart';
import 'package:pass_rate/core/utils/device/device_utility.dart';
import 'package:pass_rate/core/utils/logger_utils.dart';
import 'package:pass_rate/shared/widgets/custom_appbar.dart';
import '../../../shared/widgets/app_button.dart';
import '../controllers/support_controller.dart';
import '../widgets/support_plan.dart';

class SupportScreen extends GetView<SupportController> {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const CustomAppBar(label: AppStrings.supportPassRate),
              const SizedBox(height: AppSizes.md),
              Text(
                AppStrings.helpUsKeepTheAppFree.tr,
                style: context.txtTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(AppStrings.everyEuroGoesTowardSupport.tr),
              bulletinText(bodyText: AppStrings.salaryComparisons.tr),
              bulletinText(bodyText: AppStrings.realAssessmentInsights.tr),
              bulletinText(bodyText: AppStrings.futureReleaseOFPilot.tr),
              const SizedBox(height: AppSizes.sm),
              Text(AppStrings.aDedicatedPlatformWhere.tr),
              SupportPlanSelector(
                plans: <PlanOption>[
                  PlanOption(
                    title: AppStrings.supportPlanCadetTitle,
                    description: AppStrings.supportPlanCadetDesc,
                    price: "€1/month",
                  ),
                  PlanOption(
                    title: AppStrings.supportPlanCadetPlusTitle,
                    description: AppStrings.supportPlanCadetPlusDesc,
                    price: "€8/year",
                  ),
                  PlanOption(
                    title: AppStrings.supportPlanFirstOfficerTitle,
                    description: AppStrings.supportPlanFirstOfficerDesc,
                    price: "€3/month",
                  ),
                  PlanOption(
                    title: AppStrings.supportPlanCaptainTitle,
                    description: AppStrings.supportPlanCaptainDesc,
                    price: "€20/year",
                  ),
                ],
                // plans: <PlanOption>[
                //   PlanOption(
                //     title: AppStrings.supportPlanCadetTitle,
                //     description: AppStrings.supportPlanCadetDesc,
                //     price: "€1/month",
                //   ),
                //   PlanOption(
                //     title: AppStrings.supportPlanCadetPlusTitle,
                //     description: AppStrings.supportPlanCadetPlusDesc,
                //     price: "€8/year",
                //   ),
                //   PlanOption(
                //     title: AppStrings.supportPlanFirstOfficerTitle,
                //     description: AppStrings.supportPlanFirstOfficerDesc,
                //     price: "€3/month",
                //   ),
                //   PlanOption(
                //     title: AppStrings.supportPlanCaptainTitle,
                //     description: AppStrings.supportPlanCaptainDesc,
                //     price: "€20/year",
                //   ),
                // ],
                onPlanSelected: (int index) {
                  LoggerUtils.debug('Selected plan at index: $index');
                },
              ),
              const SizedBox(height: AppSizes.sm),

              /// Proceed button ============>
              AppButton(
                labelText: AppStrings.proceed.tr,
                onTap: () {
                  /// simple Vibration
                  DeviceUtility.hapticFeedback();
                },
              ),

              /// Proceed button lower part  ============>
              const SizedBox(height: AppSizes.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      AppStrings.cancelPlan,
                      style: context.txtTheme.labelSmall?.copyWith(
                        color: AppColors.red,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.red,
                        decorationThickness: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              Text(AppStrings.moSubscriptionLock.tr, textAlign: TextAlign.start),
            ],
          ),
        ),
      ),
    );
  }

  Padding bulletinText({required String bodyText}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        spacing: AppSizes.md,
        children: <Widget>[
          Container(
            height: 5,
            width: 5,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
          ),
          Text(bodyText),
        ],
      ),
    );
  }
}
