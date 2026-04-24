import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pass_rate/core/common/widgets/custom_svg.dart';
import 'package:pass_rate/core/config/app_constants.dart';
import 'package:pass_rate/core/config/app_sizes.dart';
import 'package:pass_rate/core/design/app_icons.dart';
import 'package:pass_rate/core/extensions/context_extensions.dart';
import 'package:pass_rate/features/assessment/controllers/assessment_controller.dart';
import 'package:pass_rate/shared/widgets/custom_appbar.dart';
import '../../../core/common/widgets/custom_dropdown.dart';
import '../../../core/common/widgets/date_picker_field.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/utils/logger_utils.dart';
import '../controllers/statistics_controller.dart';

class StatisticsScreen extends GetView<StatisticsController> {
  StatisticsScreen({super.key});

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
              Text(AppStrings.topResults.tr, style: context.txtTheme.titleMedium),
              const SizedBox(height: AppSizes.md),

              ///==============> The filter container
              statisticsContainer(
                context: context,
                title: AppStrings.topAirlinesByPassRate.tr,
                list: <dynamic>[
                  <String, String>{'labeltxt': 'Airplane Name', 'data': '98%'},
                ],
              ),
              const SizedBox(height: AppSizes.md),

              statisticsContainer(
                context: context,
                title: AppStrings.topAirlineSubmission.tr,
                list: <dynamic>[
                  <String, String>{'labeltxt': 'Airplane Name', 'data': '98%'},
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container statisticsContainer({
    required BuildContext context,
    required String title,
    required List<dynamic> list,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryColor),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(title, style: context.txtTheme.headlineMedium),
              InkWell(
                onTap: () {
                  ///TODO : the filter will pop up
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                    border: Border.all(color: AppColors.primaryColor),
                  ),
                  child: Row(
                    spacing: 3,
                    children: <Widget>[
                      Text(AppStrings.year, style: context.txtTheme.labelSmall),
                      const Icon(CupertinoIcons.chevron_down, size: 10, color: Colors.black),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Transform.translate(
                offset: const Offset(0, 5),
                child: Container(
                  height: 5,
                  width: 50,
                  decoration: const BoxDecoration(color: AppColors.primaryColor),
                ),
              ),
              const SizedBox(width: 2),
              const Expanded(child: Divider(thickness: 0.5)),
              CustomSvgImage(assetName: AppIcons.dividerIcon, width: 20, height: 10),
            ],
          ),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[Text(list[index]['labeltxt']), Text(list[index]['data'])],
                ),
              );
            },

            separatorBuilder: (BuildContext context, int index) {
              return const Divider();
            },
          ),
        ],
      ),
    );
  }
}
