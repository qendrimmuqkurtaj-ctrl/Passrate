import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pass_rate/core/config/app_sizes.dart';
import 'package:pass_rate/core/utils/enum.dart';
import '../../../core/design/app_colors.dart';
import '../../../shared/widgets/custom_appbar.dart' show CustomAppBar;
import '../controllers/submissions_controller.dart';
import '../widget/submission_tile.dart';

class SubmissionsScreen extends GetView<SubmissionsController> {
  SubmissionsScreen({super.key});

  final TextEditingController _searchTeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Column(
            children: <Widget>[
              /// Appbar ====>
              const CustomAppBar(label: 'My Submissions'),
              const SizedBox(height: AppSizes.md),

              /// Search field  ====>
              TextFormField(
                controller: _searchTeController,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(CupertinoIcons.search, color: AppColors.primaryColor),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              /// Submission Container  ====>
              Expanded(
                child: ListView.separated(
                  // physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: 20,
                  itemBuilder: (BuildContext context, int index) {
                    return SubmissionTile(
                      bodyText: 'July 2024',
                      name: 'Ryanair',
                      resultStatus: ResultStatus.failed.displayName,
                    );
                  },

                  separatorBuilder: (BuildContext context, int index) {
                    return const SizedBox(height: AppSizes.md);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


