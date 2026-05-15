import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/statistics_controller.dart';
import '../../../core/design/app_colors.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StatisticsController c = Get.put(StatisticsController());

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor), onPressed: () => Get.back()),
        title: const Text('Statistics Overview', style: TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.w600, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Check Pass Rates & Assessment Content',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black)),
            const SizedBox(height: 20),

            // Airline dropdown
            Obx(() => _buildAirlineDropdown(context, c)),
            const SizedBox(height: 16),

            // Year only picker
            Obx(() => _buildYearPicker(context, c)),
            const SizedBox(height: 16),

            // Search button
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: c.isLoadingSearch.value ? null : () => c.searchStatistics(),
                icon: c.isLoadingSearch.value
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(CupertinoIcons.search, color: Colors.white),
                label: const Text('Search', style: TextStyle(color: Colors.white)),
              ),
            )),
            const SizedBox(height: 16),

            // Search results
            Obx(() {
              final Map<String, dynamic>? stats = c.airlineStats.value;
              if (stats == null) return const SizedBox.shrink();
              return _buildSearchResult(context, c, stats);
            }),

            const SizedBox(height: 8),
            const Text('Top Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black)),
            const SizedBox(height: 12),

            Obx(() => _buildTopCard(
              context: context,
              title: 'Top Airlines by Pass Rate',
              selectedYear: c.filterYearPassRate.value,
              isLoading: c.isLoadingPassRate.value,
              items: c.topByPassRate,
              valueBuilder: (Map<String, dynamic> item) => '${(item['successRate'] as double).toStringAsFixed(1)}%',
              nameBuilder: (Map<String, dynamic> item) => item['name'] as String,
              onYearSelected: (int y) { c.filterYearPassRate.value = y; c.loadTopByPassRate(); },
            )),
            const SizedBox(height: 12),

            Obx(() => _buildTopCard(
              context: context,
              title: 'Top Airlines by Submission Count',
              selectedYear: c.filterYearSubmission.value,
              isLoading: c.isLoadingSubmission.value,
              items: c.topBySubmission,
              valueBuilder: (Map<String, dynamic> item) => '${item['submissionCount']}',
              nameBuilder: (Map<String, dynamic> item) => item['name'] as String,
              onYearSelected: (int y) { c.filterYearSubmission.value = y; c.loadTopBySubmission(); },
            )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildAirlineDropdown(BuildContext context, StatisticsController c) {
    if (c.assessmentController.loadingAirlines.value) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primaryColor)),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Airline Name', style: TextStyle(color: AppColors.primaryColor, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Choose the Airline Name', style: TextStyle(color: AppColors.primaryColor, fontSize: 14)),
              value: c.selectedAirlineName.value.isEmpty ? null : c.selectedAirlineName.value,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryColor),
              items: c.assessmentController.airlines.map((Map<String, dynamic> a) =>
                DropdownMenuItem<String>(value: a['name'] as String, child: Text(a['name'] as String))).toList(),
              onChanged: (String? v) { if (v != null) c.selectedAirlineName.value = v; },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearPicker(BuildContext context, StatisticsController c) {
    return GestureDetector(
      onTap: () => _showYearPickerDialog(context, c),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primaryColor)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Select Year', style: TextStyle(color: AppColors.primaryColor, fontSize: 12, fontWeight: FontWeight.w500)),
            Row(
              children: <Widget>[
                Expanded(child: Text('${c.searchYear.value}', style: const TextStyle(fontSize: 14))),
                const Icon(CupertinoIcons.calendar, color: AppColors.primaryColor, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showYearPickerDialog(BuildContext context, StatisticsController c) {
    final List<int> years = List<int>.generate(DateTime.now().year + 1 - 2024 + 1, (int i) => DateTime.now().year + 1 - i);
    Get.dialog(Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primaryColor, width: 2)),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Select Year', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryColor, fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: years.length,
                itemBuilder: (BuildContext ctx, int i) => ListTile(
                  title: Text('${years[i]}'),
                  trailing: c.searchYear.value == years[i] ? const Icon(CupertinoIcons.check_mark, color: AppColors.primaryColor) : null,
                  onTap: () {
                    c.searchYear.value = years[i];
                    Get.back();
                  },
                ),
              ),
            ),
            OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(color: AppColors.red))),
          ],
        ),
      ),
    ));
  }

  Widget _buildSearchResult(BuildContext context, StatisticsController c, Map<String, dynamic> stats) {
    final Map<int, int> monthlyData = Map<int, int>.from(stats['monthlyData'] as Map);
    final List<String> assessments = List<String>.from(stats['assessments'] as List);
    final int maxVal = monthlyData.values.isEmpty ? 1 : monthlyData.values.reduce((int a, int b) => a > b ? a : b);
    final List<String> months = <String>['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Search Result', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primaryColor)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(stats['airlineName'] as String, style: Theme.of(context).textTheme.titleMedium),
              Text('${stats['year']}', style: const TextStyle(color: AppColors.primaryColor, fontSize: 13)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                const Text('Total Responses'),
                Text('${stats['totalSubmissions']}'),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                const Text('Success Rate'),
                Text('${(stats['successRate'] as double).toStringAsFixed(1)}%',
                  style: const TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 16),

              // Monthly bar chart - fixed overflow
              const Text('Monthly Distribution', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List<Widget>.generate(12, (int i) {
                    final int count = monthlyData[i + 1] ?? 0;
                    final double barHeight = maxVal > 0 ? (count / maxVal * 55).clamp(2.0, 55.0) : 2.0;
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          if (count > 0)
                            Text('$count', style: const TextStyle(fontSize: 8, color: AppColors.primaryColor)),
                          const SizedBox(height: 2),
                          Container(
                            height: barHeight,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: count > 0 ? AppColors.primaryColor : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(months[i], style: const TextStyle(fontSize: 7, color: Colors.grey)),
                        ],
                      ),
                    );
                  }),
                ),
              ),

              if (assessments.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                const Divider(),
                const Text('Assessment Content', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                ...assessments.map((String a) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• ${a[0].toUpperCase()}${a.substring(1)}', style: const TextStyle(fontSize: 14)),
                )),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTopCard({
    required BuildContext context,
    required String title,
    required int selectedYear,
    required bool isLoading,
    required List<Map<String, dynamic>> items,
    required String Function(Map<String, dynamic>) valueBuilder,
    required String Function(Map<String, dynamic>) nameBuilder,
    required Function(int) onYearSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primaryColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryColor))),
              GestureDetector(
                onTap: () => _showYearDialog(context, selectedYear, onYearSelected),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.primaryColor)),
                  child: Row(children: <Widget>[
                    Text('$selectedYear', style: const TextStyle(fontSize: 12, color: AppColors.primaryColor)),
                    const Icon(CupertinoIcons.chevron_down, size: 10, color: AppColors.primaryColor),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: <Widget>[
            Container(height: 5, width: 50, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 8),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (items.isEmpty)
            const Text('No data for the selected year', style: TextStyle(color: Colors.grey, fontSize: 13))
          else
            ...items.asMap().entries.map((MapEntry<int, Map<String, dynamic>> entry) => Column(
              children: <Widget>[
                if (entry.key > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(nameBuilder(entry.value), style: const TextStyle(fontSize: 14)),
                      Text(valueBuilder(entry.value), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryColor)),
                    ],
                  ),
                ),
              ],
            )),
        ],
      ),
    );
  }

  void _showYearDialog(BuildContext context, int currentYear, Function(int) onSelected) {
    final List<int> years = List<int>.generate(DateTime.now().year + 1 - 2024 + 1, (int i) => DateTime.now().year + 1 - i);
    Get.dialog(Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primaryColor, width: 2)),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Select Year', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryColor)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: years.length,
                itemBuilder: (BuildContext ctx, int i) => ListTile(
                  title: Text('${years[i]}'),
                  trailing: currentYear == years[i] ? const Icon(CupertinoIcons.check_mark, color: AppColors.primaryColor) : null,
                  onTap: () { Get.back(); onSelected(years[i]); },
                ),
              ),
            ),
            OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(color: AppColors.red))),
          ],
        ),
      ),
    ));
  }
}
