import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pass_rate/core/config/app_constants.dart';
import 'package:pass_rate/core/config/app_sizes.dart';
import 'package:pass_rate/core/extensions/context_extensions.dart';
import 'package:pass_rate/core/routes/app_routes.dart';
import 'package:pass_rate/core/utils/enum.dart';
import 'package:pass_rate/core/utils/logger_utils.dart';
import 'package:pass_rate/shared/widgets/app_button.dart';
import 'package:pass_rate/shared/widgets/custom_appbar.dart';
import '../../../core/common/widgets/custom_dropdown.dart';
import '../../../core/common/widgets/custom_svg.dart';
import '../../../core/common/widgets/date_picker_field.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/utils/device/device_utility.dart';
import '../controllers/assessment_controller.dart';

class SubmitAssessmentScreen extends GetView<AssessmentController> {
  SubmitAssessmentScreen({super.key});

  final TextEditingController _assessmentDateTEController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CustomAppBar(label: AppStrings.submitResultTitle.tr),
              const SizedBox(height: AppSizes.md),
              Text(AppStrings.submitResultTitle.tr, style: context.txtTheme.labelLarge),

              /// ============> Airline Name ==========>
              const SizedBox(height: AppSizes.xl),
              CustomDropdown<String>(
                label: AppStrings.airlineName.tr,
                isRequired: true,
                items: controller.airlineNames,
                hint: AppStrings.chooseAirlineName.tr,
                dropdownMaxHeight: 250,
                onChanged: (String? value) {
                  LoggerUtils.debug('Selected searchable country: $value');
                },
                validator: (String? value) {
                  if (value == null) {
                    return 'Please select a type';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSizes.lg),

              /// Select Year and Month ================ >
              ReusableDatePickerField(
                labelText: AppStrings.selectYearAndMonth.tr,
                hintText: AppStrings.chooseAssessmentYear.tr,
                controller: _assessmentDateTEController,
              ),
              const SizedBox(height: AppSizes.lg),

              /// Select Year and Month ================ >
              CustomDropdown<String>(
                label: AppStrings.whatWasIncludedInYour.tr,
                isRequired: true,
                items: controller.assessmentItems,
                hint: AppStrings.chooseTasks.tr,
                dropdownMaxHeight: 250,
                onChanged: (String? value) {
                  LoggerUtils.debug('Selected searchable country: $value');
                },
                validator: (String? value) {
                  if (value == null) {
                    return 'Please select a type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.md),

              ///  ================== Pass fail button =========>
              Obx(
                () => Row(
                  spacing: 12,
                  children: <Widget>[
                    Expanded(
                      child: passedFailedButton(
                        context: context,
                        onTap: () {
                          controller.buttonState(ResultStatus.passed.displayName);
                        },
                        selected: controller.result.value == ResultStatus.passed.displayName,
                        label: ResultStatus.passed.displayName,
                        iconPath: AppIcons.passedIcon,
                        tileColor: AppColors.green,
                      ),
                    ),
                    Expanded(
                      child: passedFailedButton(
                        context: context,
                        onTap: () {
                          controller.buttonState(ResultStatus.failed.displayName);
                        },
                        selected: controller.result.value == ResultStatus.failed.displayName,
                        label: ResultStatus.failed.displayName,
                        iconPath: AppIcons.failedIcon,
                        tileColor: AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),

              /// Submit Button here =================>
              AppButton(
                labelText: AppStrings.submit.tr,
                onTap: () {
                  /// simple Vibration
                  DeviceUtility.hapticFeedback();
                  Get.toNamed(AppRoutes.confirmSubmissionPage);
                },
                bgColor: AppColors.primaryColor,
                textColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InkWell passedFailedButton({
    required BuildContext context,
    required String label,
    required String iconPath,
    required VoidCallback onTap,
    required bool selected,
    required Color tileColor,
  }) {
    return InkWell(
      splashColor: selected ? tileColor.withValues(alpha: 0.1) : Colors.transparent,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md, horizontal: 0),
        decoration: BoxDecoration(
          color: selected ? tileColor.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(color: tileColor, width: 1.5),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          spacing: 5,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CustomSvgImage(assetName: iconPath, color: tileColor, height: 28),
            Text(
              label,
              style: context.txtTheme.labelMedium?.copyWith(
                color: tileColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
