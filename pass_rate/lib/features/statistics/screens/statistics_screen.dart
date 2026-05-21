import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/statistics_controller.dart';
import '../../../core/design/app_colors.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(StatisticsController());
  }

  String _yearLabel(int year) => year == 0 ? 'All Time' : '$year';
  String _airlineLabel(String name) => name.isEmpty ? 'All Airlines' : name;

  Color _rateColor(double rate) {
    if (rate >= 80) return AppColors.passText;
    if (rate >= 60) return const Color(0xFFE8A020);
    return AppColors.failText;
  }

  Color _rankColor(int rank) {
    if (rank == 0) return const Color(0xFFD4A017);
    if (rank == 1) return const Color(0xFF9EA0A5);
    if (rank == 2) return const Color(0xFFC17F40);
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final StatisticsController c = Get.find<StatisticsController>();

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
          'Statistics Overview',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Check Pass Rates & Assessment Content',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),

            // Search panel — airline + year + button grouped in a card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: <Widget>[
                  Obx(() => _buildAirlineDropdown(context, c)),
                  const SizedBox(height: 10),
                  Obx(() => _buildYearPicker(context, c)),
                  const SizedBox(height: 14),
                  Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: c.isLoadingSearch.value ? null : () => c.searchStatistics(),
                      icon: c.isLoadingSearch.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(CupertinoIcons.search, color: Colors.white, size: 16),
                      label: Text(
                        c.isLoadingSearch.value ? 'Searching…' : 'Search',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search results
            Obx(() {
              if (c.isLoadingSearch.value) return _buildSearchResultSkeleton();
              final Map<String, dynamic>? stats = c.airlineStats.value;
              if (stats != null) return _buildSearchResult(c, stats);
              if (c.hasSearched.value) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No results for ${_airlineLabel(c.selectedAirlineName.value)} in ${_yearLabel(c.searchYear.value)}. Try a different year.',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            const SizedBox(height: 8),
            const Text(
              'Top Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            Obx(() => _buildTopCard(
              context: context,
              title: 'Top Airlines by Pass Rate',
              selectedYear: c.filterYearPassRate.value,
              isLoading: c.isLoadingPassRate.value,
              items: c.topByPassRate,
              valueBuilder: (Map<String, dynamic> item) =>
                  '${(item['successRate'] as double).toStringAsFixed(1)}%',
              relativeValue: (Map<String, dynamic> item) {
                if (c.topByPassRate.isEmpty) return 0.0;
                final double max = c.topByPassRate.first['successRate'] as double;
                return max > 0 ? (item['successRate'] as double) / max : 0.0;
              },
              nameBuilder: (Map<String, dynamic> item) => item['name'] as String,
              onYearSelected: (int y) {
                c.filterYearPassRate.value = y;
                c.loadTopByPassRate();
              },
            )),
            const SizedBox(height: 12),

            Obx(() => _buildTopCard(
              context: context,
              title: 'Top Airlines by Submission Count',
              selectedYear: c.filterYearSubmission.value,
              isLoading: c.isLoadingSubmission.value,
              items: c.topBySubmission,
              valueBuilder: (Map<String, dynamic> item) => '${item['submissionCount']}',
              relativeValue: (Map<String, dynamic> item) {
                if (c.topBySubmission.isEmpty) return 0.0;
                final int max = c.topBySubmission.first['submissionCount'] as int;
                return max > 0 ? (item['submissionCount'] as int) / max : 0.0;
              },
              nameBuilder: (Map<String, dynamic> item) => item['name'] as String,
              onYearSelected: (int y) {
                c.filterYearSubmission.value = y;
                c.loadTopBySubmission();
              },
            )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ── Airline picker ────────────────────────────────────────────────────────

  Widget _buildAirlineDropdown(BuildContext context, StatisticsController c) {
    if (c.assessmentController.loadingAirlines.value) {
      return const Center(child: CircularProgressIndicator());
    }
    final List<String> names = c.assessmentController.airlines
        .map((Map<String, dynamic> a) => a['name'] as String)
        .toList();
    return GestureDetector(
      onTap: () async {
        final String? picked = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: AppColors.bgCard,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => _AirlineSearchSheet(items: names),
        );
        if (picked != null) c.selectedAirlineName.value = picked;
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Airline', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    _airlineLabel(c.selectedAirlineName.value),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.accent),
          ],
        ),
      ),
    );
  }

  // ── Year picker ───────────────────────────────────────────────────────────

  Widget _buildYearPicker(BuildContext context, StatisticsController c) {
    return GestureDetector(
      onTap: () => _showYearPickerDialog(context, c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Year', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(_yearLabel(c.searchYear.value),
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                ],
              ),
            ),
            const Icon(CupertinoIcons.calendar, color: AppColors.accent, size: 18),
          ],
        ),
      ),
    );
  }

  void _showYearPickerDialog(BuildContext context, StatisticsController c) {
    final List<int> years = <int>[
      0,
      ...List<int>.generate(DateTime.now().year - 2024 + 1, (int i) => DateTime.now().year - i),
    ];
    Get.dialog<void>(Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Select Year',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: years.length,
                itemBuilder: (BuildContext ctx, int i) => ListTile(
                  title: Text(_yearLabel(years[i]),
                    style: const TextStyle(color: AppColors.textPrimary)),
                  trailing: c.searchYear.value == years[i]
                      ? const Icon(CupertinoIcons.check_mark, color: AppColors.accent)
                      : null,
                  onTap: () {
                    if (years[i] == 0) c.selectedAirlineName.value = '';
                    c.searchYear.value = years[i];
                    Get.back();
                  },
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.failText)),
            ),
          ],
        ),
      ),
    ));
  }

  // ── Search result skeleton ─────────────────────────────────────────────────

  Widget _buildSearchResultSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _skeleton(14, fixedWidth: 180),
          const SizedBox(height: 8),
          _skeleton(10, fixedWidth: 80),
          const SizedBox(height: 28),
          Center(child: _skeleton(52, fixedWidth: 110)),
          const SizedBox(height: 8),
          Center(child: _skeleton(10, fixedWidth: 70)),
          const SizedBox(height: 24),
          _skeleton(140),
        ],
      ),
    );
  }

  Widget _skeleton(double height, {double? fixedWidth}) => Container(
    height: height,
    width: fixedWidth,
    decoration: BoxDecoration(
      color: AppColors.border.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(6),
    ),
  );

  // ── Search result card ────────────────────────────────────────────────────

  Widget _buildSearchResult(StatisticsController c, Map<String, dynamic> stats) {
    final Map<int, int> monthlyData = Map<int, int>.from(stats['monthlyData'] as Map);
    final List<String> assessments = List<String>.from(stats['assessments'] as List);
    final int maxVal = monthlyData.values.isEmpty
        ? 1
        : monthlyData.values.reduce((int a, int b) => a > b ? a : b);
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final double successRate = stats['successRate'] as double;
    final int total = stats['totalSubmissions'] as int;
    final int pass = stats['pass'] as int;
    final int fail = stats['fail'] as int;
    final Color rateColor = _rateColor(successRate);

    final int peakMonth = maxVal > 0
        ? monthlyData.entries
            .reduce((MapEntry<int, int> a, MapEntry<int, int> b) =>
                a.value >= b.value ? a : b)
            .key
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Search Result',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
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

                        // Airline + year header
                        Text(stats['airlineName'] as String,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          )),
                        const SizedBox(height: 2),
                        Text(_yearLabel(stats['year'] as int),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        const SizedBox(height: 20),

                        // Hero: pass rate
                        Center(
                          child: Column(
                            children: <Widget>[
                              Text(
                                '${successRate.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: rateColor,
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -2,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text('Pass Rate',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  _StatPill(
                                    icon: CupertinoIcons.checkmark_circle_fill,
                                    label: '$pass passed',
                                    color: AppColors.passText,
                                    bg: AppColors.passBg,
                                  ),
                                  const SizedBox(width: 10),
                                  _StatPill(
                                    icon: CupertinoIcons.xmark_circle_fill,
                                    label: '$fail failed',
                                    color: AppColors.failText,
                                    bg: AppColors.failBg,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$total total submission${total == 1 ? '' : 's'}',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 16),

                        // Bar chart
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Text('Monthly Distribution',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              )),
                            if (peakMonth > 0)
                              Text('peak: ${months[peakMonth - 1]}',
                                style: const TextStyle(color: AppColors.accent, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 180,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List<Widget>.generate(12, (int i) {
                              final int count = monthlyData[i + 1] ?? 0;
                              final bool isPeak = (i + 1) == peakMonth && count > 0;
                              final double barH = maxVal > 0
                                  ? (count / maxVal * 120).clamp(2.0, 120.0)
                                  : 2.0;
                              return Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    if (count > 0)
                                      Text(
                                        '$count',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isPeak ? AppColors.accent : AppColors.textMuted,
                                          fontWeight: isPeak ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    const SizedBox(height: 3),
                                    Container(
                                      height: barH,
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      decoration: BoxDecoration(
                                        color: isPeak
                                            ? AppColors.accent
                                            : AppColors.accent.withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(months[i],
                                      style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),

                        // Assessment chips — hidden for All Time (cross-year data is not meaningful per task)
                        if (assessments.isNotEmpty && stats['year'] != 0) ...<Widget>[
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.border, height: 1),
                          const SizedBox(height: 14),
                          const Text('Assessment Content',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            )),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: assessments.map((String a) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '${a[0].toUpperCase()}${a.substring(1)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Top card ──────────────────────────────────────────────────────────────

  Widget _buildTopCard({
    required BuildContext context,
    required String title,
    required int selectedYear,
    required bool isLoading,
    required List<Map<String, dynamic>> items,
    required String Function(Map<String, dynamic>) valueBuilder,
    required double Function(Map<String, dynamic>) relativeValue,
    required String Function(Map<String, dynamic>) nameBuilder,
    required Function(int) onYearSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
              ),
              GestureDetector(
                onTap: () => _showYearDialog(context, selectedYear, onYearSelected),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(_yearLabel(selectedYear),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w500,
                        )),
                      const SizedBox(width: 3),
                      const Icon(CupertinoIcons.chevron_down, size: 10, color: AppColors.accent),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1.5, color: AppColors.accent.withValues(alpha: 0.4)),
          const SizedBox(height: 14),

          if (isLoading)
            Column(
              children: <Widget>[
                _skeleton(40),
                const SizedBox(height: 10),
                _skeleton(40),
                const SizedBox(height: 10),
                _skeleton(40),
              ],
            )
          else if (items.isEmpty)
            Row(
              children: <Widget>[
                const Icon(Icons.bar_chart_outlined, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 10),
                Text('No data for ${_yearLabel(selectedYear)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            )
          else
            ...items.asMap().entries.map((MapEntry<int, Map<String, dynamic>> entry) {
              final int rank = entry.key;
              final Map<String, dynamic> item = entry.value;
              final Color rankColor = _rankColor(rank);
              final double rel = relativeValue(item).clamp(0.0, 1.0);

              return Padding(
                padding: EdgeInsets.only(bottom: rank < items.length - 1 ? 14 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: rankColor.withValues(alpha: 0.12),
                        border: Border.all(color: rankColor.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '${rank + 1}',
                          style: TextStyle(
                            color: rankColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(nameBuilder(item),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 8),
                              Text(valueBuilder(item),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: rankColor,
                                )),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: rel,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                rankColor.withValues(alpha: 0.65),
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showYearDialog(BuildContext context, int currentYear, Function(int) onSelected) {
    final List<int> years = <int>[
      0,
      ...List<int>.generate(DateTime.now().year - 2024 + 1, (int i) => DateTime.now().year - i),
    ];
    Get.dialog<void>(Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Select Year',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: years.length,
                itemBuilder: (BuildContext ctx, int i) => ListTile(
                  title: Text(_yearLabel(years[i]),
                    style: const TextStyle(color: AppColors.textPrimary)),
                  trailing: currentYear == years[i]
                      ? const Icon(CupertinoIcons.check_mark, color: AppColors.accent)
                      : null,
                  onTap: () { Get.back(); onSelected(years[i]); },
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.failText)),
            ),
          ],
        ),
      ),
    ));
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

// ── Airline search sheet ───────────────────────────────────────────────────────

class _AirlineSearchSheet extends StatefulWidget {
  final List<String> items;
  const _AirlineSearchSheet({required this.items});

  @override
  State<_AirlineSearchSheet> createState() => _AirlineSearchSheetState();
}

class _AirlineSearchSheetState extends State<_AirlineSearchSheet> {
  final TextEditingController _ctrl = TextEditingController();
  late List<String> _visible;

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
          : widget.items.where((String s) => s.toLowerCase().contains(q)).toList();
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Airline Name',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
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
              itemCount: _visible.length + 1,
              itemBuilder: (BuildContext ctx, int i) {
                if (i == 0) {
                  return InkWell(
                    onTap: () => Navigator.of(ctx).pop(''),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      child: Text('All Airlines',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    ),
                  );
                }
                return InkWell(
                  onTap: () => Navigator.of(ctx).pop(_visible[i - 1]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                    child: Text(_visible[i - 1],
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
