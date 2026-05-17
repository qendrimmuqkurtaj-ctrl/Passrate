import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/services/firebase_service.dart';
import 'submit_salary_screen.dart';

class SalaryController extends GetxController {
  final RxBool loading = true.obs;
  final RxBool hasSubmitted = false.obs;
  final RxBool isOutdated = false.obs;
  final RxList<Map<String, dynamic>> salaries = <Map<String, dynamic>>[].obs;
  String? existingDocId;
  String myRank = '';
  String myAircraftType = '';
  int mySeniorityYears = 0;

  final RxString searchQuery = ''.obs;
  final RxString filterRank = ''.obs;
  final RxString filterCountry = ''.obs;
  final RxString filterBase = ''.obs;
  final RxList<String> airlineNames = <String>[].obs;

  List<Map<String, dynamic>> get filtered {
    List<Map<String, dynamic>> list = salaries.toList();
    final String q = searchQuery.value.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((Map<String, dynamic> s) =>
          (s['airline'] as String? ?? '').toLowerCase().contains(q)).toList();
    }
    if (filterRank.value.isNotEmpty) {
      list = list.where((Map<String, dynamic> s) => s['rank'] == filterRank.value).toList();
    }
    if (filterCountry.value.isNotEmpty) {
      list = list.where((Map<String, dynamic> s) =>
          (s['country'] as String? ?? '') == filterCountry.value).toList();
    }
    if (filterBase.value.isNotEmpty) {
      list = list.where((Map<String, dynamic> s) =>
          (s['base'] as String? ?? '') == filterBase.value).toList();
    }
    return list;
  }

  // Top 3 highest-paid submissions matching user's rank and aircraft type.
  List<Map<String, dynamic>> get pilotsLikeMe {
    if (myRank.isEmpty || myAircraftType.isEmpty) return <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> matches = salaries
        .where((Map<String, dynamic> s) {
          if (s['rank'] != myRank || s['aircraftType'] != myAircraftType) return false;
          final int seniority = (s['seniorityYears'] as num?)?.toInt() ?? 0;
          return seniority == mySeniorityYears;
        })
        .toList();
    matches.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
        ((b['baseSalary'] as num?)?.toDouble() ?? 0)
            .compareTo((a['baseSalary'] as num?)?.toDouble() ?? 0));
    return matches.take(3).toList();
  }

  // Top 3 countries by average base salary for the current user's rank.
  List<Map<String, dynamic>> get bestPaidCountriesForMyRank {
    if (myRank.isEmpty) return <Map<String, dynamic>>[];
    final Map<String, List<double>> salariesByCountry = <String, List<double>>{};
    final Map<String, Map<String, int>> currencyByCountry = <String, Map<String, int>>{};
    for (final Map<String, dynamic> s in salaries) {
      if (s['rank'] != myRank) continue;
      final String country = s['country'] as String? ?? '';
      if (country.isEmpty) continue;
      final double sal = (s['baseSalary'] as num?)?.toDouble() ?? 0;
      final String cur = s['currency'] as String? ?? '';
      salariesByCountry[country] ??= <double>[];
      salariesByCountry[country]!.add(sal);
      currencyByCountry[country] ??= <String, int>{};
      currencyByCountry[country]![cur] = (currencyByCountry[country]![cur] ?? 0) + 1;
    }
    final List<Map<String, dynamic>> result = salariesByCountry.entries
        .map((MapEntry<String, List<double>> e) {
          final double avg = e.value.reduce((double a, double b) => a + b) / e.value.length;
          final String currency = (currencyByCountry[e.key]!.entries.toList()
                ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
                    b.value.compareTo(a.value)))
              .first
              .key;
          return <String, dynamic>{'country': e.key, 'avgSalary': avg, 'currency': currency};
        })
        .toList();
    result.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
        (b['avgSalary'] as double).compareTo(a['avgSalary'] as double));
    return result.take(3).toList();
  }

  List<String> get availableCountries {
    return salaries
        .map((Map<String, dynamic> s) => s['country'] as String? ?? '')
        .where((String c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> get availableBases {
    return salaries
        .map((Map<String, dynamic> s) => s['base'] as String? ?? '')
        .where((String b) => b.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  void onInit() {
    super.onInit();
    _fetchAirlineNames();
    _load();
  }

  Future<void> _load() async {
    loading.value = true;
    final String deviceId = await FirebaseService.getDeviceId();
    final Map<String, dynamic>? submission = await FirebaseService.getDeviceSalarySubmission(deviceId);

    hasSubmitted.value = submission != null;
    existingDocId = submission?['id'] as String?;

    if (submission != null) {
      myRank = submission['rank'] as String? ?? '';
      myAircraftType = submission['aircraftType'] as String? ?? '';
      mySeniorityYears = (submission['seniorityYears'] as num?)?.toInt() ?? 0;
      final DateTime? createdAt = submission['createdAt'] as DateTime?;
      isOutdated.value = createdAt == null || DateTime.now().difference(createdAt).inDays > 365;
      if (!isOutdated.value) {
        salaries.value = await FirebaseService.getAllSalaries();
      }
    } else {
      myRank = '';
      myAircraftType = '';
      mySeniorityYears = 0;
    }

    loading.value = false;
  }

  Future<void> reload() => _load();

  Future<void> _fetchAirlineNames() async {
    final List<Map<String, dynamic>> list = await FirebaseService.getAirlines();
    airlineNames.value = list
        .map((Map<String, dynamic> m) => m['name'] as String)
        .toList();
  }

  Future<void> deleteMySalary() async {
    if (existingDocId == null) return;
    await FirebaseService.deleteSalary(existingDocId!);
    existingDocId = null;
    myRank = '';
    myAircraftType = '';
    mySeniorityYears = 0;
    salaries.clear();
    hasSubmitted.value = false;
    isOutdated.value = false;
  }
}

class SalaryScreen extends StatelessWidget {
  const SalaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SalaryController c = Get.put(SalaryController());

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
          'Pilot Salaries',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (c.loading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        if (!c.hasSubmitted.value) {
          return _buildLockedView(
            c,
            message: 'Submit your salary to unlock all pilot salaries',
            buttonLabel: 'Submit Salary',
          );
        }
        if (c.isOutdated.value) {
          return _buildLockedView(
            c,
            message: 'Your salary data is outdated. Please update to continue viewing salaries.',
            buttonLabel: 'Update Salary',
          );
        }
        return _buildSearchPage(c);
      }),
    );
  }

  Widget _buildLockedView(SalaryController c, {required String message, required String buttonLabel}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 64),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await Get.to(() => SubmitSalaryScreen(existingDocId: c.existingDocId));
                  c.reload();
                },
                child: Text(buttonLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchPage(SalaryController c) {
    return Column(
      children: <Widget>[
        // Search bar + filters (fixed)
        Container(
          color: AppColors.bgPrimary,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            children: <Widget>[
              _buildSearchBar(c),
              const SizedBox(height: 8),
              _buildFilters(c),
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: Obx(() {
            final List<Map<String, dynamic>> results = c.filtered;
            final List<Map<String, dynamic>> peers = c.pilotsLikeMe;
            final List<Map<String, dynamic>> bestCountries = c.bestPaidCountriesForMyRank;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: <Widget>[

                // ── Pilots like you ──────────────────────────────────────
                const Text(
                  'Pilots like you',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                if (peers.isEmpty)
                  _buildEmptyInsightCard('Not enough data yet — check back later')
                else
                  SizedBox(
                    height: 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: peers.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (BuildContext ctx, int i) => _PeerCard(
                        salary: peers[i],
                        onTap: () => _showPeerProfile(ctx, peers[i]),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // ── Best paid countries ──────────────────────────────────
                Text(
                  'Best paid countries for ${c.myRank}',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                if (bestCountries.isEmpty)
                  _buildEmptyInsightCard('Not enough data yet')
                else
                  _BestCountriesCard(countries: bestCountries),

                const SizedBox(height: 16),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 10),

                // ── Results count ────────────────────────────────────────
                Text(
                  '${results.length} result${results.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 10),

                // ── Salary cards ─────────────────────────────────────────
                if (results.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text('No results found.', style: TextStyle(color: AppColors.textMuted)),
                    ),
                  )
                else
                  ...results.map((Map<String, dynamic> s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SalaryCard(salary: s),
                  )),
              ],
            );
          }),
        ),

        // Update / Delete buttons (fixed at bottom)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await Get.to(() => SubmitSalaryScreen(existingDocId: c.existingDocId));
                    c.reload();
                  },
                  child: const Text('Update Salary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () => _confirmDelete(c),
                child: const Text('Delete', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(SalaryController c) {
    return Obx(() => _FilterDrop(
      hint: 'Airline',
      value: c.searchQuery.value.isEmpty ? null : c.searchQuery.value,
      options: c.airlineNames.toList(),
      onChanged: (String? v) => c.searchQuery.value = v ?? '',
    ));
  }

  Widget _buildFilters(SalaryController c) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Obx(() => _FilterDrop(
                hint: 'Rank',
                value: c.filterRank.value.isEmpty ? null : c.filterRank.value,
                options: const <String>['SO', 'FO', 'Captain'],
                onChanged: (String? v) => c.filterRank.value = v ?? '',
              )),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Obx(() => _FilterDrop(
                hint: 'Country',
                value: c.filterCountry.value.isEmpty ? null : c.filterCountry.value,
                options: c.availableCountries,
                onChanged: (String? v) => c.filterCountry.value = v ?? '',
              )),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() => _FilterDrop(
          hint: 'Base/City',
          value: c.filterBase.value.isEmpty ? null : c.filterBase.value,
          options: c.availableBases,
          onChanged: (String? v) => c.filterBase.value = v ?? '',
        )),
      ],
    );
  }

  Widget _buildEmptyInsightCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
    );
  }

  Future<void> _confirmDelete(SalaryController c) async {
    final bool? confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete salary?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This will permanently remove your salary submission.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await c.deleteMySalary();
    }
  }

  void _showPeerProfile(BuildContext context, Map<String, dynamic> salary) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Pilot Profile',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _SalaryCard(salary: salary),
          ],
        ),
      ),
    );
  }
}

class _PeerCard extends StatelessWidget {
  final Map<String, dynamic> salary;
  final VoidCallback onTap;
  const _PeerCard({required this.salary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double baseSalary = (salary['baseSalary'] as num?)?.toDouble() ?? 0;
    final String currency = salary['currency'] as String? ?? '';
    final String country = salary['country'] as String? ?? '-';
    final int seniority = (salary['seniorityYears'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '$currency ${_fmt(baseSalary)}',
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(country, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            Text('$seniority yr seniority', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) => v.truncate().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (Match m) => ',',
  );
}

class _BestCountriesCard extends StatelessWidget {
  final List<Map<String, dynamic>> countries;
  const _BestCountriesCard({required this.countries});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: countries.asMap().entries.map((MapEntry<int, Map<String, dynamic>> e) {
          final int idx = e.key;
          final Map<String, dynamic> item = e.value;
          final double avg = (item['avgSalary'] as double?) ?? 0;
          final String currency = item['currency'] as String? ?? '';
          final String country = item['country'] as String? ?? '-';
          final bool isLast = idx == countries.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 20,
                  child: Text(
                    '${idx + 1}',
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(country, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                ),
                Text(
                  '$currency ${_fmt(avg)} avg',
                  style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _fmt(double v) => v.truncate().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (Match m) => ',',
  );
}

class _FilterDrop extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _FilterDrop({
    required this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: value != null ? AppColors.accent : AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.accent, size: 18),
          dropdownColor: AppColors.bgCard,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          items: <DropdownMenuItem<String?>>[
            DropdownMenuItem<String?>(
              value: null,
              child: Text('All $hint', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ),
            ...options.map((String o) => DropdownMenuItem<String?>(
              value: o,
              child: Text(o, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
            )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SalaryCard extends StatelessWidget {
  final Map<String, dynamic> salary;
  const _SalaryCard({required this.salary});

  @override
  Widget build(BuildContext context) {
    final String airline = salary['airline'] as String? ?? '-';
    final String rank = salary['rank'] as String? ?? '-';
    final int seniority = (salary['seniorityYears'] as num?)?.toInt() ?? 0;
    final String aircraft = salary['aircraftType'] as String? ?? '-';
    final String contract = salary['contractType'] as String? ?? '-';
    final double baseSalary = (salary['baseSalary'] as num?)?.toDouble() ?? 0;
    final double perDiem = (salary['perDiem'] as num?)?.toDouble() ?? 0;
    final String country = salary['country'] as String? ?? '-';
    final String base = salary['base'] as String? ?? '-';
    final String currency = salary['currency'] as String? ?? '';

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  airline,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(rank, style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Row('Aircraft', aircraft),
          _Row('Contract', contract),
          _Row('Seniority', '$seniority yr'),
          _Row('Country', country),
          _Row('Base/City', base),
          const SizedBox(height: 8),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Base Salary', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      '$currency ${_fmt(baseSalary)}',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Per Diem', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      '$currency ${_fmt(perDiem)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => v.truncate().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (Match m) => ',',
  );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: <Widget>[
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
        Expanded(child: Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
      ],
    ),
  );
}
