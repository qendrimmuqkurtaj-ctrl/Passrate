import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/assessment_controller.dart';
import '../../../core/design/app_colors.dart';
import '../../statistics/screens/statistics_screen.dart';

class SubmitAssessmentScreen extends StatelessWidget {
  const SubmitAssessmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AssessmentController());

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.accent),
          onPressed: () => Get.back(),
        ),
        title: const Text('Submit Result', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GetBuilder<AssessmentController>(
          builder: (AssessmentController c) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Submit Result', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 24),

              // Airline dropdown
              _FieldLabel('Airline Name'),
              Obx(() => c.loadingAirlines.value
                ? const Center(child: CircularProgressIndicator())
                : _buildAirlineDropdown(context, c)),
              const SizedBox(height: 16),

              // Date picker
              _FieldLabel('Select Year and Month'),
              _buildDatePicker(context, c),
              const SizedBox(height: 16),

              // Tasks (only show if airline selected)
              Obx(() => c.selectedAirline.value != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _FieldLabel('What was included in your assessment?'),
                      c.loadingTasks.value
                        ? const Center(child: CircularProgressIndicator())
                        : c.tasks.isEmpty
                          ? const Text('No tasks available', style: TextStyle(color: AppColors.textMuted))
                          : _buildTasksCheckboxes(c),
                      const SizedBox(height: 16),
                    ],
                  )
                : const SizedBox.shrink()),

              // Passed / Failed
              Row(
                children: <Widget>[
                  Expanded(child: _PassFailButton(
                    label: 'PASSED',
                    icon: CupertinoIcons.check_mark_circled,
                    color: AppColors.passText,
                    borderColor: AppColors.passBorder,
                    selectedBg: AppColors.passBg,
                    selected: c.passed.value == true,
                    onTap: () => c.setPassed(true),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _PassFailButton(
                    label: 'FAILED',
                    icon: CupertinoIcons.xmark_circle,
                    color: AppColors.failText,
                    borderColor: AppColors.failBorder,
                    selectedBg: AppColors.failBg,
                    selected: c.passed.value == false,
                    onTap: () => c.setPassed(false),
                  )),
                ],
              ),
              const SizedBox(height: 24),

              // Progress bar
              Obx(() => _buildProgressBar(c)),
              const SizedBox(height: 16),

              // Submit button
              Obx(() => c.allCompleted
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: c.submitting.value ? null : () => _submit(c),
                      child: c.submitting.value
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Submit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  )
                : const SizedBox.shrink()),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAirlineDropdown(BuildContext context, AssessmentController c) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          isExpanded: true,
          hint: const Text('Choose the Airline Name', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          value: c.selectedAirline.value,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.accent),
          dropdownColor: AppColors.bgCard,
          items: c.airlines.map((Map<String, dynamic> a) => DropdownMenuItem<Map<String, dynamic>>(
            value: a,
            child: Text(a['name'] as String, style: const TextStyle(color: AppColors.textPrimary)),
          )).toList(),
          onChanged: (Map<String, dynamic>? v) { if (v != null) c.selectAirline(v); },
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, AssessmentController c) {
    return GestureDetector(
      onTap: () => _showMonthYearPicker(context, c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                c.dateController.text.isEmpty ? 'Choose the year of assessment' : c.dateController.text,
                style: TextStyle(color: c.dateController.text.isEmpty ? AppColors.textMuted : AppColors.textPrimary, fontSize: 14),
              ),
            ),
            const Icon(CupertinoIcons.calendar, color: AppColors.accent, size: 20),
          ],
        ),
      ),
    );
  }

  void _showMonthYearPicker(BuildContext context, AssessmentController c) {
    final DateTime now = DateTime.now();
    int selectedYear = c.selectedYear.value;
    int selectedMonth = c.selectedMonth.value;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx2, StateSetter setState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Select Year and Month', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              // Year selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text('Year:', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  Row(
                    children: <Widget>[
                      IconButton(icon: const Icon(CupertinoIcons.chevron_left, color: AppColors.textPrimary), onPressed: () => setState(() { if (selectedYear > 2024) selectedYear--; })),
                      Text('$selectedYear', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      IconButton(icon: const Icon(CupertinoIcons.chevron_right, color: AppColors.textPrimary), onPressed: () => setState(() { if (selectedYear <= now.year) selectedYear++; })),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Month grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: 12,
                itemBuilder: (BuildContext context, int i) {
                  final bool isSelected = selectedMonth == i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => selectedMonth = i + 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(child: Text(DateFormat('MMM').format(DateTime(2024, i + 1)), style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500))),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    c.onDateSelected(DateTime(selectedYear, selectedMonth));
                    Navigator.pop(ctx2);
                  },
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksCheckboxes(AssessmentController c) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: c.tasks.map((Map<String, dynamic> task) {
          final String id = task['id'] as String;
          final String name = task['name'] as String;
          return Obx(() => CheckboxListTile(
            title: Text(name, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            value: c.selectedTaskIds.contains(id),
            activeColor: AppColors.accent,
            checkColor: Colors.white,
            onChanged: (bool? _) => c.toggleTask(task),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            dense: true,
          ));
        }).toList(),
      ),
    );
  }

  Widget _buildProgressBar(AssessmentController c) {
    int steps = 0;
    if (c.selectedAirline.value != null) steps++;
    if (c.dateController.text.isNotEmpty) steps++;
    if (c.selectedTaskIds.isNotEmpty) steps++;
    if (c.passed.value != null) steps++;
    final double progress = steps / 4;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(progress >= 1.0 ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.airplane, color: AppColors.accent, size: 28),
        ],
      ),
    );
  }

  Future<void> _submit(AssessmentController c) async {
    final Map<String, dynamic>? result = await c.submitAssessment();
    if (result != null) {
      Get.to(() => ConfirmScreen(result: result, controller: c));
    } else {
      Get.snackbar('Error', 'Could not submit. Please try again.', snackPosition: SnackPosition.BOTTOM);
    }
  }
}

class ConfirmScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final AssessmentController controller;
  const ConfirmScreen({super.key, required this.result, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.accent), onPressed: () => Get.back()),
        title: const Text('Submit Result', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 20),
            const Icon(CupertinoIcons.check_mark_circled_solid, color: AppColors.green, size: 80),
            const SizedBox(height: 16),
            const Text('Thank you! Your result has been submitted.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(result['airlineName'] as String? ?? '', style: Theme.of(context).textTheme.titleMedium),
                  Text('${result['year']}', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                    const Text('Total Responses', style: TextStyle(color: AppColors.textPrimary)),
                    Text('${result['totalResponse']}', style: const TextStyle(color: AppColors.textPrimary)),
                  ]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                    const Text('Success Rate', style: TextStyle(color: AppColors.textPrimary)),
                    Text('${(result['successRate'] as double).toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.textPrimary)),
                  ]),
                ],
              ),
            ),
            const Spacer(),
            Row(children: <Widget>[
              Expanded(child: OutlinedButton(
                onPressed: () { controller.reset(); Get.back(); },
                child: const Text('Submit Another'),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Get.to(() => const StatisticsScreen()),
                child: const Text('View Statistics'),
              )),
            ]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
  );
}

class _PassFailButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final Color selectedBg;
  final bool selected;
  final VoidCallback onTap;
  const _PassFailButton({
    required this.label, required this.icon, required this.color,
    required this.borderColor, required this.selectedBg,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? selectedBg : AppColors.bgCard,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
      ),
    );
  }
}
