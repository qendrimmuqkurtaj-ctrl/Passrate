import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/assessment_controller.dart';
import '../../../core/design/app_colors.dart';
import '../../home/screens/home_screen.dart';
import '../../statistics/screens/statistics_screen.dart';

class SubmitAssessmentScreen extends StatefulWidget {
  const SubmitAssessmentScreen({super.key});

  @override
  State<SubmitAssessmentScreen> createState() => _SubmitAssessmentScreenState();
}

class _SubmitAssessmentScreenState extends State<SubmitAssessmentScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(AssessmentController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.accent),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Submit Result',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: GetBuilder<AssessmentController>(
        builder: (AssessmentController c) => Column(
          children: <Widget>[
            // Fixed step progress header
            _buildStepHeader(c),

            // Scrollable form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[

                    // Airline dropdown
                    _FieldLabel('Airline Name'),
                    Obx(() {
                      if (c.loadingAirlines.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (c.loadingAirlinesError.value) {
                        return _ErrorRetry(
                          message: 'Could not load airlines.',
                          onRetry: c.loadAirlines,
                        );
                      }
                      return _buildAirlineDropdown(context, c);
                    }),
                    const SizedBox(height: 16),

                    // Date picker
                    _FieldLabel('Select Year and Month'),
                    _buildDatePicker(context, c),
                    const SizedBox(height: 16),

                    // Tasks — only show if airline selected
                    Obx(() => c.selectedAirline.value != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _FieldLabel('What was included in your assessment?'),
                              if (c.loadingTasks.value)
                                const Center(child: CircularProgressIndicator())
                              else if (c.loadingTasksError.value)
                                _ErrorRetry(
                                  message: 'Could not load tasks.',
                                  onRetry: c.loadTasks,
                                )
                              else if (c.tasks.isEmpty)
                                const Text('No tasks available',
                                  style: TextStyle(color: AppColors.textMuted))
                              else
                                _buildTaskChips(c),
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

                    // Submit button — only when all steps complete
                    Obx(() => c.allCompleted
                        ? SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: c.submitting.value ? null : () => _submit(c),
                              child: c.submitting.value
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Submit',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          )
                        : const SizedBox.shrink()),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step progress header (fixed) ──────────────────────────────────────────

  Widget _buildStepHeader(AssessmentController c) {
    final List<bool> done = <bool>[
      c.selectedAirline.value != null,
      c.dateController.text.isNotEmpty,
      c.selectedTaskIds.isNotEmpty,
      c.passed.value != null,
    ];
    final List<String> labels = <String>['Airline', 'Date', 'Tasks', 'Result'];
    final int doneCount = done.where((bool d) => d).length;

    return Container(
      color: AppColors.bgSecondary,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        children: <Widget>[
          Row(
            children: List<Widget>.generate(7, (int i) {
              if (i.isOdd) {
                final int leftIdx = i ~/ 2;
                return Expanded(
                  child: Container(
                    height: 1.5,
                    color: done[leftIdx] ? AppColors.accent : AppColors.border,
                  ),
                );
              }
              final int idx = i ~/ 2;
              return Column(
                children: <Widget>[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done[idx] ? AppColors.accent : AppColors.bgCard,
                      border: Border.all(
                        color: done[idx] ? AppColors.accent : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: done[idx]
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    labels[idx],
                    style: TextStyle(
                      color: done[idx] ? AppColors.textSecondary : AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: done[idx] ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: doneCount / 4,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Airline dropdown ──────────────────────────────────────────────────────

  Widget _buildAirlineDropdown(BuildContext context, AssessmentController c) {
    return _AirlineSearchableDropdown(
      hint: 'Choose the Airline Name',
      value: c.selectedAirline.value,
      items: c.airlines,
      onChanged: (Map<String, dynamic>? v) {
        if (v != null) c.selectAirline(v);
      },
    );
  }

  // ── Date picker ───────────────────────────────────────────────────────────

  Widget _buildDatePicker(BuildContext context, AssessmentController c) {
    return GestureDetector(
      onTap: () => _showMonthYearPicker(context, c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                c.dateController.text.isEmpty
                    ? 'Choose the year of assessment'
                    : c.dateController.text,
                style: TextStyle(
                  color: c.dateController.text.isEmpty
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  fontSize: 14,
                ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx2, StateSetter setState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Select Year and Month',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text('Year:', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  Row(
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(CupertinoIcons.chevron_left, color: AppColors.textPrimary),
                        onPressed: () => setState(() { if (selectedYear > 2024) selectedYear--; }),
                      ),
                      Text('$selectedYear',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      IconButton(
                        icon: const Icon(CupertinoIcons.chevron_right, color: AppColors.textPrimary),
                        onPressed: () => setState(() {
                          if (selectedYear < now.year) {
                            selectedYear++;
                            if (selectedYear == now.year && selectedMonth > now.month) {
                              selectedMonth = now.month;
                            }
                          }
                        }),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (BuildContext context, int i) {
                  final int month = i + 1;
                  final bool isSelected = selectedMonth == month;
                  final bool isFuture = selectedYear == now.year && month > now.month;
                  return GestureDetector(
                    onTap: isFuture ? null : () => setState(() => selectedMonth = month),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          DateFormat('MMM').format(DateTime(2024, month)),
                          style: TextStyle(
                            color: isFuture
                                ? AppColors.textMuted.withValues(alpha: 0.4)
                                : (isSelected ? Colors.white : AppColors.textPrimary),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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

  // ── Task chips ────────────────────────────────────────────────────────────

  Widget _buildTaskChips(AssessmentController c) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: c.tasks.map((Map<String, dynamic> task) {
        final String id = task['id'] as String;
        final String name = task['name'] as String;
        final String label = name.isNotEmpty
            ? '${name[0].toUpperCase()}${name.substring(1)}'
            : name;
        final bool selected = c.selectedTaskIds.contains(id);
        return GestureDetector(
          onTap: () => c.toggleTask(task),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.13)
                  : AppColors.bgCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
                width: selected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (selected) ...<Widget>[
                  const Icon(Icons.check, size: 13, color: AppColors.accent),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.accent : AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit(AssessmentController c) async {
    final Map<String, dynamic>? result = await c.submitAssessment();
    if (result != null) {
      Get.to(() => ConfirmScreen(result: result, controller: c));
    } else {
      Get.snackbar('Error', 'Could not submit. Please try again.',
        snackPosition: SnackPosition.BOTTOM);
    }
  }
}

// ── Confirm screen ─────────────────────────────────────────────────────────────

class ConfirmScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final AssessmentController controller;
  const ConfirmScreen({super.key, required this.result, required this.controller});

  Color _rateColor(double rate) {
    if (rate >= 80) return AppColors.passText;
    if (rate >= 60) return const Color(0xFFE8A020);
    return AppColors.failText;
  }

  @override
  Widget build(BuildContext context) {
    final double successRate = result['successRate'] as double;
    final int total = result['totalResponse'] as int;
    final Color rateColor = _rateColor(successRate);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.accent),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Submit Result',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 24),
            const Icon(CupertinoIcons.check_mark_circled_solid,
              color: AppColors.green, size: 72),
            const SizedBox(height: 14),
            const Text(
              'Result submitted!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thank you for helping the community.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 28),

            // Stats card with accent left border
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(width: 3, color: AppColors.accent),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              result['airlineName'] as String? ?? '',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              DateFormat('MMMM yyyy').format(
                                DateTime(result['year'] as int, result['month'] as int),
                              ),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Column(
                                children: <Widget>[
                                  Text(
                                    '${successRate.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: rateColor,
                                      fontSize: 52,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -2,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'overall pass rate',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'from $total submission${total == 1 ? '' : 's'}',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () { controller.reset(); Get.back(); },
                    child: const Text('Submit Another'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.offAll(() => const HomeScreen());
                      Get.to(() => const StatisticsScreen());
                    },
                    child: const Text('View Pass Rates'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Shared helper widgets ──────────────────────────────────────────────────────

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.wifi_off_outlined, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry', style: TextStyle(color: AppColors.accent, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _AirlineSearchableDropdown extends StatelessWidget {
  final String hint;
  final Map<String, dynamic>? value;
  final List<Map<String, dynamic>> items;
  final ValueChanged<Map<String, dynamic>?> onChanged;

  const _AirlineSearchableDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                value != null ? value!['name'] as String : hint,
                style: TextStyle(
                  color: value != null ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.accent),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final Map<String, dynamic>? picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AirlineSearchSheet(hint: hint, items: items),
    );
    if (picked != null) onChanged(picked);
  }
}

class _AirlineSearchSheet extends StatefulWidget {
  final String hint;
  final List<Map<String, dynamic>> items;
  const _AirlineSearchSheet({required this.hint, required this.items});

  @override
  State<_AirlineSearchSheet> createState() => _AirlineSearchSheetState();
}

class _AirlineSearchSheetState extends State<_AirlineSearchSheet> {
  final TextEditingController _ctrl = TextEditingController();
  late List<Map<String, dynamic>> _visible;

  @override
  void initState() {
    super.initState();
    _visible = widget.items;
    _ctrl.addListener(_filter);
  }

  void _filter() {
    final String q = _ctrl.text.toLowerCase();
    setState(() {
      _visible = q.isEmpty
          ? widget.items
          : widget.items
              .where((Map<String, dynamic> a) =>
                  (a['name'] as String).toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.hint,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                filled: true,
                fillColor: AppColors.bgPrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: _visible.length,
              itemBuilder: (BuildContext ctx, int i) => InkWell(
                onTap: () => Navigator.of(ctx).pop(_visible[i]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  child: Text(_visible[i]['name'] as String,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
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
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
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
    required this.label,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.selectedBg,
    required this.selected,
    required this.onTap,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
