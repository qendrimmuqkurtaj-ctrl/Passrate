import 'dart:convert';
import 'dart:io';
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

  final RxBool isJobHunting = false.obs;
  final RxBool hasError = false.obs;
  bool _reminderShown = false;

  final RxString searchQuery = ''.obs;
  final RxString filterRank = ''.obs;
  final RxString filterCountry = ''.obs;
  final RxString filterBase = ''.obs;
  final RxString filterAircraftType = ''.obs;
  final RxString filterSeniority = ''.obs;
  final RxString limitedAirlineFilter = ''.obs;
  final RxList<String> airlineNames = <String>[].obs;
  Map<String, double> rates = <String, double>{};

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
    if (filterAircraftType.value.isNotEmpty) {
      list = list.where((Map<String, dynamic> s) =>
          (s['aircraftType'] as String? ?? '') == filterAircraftType.value).toList();
    }
    if (filterSeniority.value.isNotEmpty) {
      final String sel = filterSeniority.value;
      list = list.where((Map<String, dynamic> s) {
        final int seniority = (s['seniorityYears'] as num?)?.toInt() ?? 0;
        if (sel == '10+') return seniority >= 10;
        return seniority == (int.tryParse(sel) ?? -1);
      }).toList();
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
    matches.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final double eurA = toEur((a['baseSalary'] as num?)?.toDouble() ?? 0, a['currency'] as String? ?? '');
      final double eurB = toEur((b['baseSalary'] as num?)?.toDouble() ?? 0, b['currency'] as String? ?? '');
      return eurB.compareTo(eurA);
    });
    return matches.take(3).toList();
  }

  // Top 3 countries by the single highest-paid individual submission for the current user's rank.
  List<Map<String, dynamic>> get bestPaidCountriesForMyRank {
    if (myRank.isEmpty) return <Map<String, dynamic>>[];
    final Map<String, Map<String, dynamic>> bestByCountry = <String, Map<String, dynamic>>{};
    for (final Map<String, dynamic> s in salaries) {
      if (s['rank'] != myRank) continue;
      final String country = s['country'] as String? ?? '';
      if (country.isEmpty) continue;
      final double sal = (s['baseSalary'] as num?)?.toDouble() ?? 0;
      final String cur = s['currency'] as String? ?? '';
      final double eur = toEur(sal, cur);
      final Map<String, dynamic>? current = bestByCountry[country];
      if (current == null) {
        bestByCountry[country] = s;
      } else {
        final double currentEur = toEur(
          (current['baseSalary'] as num?)?.toDouble() ?? 0,
          current['currency'] as String? ?? '',
        );
        if (eur > currentEur) bestByCountry[country] = s;
      }
    }
    final List<Map<String, dynamic>> result = bestByCountry.entries.map((MapEntry<String, Map<String, dynamic>> e) {
      final double sal = (e.value['baseSalary'] as num?)?.toDouble() ?? 0;
      final String cur = e.value['currency'] as String? ?? '';
      return <String, dynamic>{
        'country': e.key,
        'salary': sal,
        'salaryEur': toEur(sal, cur),
        'currency': cur,
      };
    }).toList();
    result.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
        (b['salaryEur'] as double).compareTo(a['salaryEur'] as double));
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

  double toEur(double amount, String currency) {
    if (currency == 'EUR') return amount;
    final double rate = rates[currency] ?? 0;
    return rate > 0 ? amount / rate : 0;
  }

  @override
  void onInit() {
    super.onInit();
    _fetchAirlineNames();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    loading.value = true;
    hasError.value = false;
    try {
      const Duration timeout = Duration(seconds: 10);
      final String deviceId = await FirebaseService.getDeviceId();
      final Map<String, dynamic>? submission = await FirebaseService
          .getDeviceSalarySubmission(deviceId)
          .timeout(timeout);

      hasSubmitted.value = submission != null;
      existingDocId = submission?['id'] as String?;

      if (submission != null) {
        myRank = submission['rank'] as String? ?? '';
        myAircraftType = submission['aircraftType'] as String? ?? '';
        mySeniorityYears = (submission['seniorityYears'] as num?)?.toInt() ?? 0;
        final DateTime? updatedAt = submission['updatedAt'] as DateTime?;
        final DateTime? createdAt = submission['createdAt'] as DateTime?;
        final DateTime? effectiveDate = updatedAt ?? createdAt;
        isOutdated.value = effectiveDate == null || DateTime.now().difference(effectiveDate).inDays > 365;
        await _fetchRates();
        salaries.value = await FirebaseService.getAllSalaries().timeout(timeout);
        if (isOutdated.value && !_reminderShown) {
          _reminderShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _showSoftReminder());
        }
      } else if (isJobHunting.value) {
        myRank = '';
        myAircraftType = '';
        mySeniorityYears = 0;
        await _fetchRates();
        salaries.value = await FirebaseService.getAllSalaries().timeout(timeout);
      } else {
        myRank = '';
        myAircraftType = '';
        mySeniorityYears = 0;
      }
    } catch (_) {
      hasError.value = true;
    }
    loading.value = false;
  }

  Future<void> reload() => _load();

  Future<void> _fetchRates() async {
    try {
      final HttpClient client = HttpClient();
      final HttpClientRequest request = await client.getUrl(
        Uri.parse('https://open.er-api.com/v6/latest/EUR'),
      );
      final HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        final String body = await response.transform(utf8.decoder).join();
        client.close();
        final Map<String, dynamic> json = jsonDecode(body) as Map<String, dynamic>;
        if (json['result'] == 'success') {
          final Map<String, dynamic> r = json['rates'] as Map<String, dynamic>;
          rates = r.map((String k, dynamic v) => MapEntry(k, (v as num).toDouble()));
        }
      } else {
        client.close();
      }
    } catch (_) {}
  }

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

  Future<void> setJobHunting() async {
    loading.value = true;
    hasError.value = false;
    isJobHunting.value = true;
    try {
      if (salaries.isEmpty) {
        await _fetchRates();
        salaries.value = await FirebaseService.getAllSalaries()
            .timeout(const Duration(seconds: 10));
      }
    } catch (_) {
      hasError.value = true;
    }
    loading.value = false;
  }

  Future<void> confirmStillValid() async {
    if (existingDocId == null) return;
    await FirebaseService.updateSalaryTimestamp(existingDocId!);
    isOutdated.value = false;
  }

  void _showSoftReminder() {
    Get.dialog<void>(
      AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text(
          'Is your salary still current?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Your salary submission is over 12 months old. Is it still accurate?',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              Get.back();
              await confirmStillValid();
            },
            child: const Text('Yes, still valid', style: TextStyle(color: AppColors.accent)),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await Get.to(() => SubmitSalaryScreen(existingDocId: existingDocId));
              reload();
            },
            child: const Text('No, update it', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  List<Map<String, dynamic>> get limitedViewGroups {
    final Map<String, List<Map<String, dynamic>>> grouped = <String, List<Map<String, dynamic>>>{};
    for (final Map<String, dynamic> s in salaries) {
      final String airline = s['airline'] as String? ?? '';
      final String rank = s['rank'] as String? ?? '';
      final String aircraft = s['aircraftType'] as String? ?? '';
      if (airline.isEmpty) continue;
      final String key = '$airline\x00$rank\x00$aircraft';
      grouped[key] ??= <Map<String, dynamic>>[];
      grouped[key]!.add(s);
    }
    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];
    for (final MapEntry<String, List<Map<String, dynamic>>> entry in grouped.entries) {
      final List<String> parts = entry.key.split('\x00');
      final String airline = parts[0];
      final String rank = parts.length > 1 ? parts[1] : '';
      final String aircraft = parts.length > 2 ? parts[2] : '';
      final List<Map<String, dynamic>> entries = entry.value;
      if (entries.length >= 3) {
        final List<double> eurSalaries = entries
            .map((Map<String, dynamic> s) => toEur(
                  (s['baseSalary'] as num?)?.toDouble() ?? 0,
                  s['currency'] as String? ?? '',
                ))
            .where((double v) => v > 0)
            .toList()
          ..sort();
        result.add(<String, dynamic>{
          'airline': airline,
          'rank': rank,
          'aircraftType': aircraft,
          'hasData': eurSalaries.isNotEmpty,
          'minEur': eurSalaries.isEmpty ? 0.0 : eurSalaries.first,
          'maxEur': eurSalaries.isEmpty ? 0.0 : eurSalaries.last,
          'count': entries.length,
        });
      } else {
        result.add(<String, dynamic>{
          'airline': airline,
          'rank': rank,
          'aircraftType': aircraft,
          'hasData': false,
          'minEur': 0.0,
          'maxEur': 0.0,
          'count': entries.length,
        });
      }
    }
    result.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final int cmp = (a['airline'] as String).compareTo(b['airline'] as String);
      if (cmp != 0) return cmp;
      return (a['rank'] as String).compareTo(b['rank'] as String);
    });
    return result;
  }

  List<String> get limitedAirlines {
    return limitedViewGroups
        .map((Map<String, dynamic> g) => g['airline'] as String? ?? '')
        .where((String a) => a.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<Map<String, dynamic>> get filteredLimitedGroups {
    final String q = limitedAirlineFilter.value;
    if (q.isEmpty) return limitedViewGroups;
    return limitedViewGroups
        .where((Map<String, dynamic> g) => (g['airline'] as String? ?? '') == q)
        .toList();
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
        leading: Obx(() => IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.accent),
          onPressed: () {
            if (c.isJobHunting.value) {
              c.isJobHunting.value = false;
            } else {
              Get.back();
            }
          },
        )),
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
        if (c.hasError.value) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.wifi_off_outlined, color: AppColors.textMuted, size: 52),
                  const SizedBox(height: 20),
                  const Text(
                    'Something went wrong. Please try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => c.reload(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!c.hasSubmitted.value && !c.isJobHunting.value) {
          return _buildIntroView(c);
        }
        if (!c.hasSubmitted.value && c.isJobHunting.value) {
          return _buildLimitedView(c);
        }
        return _buildSearchPage(c);
      }),
    );
  }

  Widget _buildIntroView(SalaryController c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.monetization_on_outlined, color: AppColors.accent, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Pilot Salary Data',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 12),
            const Text(
              'Access real pilot salary data from airlines across Europe.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await Get.to(() => SubmitSalaryScreen(existingDocId: c.existingDocId));
                  c.reload();
                },
                child: const Text(
                  "I'm employed — submit my salary",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Submit your salary once to unlock exact figures, seniority data and full details from every pilot in our database.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => c.setJobHunting(),
                child: const Text(
                  "I'm seeking a position",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "View salary ranges across European airlines to know what to expect before your first offer.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 24),
            const Text(
              'Switched phones? Submit your salary again to restore full access.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitedView(SalaryController c) {
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.accent.withValues(alpha: 0.12),
          child: Row(
            children: <Widget>[
              const Icon(Icons.info_outline, color: AppColors.accent, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Submit your salary to see individual entries and advanced insights.',
                  style: TextStyle(color: AppColors.accent, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Obx(() => _SearchableFilterDrop(
            hint: 'Airline',
            value: c.limitedAirlineFilter.value.isEmpty ? null : c.limitedAirlineFilter.value,
            options: c.limitedAirlines,
            onChanged: (String? v) => c.limitedAirlineFilter.value = v ?? '',
          )),
        ),
        Expanded(
          child: Obx(() {
            final List<Map<String, dynamic>> groups = c.filteredLimitedGroups;
            if (groups.isEmpty) {
              return const Center(
                child: Text('No salary data available yet.', style: TextStyle(color: AppColors.textMuted)),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (BuildContext ctx, int i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LimitedGroupCard(group: groups[i]),
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await Get.to(() => SubmitSalaryScreen(existingDocId: c.existingDocId));
                c.reload();
              },
              child: const Text(
                'Submit Salary for Full Access',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
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
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: peers.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (BuildContext ctx, int i) => _PeerCard(
                        salary: peers[i],
                        rates: c.rates,
                        onTap: () => _showPeerProfile(ctx, peers[i], c.rates),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // ── Best paid countries ──────────────────────────────────
                Text(
                  'Best paid countries for ${c.myRank} pilots (based on submitted salaries)',
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
                    child: _SalaryCard(salary: s, rates: c.rates),
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
        Row(
          children: <Widget>[
            Expanded(
              child: Obx(() => _SearchableFilterDrop(
                hint: 'Aircraft',
                value: c.filterAircraftType.value.isEmpty ? null : c.filterAircraftType.value,
                options: kAircraftTypes,
                onChanged: (String? v) => c.filterAircraftType.value = v ?? '',
              )),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Obx(() => _FilterDrop(
                hint: 'Base/City',
                value: c.filterBase.value.isEmpty ? null : c.filterBase.value,
                options: c.availableBases,
                onChanged: (String? v) => c.filterBase.value = v ?? '',
              )),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() => _FilterDrop(
          hint: 'Seniority',
          value: c.filterSeniority.value.isEmpty ? null : c.filterSeniority.value,
          options: const <String>['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '10+'],
          onChanged: (String? v) => c.filterSeniority.value = v ?? '',
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

  void _showPeerProfile(BuildContext context, Map<String, dynamic> salary, Map<String, double> rates) {
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
            _SalaryCard(salary: salary, rates: rates),
          ],
        ),
      ),
    );
  }
}

class _LimitedGroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  const _LimitedGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final String airline = group['airline'] as String? ?? '-';
    final String rank = group['rank'] as String? ?? '-';
    final String aircraft = group['aircraftType'] as String? ?? '-';
    final bool hasData = group['hasData'] as bool? ?? false;
    final int count = group['count'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  airline,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text('$rank · $aircraft', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                Text(
                  '$count submission${count == 1 ? '' : 's'}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (hasData)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                const Text('Base Salary', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text(
                  '${_fmt(group['minEur'] as double)} – ${_fmt(group['maxEur'] as double)} EUR',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            )
          else
            const Text(
              'Not enough\ndata yet',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
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

double _toEur(double amount, String currency, Map<String, double> rates) {
  if (currency == 'EUR') return amount;
  final double rate = rates[currency] ?? 0;
  return rate > 0 ? amount / rate : 0;
}

class _PeerCard extends StatelessWidget {
  final Map<String, dynamic> salary;
  final VoidCallback onTap;
  final Map<String, double> rates;
  const _PeerCard({required this.salary, required this.onTap, required this.rates});

  @override
  Widget build(BuildContext context) {
    final double baseSalary = (salary['baseSalary'] as num?)?.toDouble() ?? 0;
    final String currency = salary['currency'] as String? ?? '';
    final String country = salary['country'] as String? ?? '-';
    final int seniority = (salary['seniorityYears'] as num?)?.toInt() ?? 0;
    final double eurSalary = _toEur(baseSalary, currency, rates);

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
              '${_fmt(baseSalary)} $currency',
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (currency != 'EUR' && eurSalary > 0)
              Text(
                '≈ ${_fmt(eurSalary)} EUR',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
          final double salary = (item['salary'] as double?) ?? 0;
          final double salaryEur = (item['salaryEur'] as double?) ?? 0;
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      currency == 'EUR'
                          ? '${_fmt(salary)} EUR'
                          : '${_fmt(salary)} $currency',
                      style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    if (currency != 'EUR' && salaryEur > 0)
                      Text(
                        '≈ ${_fmt(salaryEur)} EUR',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                  ],
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

class _SearchableFilterDrop extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _SearchableFilterDrop({
    required this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: value != null ? AppColors.accent : AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  color: value != null ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.accent, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FilterSearchSheet(hint: hint, items: options),
    );
    if (picked != null) onChanged(picked);
  }
}

class _FilterSearchSheet extends StatefulWidget {
  final String hint;
  final List<String> items;
  const _FilterSearchSheet({required this.hint, required this.items});

  @override
  State<_FilterSearchSheet> createState() => _FilterSearchSheetState();
}

class _FilterSearchSheetState extends State<_FilterSearchSheet> {
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.hint,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      child: Text(
                        'All ${widget.hint}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                    ),
                  );
                }
                final String item = _visible[i - 1];
                return InkWell(
                  onTap: () => Navigator.of(ctx).pop(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                    child: Text(item, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
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

class _SalaryCard extends StatelessWidget {
  final Map<String, dynamic> salary;
  final Map<String, double> rates;
  const _SalaryCard({required this.salary, required this.rates});

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
    final double eurBase = _toEur(baseSalary, currency, rates);
    final double eurPerDiem = _toEur(perDiem, currency, rates);

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
                      '${_fmt(baseSalary)} $currency',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (currency != 'EUR' && eurBase > 0)
                      Text(
                        '≈ ${_fmt(eurBase)} EUR',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                      '${_fmt(perDiem)} $currency',
                      style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    if (currency != 'EUR' && eurPerDiem > 0)
                      Text(
                        '≈ ${_fmt(eurPerDiem)} EUR',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
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
