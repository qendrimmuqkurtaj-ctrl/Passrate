import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pass_rate/core/config/app_constants.dart';
import 'package:pass_rate/core/config/app_sizes.dart';
import 'package:pass_rate/core/extensions/context_extensions.dart';
import 'package:pass_rate/features/assessment/controllers/assessment_controller.dart';
import 'package:pass_rate/shared/widgets/custom_appbar.dart';
import '../../../core/common/widgets/custom_dropdown.dart';
import '../../../core/common/widgets/date_picker_field.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/utils/logger_utils.dart';
import '../controllers/statistics_controller.dart';

class ViewStatistics extends GetView<StatisticsController> {
  ViewStatistics({super.key});

  final TextEditingController _assessmentDateTEController = TextEditingController();
  final TextEditingController _searchTeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CustomAppBar(label: AppStrings.statisticsOverview.tr),
              const SizedBox(height: AppSizes.md),
              Text(
                AppStrings.checkPassRatesAssessmentContent.tr,
                style: context.txtTheme.titleMedium,
              ),
              const SizedBox(height: AppSizes.lg),
              CustomDropdown<String>(
                label: AppStrings.airlineName.tr,
                isRequired: true,
                items: Get.put(AssessmentController()).airlineNames,
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

              /// Search Bar ================ >
              TextFormField(
                controller: _searchTeController,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(CupertinoIcons.search, color: AppColors.primaryColor),
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              ///==============> The bottom container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryColor),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Rynair', style: context.txtTheme.titleMedium),
                    Text('2024', style: context.txtTheme.labelMedium),
                    const SizedBox(height: AppSizes.lg),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[Text('Total Responses:'), Text('124')],
                    ),
                    const SizedBox(height: AppSizes.sm),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[Text('Success Rate'), Text('80%')],
                    ),
                    const Divider(),
                    Text('Assessment Content', style: context.txtTheme.titleMedium),
                    const SizedBox(height: AppSizes.sm),
                    const Text('Sim'),
                    const Text('Group Task'),
                    const Text('Interview'),

                    const SizedBox(height: AppSizes.md),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
