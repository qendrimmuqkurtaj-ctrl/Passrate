import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/services/firebase_service.dart';
import 'submit_salary_screen.dart';

class SalaryController extends GetxController {
  final RxBool loading = true.obs;
  final RxBool hasSubmitted = false.obs;
  final RxBool isOutdated = false.obs;
  final RxList<Map<String, dynamic>> salaries = <Map<String, dynamic>>[].obs;
  String? existingDocId;
  Map<String, dynamic>? mySubmission;
  String myRank = '';
  String myAircraftType = '';
  int mySeniorityYears = 0;
  String myAmountType = '';
  int myFlightHours = 0;

  final RxBool isJobHunting = false.obs;
  final RxBool hasError = false.obs;
  bool _reminderShown = false;

  final RxString searchQuery = ''.obs;
  final RxString filterRank = ''.obs;
  final RxString filterCountry = ''.obs;
  final RxString filterBase = ''.obs;
  final RxString filterAircraftType = ''.obs;
  final RxString filterSeniority = ''.obs;
  final RxString filterAmountType = ''.obs;
  final RxString filterFlightHours = ''.obs;
  final RxString sortBy = 'base'.obs;
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
        if (sel == '<3y') return seniority > 0 && seniority < 3;
        if (sel == '3-6y') return seniority >= 3 && seniority <= 6;
        if (sel == '7-10y') return seniority >= 7 && seniority <= 10;
        if (sel == '11-15y') return seniority >= 11 && seniority <= 15;
        if (sel == '16-20y') return seniority >= 16 && seniority <= 20;
        if (sel == '20+y') return seniority > 20;
        return true;
      }).toList();
    }
    if (filterAmountType.value.isNotEmpty) {
      final String amt = filterAmountType.value;
      list = list.where((Map<String, dynamic> s) {
        final String t = (s['amountType'] as String? ?? '').toLowerCase();
        if (amt == 'gross') return t.startsWith('gross');
        if (amt == 'net') return t.startsWith('net');
        return true;
      }).toList();
    }
    if (filterFlightHours.value.isNotEmpty) {
      final String sel = filterFlightHours.value;
      list = list.where((Map<String, dynamic> s) {
        final int hours = (s['totalFlightHours'] as num?)?.toInt() ?? 0;
        if (sel == '<500h') return hours > 0 && hours < 500;
        if (sel == '500-1500h') return hours >= 500 && hours <= 1500;
        if (sel == '1500-3000h') return hours > 1500 && hours <= 3000;
        if (sel == '3000-5000h') return hours > 3000 && hours <= 5000;
        if (sel == '5000+h') return hours > 5000;
        return true;
      }).toList();
    }
    final String sort = sortBy.value;
    list.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      if (sort == 'typical') {
        final double? aVal = (a['allInMonthlyEstimate'] as num?)?.toDouble() ?? (a['typicalMonthlyTotal'] as num?)?.toDouble();
        final double? bVal = (b['allInMonthlyEstimate'] as num?)?.toDouble() ?? (b['typicalMonthlyTotal'] as num?)?.toDouble();
        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return 1;
        if (bVal == null) return -1;
        return toEur(bVal, b['currency'] as String? ?? '').compareTo(
            toEur(aVal, a['currency'] as String? ?? ''));
      }
      return toEur(
        (b['guaranteedMonthlyPay'] as num?)?.toDouble() ?? (b['fixedMonthlyTotal'] as num?)?.toDouble() ?? (b['baseSalary'] as num?)?.toDouble() ?? 0,
        b['currency'] as String? ?? '',
      ).compareTo(toEur(
        (a['guaranteedMonthlyPay'] as num?)?.toDouble() ?? (a['fixedMonthlyTotal'] as num?)?.toDouble() ?? (a['baseSalary'] as num?)?.toDouble() ?? 0,
        a['currency'] as String? ?? '',
      ));
    });
    return list;
  }

  int get activeFilterCount {
    int count = 0;
    if (searchQuery.value.isNotEmpty) count++;
    if (filterRank.value.isNotEmpty) count++;
    if (filterCountry.value.isNotEmpty) count++;
    if (filterBase.value.isNotEmpty) count++;
    if (filterAircraftType.value.isNotEmpty) count++;
    if (filterSeniority.value.isNotEmpty) count++;
    if (filterAmountType.value.isNotEmpty) count++;
    if (filterFlightHours.value.isNotEmpty) count++;
    return count;
  }

  void clearAllFilters() {
    searchQuery.value = '';
    filterRank.value = '';
    filterCountry.value = '';
    filterBase.value = '';
    filterAircraftType.value = '';
    filterSeniority.value = '';
    filterAmountType.value = '';
    filterFlightHours.value = '';
  }

  // Top 3 highest-paid submissions matching user's rank, aircraft type, and experience.
  List<Map<String, dynamic>> get pilotsLikeMe {
    if (myRank.isEmpty || myAircraftType.isEmpty) return <Map<String, dynamic>>[];

    final bool myHasSeniority = mySeniorityYears > 0;
    final bool myHasHours = myFlightHours > 0;
    final String myNormAmt = _normAmtType(myAmountType);

    final List<Map<String, dynamic>> matches = salaries.where((Map<String, dynamic> s) {
      if (s['rank'] != myRank || s['aircraftType'] != myAircraftType) return false;
      if (_normAmtType(s['amountType'] as String?) != myNormAmt) return false;

      final int peerSeniority = (s['seniorityYears'] as num?)?.toInt() ?? 0;
      final int peerHours = (s['totalFlightHours'] as num?)?.toInt() ?? 0;
      final bool peerHasSeniority = peerSeniority > 0;
      final bool peerHasHours = peerHours > 0;

      if (myHasSeniority && myHasHours && peerHasSeniority && peerHasHours) {
        return (peerSeniority - mySeniorityYears).abs() <= 2 &&
            (peerHours - myFlightHours).abs() <= 200;
      }
      if (myHasSeniority && peerHasSeniority) {
        return (peerSeniority - mySeniorityYears).abs() <= 2;
      }
      if (myHasHours && peerHasHours) {
        return (peerHours - myFlightHours).abs() <= 200;
      }
      return false;
    }).toList()
      ..sort((Map<String, dynamic> a, Map<String, dynamic> b) {
        final double aEur = toEur(
          (a['guaranteedMonthlyPay'] as num?)?.toDouble() ?? (a['fixedMonthlyTotal'] as num?)?.toDouble() ?? (a['baseSalary'] as num?)?.toDouble() ?? 0,
          a['currency'] as String? ?? '',
        );
        final double bEur = toEur(
          (b['guaranteedMonthlyPay'] as num?)?.toDouble() ?? (b['fixedMonthlyTotal'] as num?)?.toDouble() ?? (b['baseSalary'] as num?)?.toDouble() ?? 0,
          b['currency'] as String? ?? '',
        );
        return bEur.compareTo(aEur);
      });

    return matches.take(3).toList();
  }

  // Top 3 countries by the single highest-paid individual submission for the current user's rank.
  List<Map<String, dynamic>> get bestPaidCountriesForMyRank {
    if (myRank.isEmpty) return <Map<String, dynamic>>[];
    final Map<String, Map<String, dynamic>> bestByCountry = <String, Map<String, dynamic>>{};
    final String myNormAmt = _normAmtType(myAmountType);
    for (final Map<String, dynamic> s in salaries) {
      if (s['rank'] != myRank) continue;
      if (_normAmtType(s['amountType'] as String?) != myNormAmt) continue;
      final String country = s['country'] as String? ?? '';
      if (country.isEmpty) continue;
      final double sal = (s['guaranteedMonthlyPay'] as num?)?.toDouble()
          ?? (s['fixedMonthlyTotal'] as num?)?.toDouble()
          ?? (s['baseSalary'] as num?)?.toDouble() ?? 0;
      final String cur = s['currency'] as String? ?? '';
      final double eur = toEur(sal, cur);
      final Map<String, dynamic>? current = bestByCountry[country];
      if (current == null) {
        bestByCountry[country] = s;
      } else {
        final double currentEur = toEur(
          (current['guaranteedMonthlyPay'] as num?)?.toDouble()
              ?? (current['fixedMonthlyTotal'] as num?)?.toDouble()
              ?? (current['baseSalary'] as num?)?.toDouble() ?? 0,
          current['currency'] as String? ?? '',
        );
        if (eur > currentEur) bestByCountry[country] = s;
      }
    }
    final List<Map<String, dynamic>> result = bestByCountry.entries.map((MapEntry<String, Map<String, dynamic>> e) {
      final double sal = (e.value['guaranteedMonthlyPay'] as num?)?.toDouble()
          ?? (e.value['fixedMonthlyTotal'] as num?)?.toDouble()
          ?? (e.value['baseSalary'] as num?)?.toDouble() ?? 0;
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
        mySubmission = submission;
        myRank = submission['rank'] as String? ?? '';
        myAircraftType = submission['aircraftType'] as String? ?? '';
        mySeniorityYears = (submission['seniorityYears'] as num?)?.toInt() ?? 0;
        myAmountType = submission['amountType'] as String? ?? '';
        myFlightHours = (submission['totalFlightHours'] as num?)?.toInt() ?? 0;
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
        mySubmission = null;
        myRank = '';
        myAircraftType = '';
        mySeniorityYears = 0;
        myAmountType = '';
        myFlightHours = 0;
        await _fetchRates();
        salaries.value = await FirebaseService.getAllSalaries().timeout(timeout);
      } else {
        mySubmission = null;
        myRank = '';
        myAircraftType = '';
        mySeniorityYears = 0;
        myAmountType = '';
        myFlightHours = 0;
      }
    } catch (_) {
      hasError.value = true;
    }
    loading.value = false;
  }

  Future<void> reload() => _load();

  Future<void> _fetchRates() async {
    bool apiSuccess = false;
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
          apiSuccess = true;
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_eur_rates', jsonEncode(rates));
        }
      } else {
        client.close();
      }
    } catch (_) {}

    if (!apiSuccess) {
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? cached = prefs.getString('cached_eur_rates');
        if (cached != null) {
          final Map<String, dynamic> decoded = jsonDecode(cached) as Map<String, dynamic>;
          rates = decoded.map((String k, dynamic v) => MapEntry(k, (v as num).toDouble()));
        }
        // If no cache exists, rates stays empty — toEur() returns 0 for non-EUR,
        // which the UI already handles by hiding the EUR conversion line.
      } catch (_) {}
    }
  }

  Future<void> _fetchAirlineNames() async {
    try {
      final List<Map<String, dynamic>> list = await FirebaseService.getAirlines();
      airlineNames.value = list
          .map((Map<String, dynamic> m) => m['name'] as String)
          .toList();
    } catch (_) {}
  }

  Future<void> deleteMySalary() async {
    if (existingDocId == null) return;
    await FirebaseService.deleteSalary(existingDocId!);
    existingDocId = null;
    mySubmission = null;
    myRank = '';
    myAircraftType = '';
    mySeniorityYears = 0;
    myAmountType = '';
    myFlightHours = 0;
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
      Dialog(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Is your salary still current?',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your salary submission is over 12 months old. Is it still accurate?',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () async {
                      Get.back();
                      await Get.to(() => SubmitSalaryScreen(existingDocId: existingDocId, initialData: mySubmission, onDone: reload));
                    },
                    child: const Text('No, update it', style: TextStyle(color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      Get.back();
                      await confirmStillValid();
                    },
                    child: const Text('Yes, still valid', style: TextStyle(color: AppColors.accent)),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      final List<Map<String, dynamic>> grossEntries = entries
          .where((Map<String, dynamic> s) => _normAmtType(s['amountType'] as String?) == 'gross')
          .toList();
      final List<Map<String, dynamic>> netEntries = entries
          .where((Map<String, dynamic> s) => _normAmtType(s['amountType'] as String?) == 'net')
          .toList();
      if (grossEntries.length >= 3) {
        final List<double> eurSalaries = grossEntries
            .map((Map<String, dynamic> s) => toEur(
                  (s['guaranteedMonthlyPay'] as num?)?.toDouble()
                      ?? (s['fixedMonthlyTotal'] as num?)?.toDouble()
                      ?? (s['baseSalary'] as num?)?.toDouble() ?? 0,
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
          'rangeType': 'gross',
          'hasNetData': netEntries.isNotEmpty,
        });
      } else if (netEntries.length >= 3) {
        final List<double> eurSalaries = netEntries
            .map((Map<String, dynamic> s) => toEur(
                  (s['guaranteedMonthlyPay'] as num?)?.toDouble()
                      ?? (s['fixedMonthlyTotal'] as num?)?.toDouble()
                      ?? (s['baseSalary'] as num?)?.toDouble() ?? 0,
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
          'rangeType': 'net',
          'hasNetData': false,
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
          'rangeType': 'gross',
          'hasNetData': netEntries.isNotEmpty,
        });
      }
    }
    result.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final bool aHas = a['hasData'] as bool? ?? false;
      final bool bHas = b['hasData'] as bool? ?? false;
      if (aHas != bHas) return aHas ? -1 : 1;
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

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(SalaryController());
  }

  @override
  Widget build(BuildContext context) {
    final SalaryController c = Get.find<SalaryController>();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.accent),
          onPressed: () {
            if (c.isJobHunting.value) {
              c.isJobHunting.value = false;
            } else {
              Get.back();
            }
          },
        ),
        title: const Text(
          'Pilot Salaries',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        centerTitle: true,
        actions: <Widget>[
          Obx(() {
            if (!c.hasSubmitted.value) return const SizedBox.shrink();
            return Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.accent, size: 20),
                  tooltip: 'Update salary',
                  onPressed: () => Get.to(() => SubmitSalaryScreen(existingDocId: c.existingDocId, initialData: c.mySubmission, onDone: c.reload)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.failText, size: 20),
                  tooltip: 'Delete salary',
                  onPressed: () => _confirmDelete(c),
                ),
              ],
            );
          }),
        ],
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
                  final bool? confirmed = await Get.dialog<bool>(
                    AlertDialog(
                      backgroundColor: AppColors.bgCard,
                      title: const Text(
                        'Before you submit',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      content: const Text(
                        'Your salary data will be verified against other pilots at the same airline. Submitting false information may result in your data being removed and access being revoked.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                        ),
                        TextButton(
                          onPressed: () => Get.back(result: true),
                          child: const Text('I understand — Continue', style: TextStyle(color: AppColors.accent)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    Get.to(() => SubmitSalaryScreen(existingDocId: c.existingDocId, onDone: c.reload));
                  }
                },
                child: const Text(
                  "I'm employed — submit my salary",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final bool? confirmed = await Get.dialog<bool>(
                    AlertDialog(
                      backgroundColor: AppColors.bgCard,
                      title: const Text(
                        'Salary ranges ahead',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      content: const Text(
                        "You'll see average salary ranges based on real pilot submissions. Submit your own salary when you land a job to unlock exact figures.",
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text('Back', style: TextStyle(color: AppColors.textMuted)),
                        ),
                        TextButton(
                          onPressed: () => Get.back(result: true),
                          child: const Text('Got it — Browse ranges', style: TextStyle(color: AppColors.accent)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    c.setJobHunting();
                  }
                },
                child: const Text(
                  "I'm seeking a position",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
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
            placeholder: 'All Airlines',
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
            final double globalMax = groups
                .where((Map<String, dynamic> g) => g['hasData'] as bool? ?? false)
                .fold(0.0, (double prev, Map<String, dynamic> g) {
                  final double v = g['maxEur'] as double? ?? 0;
                  return v > prev ? v : prev;
                });
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (BuildContext ctx, int i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LimitedGroupCard(group: groups[i], globalMaxEur: globalMax),
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Get.to(() => SubmitSalaryScreen(existingDocId: c.existingDocId, onDone: c.reload));
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
        // Fixed: search + filter button + sort/show row
        Container(
          color: AppColors.bgPrimary,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: _buildSearchBar(c)),
                  const SizedBox(width: 10),
                  Obx(() {
                    final int filterCount = c.activeFilterCount -
                        (c.searchQuery.value.isNotEmpty ? 1 : 0);
                    return GestureDetector(
                      onTap: () => _showFilterSheet(c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: filterCount > 0
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: filterCount > 0
                                ? AppColors.accent
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.tune,
                              color: filterCount > 0
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                              size: 18,
                            ),
                            if (filterCount > 0) ...<Widget>[
                              const SizedBox(width: 6),
                              Text(
                                '$filterCount',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 8),
              Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    const Text(
                      'Sort:',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _SortChip(
                      label: 'Guaranteed',
                      selected: c.sortBy.value == 'base',
                      onTap: () => c.sortBy.value = 'base',
                    ),
                    const SizedBox(width: 6),
                    _SortChip(
                      label: 'Total Pay',
                      selected: c.sortBy.value == 'typical',
                      onTap: () => c.sortBy.value = 'typical',
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Show:',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _SortChip(
                      label: 'All',
                      selected: c.filterAmountType.value == '',
                      onTap: () => c.filterAmountType.value = '',
                    ),
                    const SizedBox(width: 6),
                    _SortChip(
                      label: 'Gross',
                      selected: c.filterAmountType.value == 'gross',
                      onTap: () => c.filterAmountType.value = 'gross',
                    ),
                    const SizedBox(width: 6),
                    _SortChip(
                      label: 'Net',
                      selected: c.filterAmountType.value == 'net',
                      onTap: () => c.filterAmountType.value = 'net',
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),

        // Scrollable content (insights + salary cards)
        Expanded(
          child: Obx(() {
            final List<Map<String, dynamic>> results = c.filtered;
            final List<Map<String, dynamic>> peers = c.pilotsLikeMe;
            final List<Map<String, dynamic>> bestCountries = c.bestPaidCountriesForMyRank;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: <Widget>[

                // ── YOUR INSIGHTS ────────────────────────────────────────
                const Text(
                  'YOUR INSIGHTS',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                ),
                const SizedBox(height: 12),

                Row(
                  children: <Widget>[
                    const Text(
                      'Pilots like you',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => Get.dialog<void>(
                        AlertDialog(
                          backgroundColor: AppColors.bgCard,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          content: const Text(
                            'Shows pilots at the same rank and aircraft type as you, with similar experience (±2 years seniority or ±200 flight hours). All figures are in the same gross/net category as your submission.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: Get.back,
                              child: const Text('Got it', style: TextStyle(color: AppColors.accent)),
                            ),
                          ],
                        ),
                      ),
                      child: const Icon(Icons.info_outline, color: AppColors.textMuted, size: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (peers.isEmpty)
                  _buildEmptyInsightCard('Not enough data yet — check back later')
                else
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: peers.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (BuildContext ctx, int i) => _PeerCard(
                        salary: peers[i],
                        rates: c.rates,
                        onTap: () => _showPeerProfile(ctx, peers[i], c.rates, _countSimilarPilots(c.salaries, peers[i])),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Top countries for ${c.myRank}s',
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    Tooltip(
                      message: 'Based on highest single salary submitted per country for your rank',
                      child: const Icon(Icons.info_outline, color: AppColors.textMuted, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (bestCountries.isEmpty)
                  _buildEmptyInsightCard('Not enough data yet')
                else
                  _BestCountriesCard(countries: bestCountries),

                const SizedBox(height: 20),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 16),

                // ── Active filter indicator ──────────────────────────────
                if (c.activeFilterCount > 0) ...<Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${c.activeFilterCount} filter${c.activeFilterCount == 1 ? '' : 's'} active',
                          style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: c.clearAllFilters,
                        child: const Text(
                          'Clear all',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // ── Results count + disclaimer ───────────────────────────
                Text(
                  '${results.length} result${results.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Amounts shown as reported by pilot',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
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
                    child: _SalaryCard(salary: s, rates: c.rates, confirmedCount: _countSimilarPilots(c.salaries, s)),
                  )),
              ],
            );
          }),
        ),

      ],
    );
  }

  Widget _buildSearchBar(SalaryController c) {
    return Obx(() => _SearchableFilterDrop(
      hint: 'Airline',
      placeholder: 'All Airlines',
      value: c.searchQuery.value.isEmpty ? null : c.searchQuery.value,
      options: c.airlineNames.toList(),
      onChanged: (String? v) => c.searchQuery.value = v ?? '',
    ));
  }

  void _showFilterSheet(SalaryController c) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _FiltersSheet(c: c),
      ),
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

  void _showPeerProfile(BuildContext context, Map<String, dynamic> salary, Map<String, double> rates, int confirmedCount) {
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
            _SalaryCard(salary: salary, rates: rates, confirmedCount: confirmedCount),
          ],
        ),
      ),
    );
  }
}

class _LimitedGroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final double globalMaxEur;
  const _LimitedGroupCard({required this.group, required this.globalMaxEur});

  @override
  Widget build(BuildContext context) {
    final String airline = group['airline'] as String? ?? '-';
    final String rank = group['rank'] as String? ?? '-';
    final String aircraft = group['aircraftType'] as String? ?? '-';
    final bool hasData = group['hasData'] as bool? ?? false;
    final bool hasNetData = group['hasNetData'] as bool? ?? false;
    final String rangeType = group['rangeType'] as String? ?? 'gross';
    final int count = group['count'] as int? ?? 0;
    final double minEur = group['minEur'] as double? ?? 0;
    final double maxEur = group['maxEur'] as double? ?? 0;
    final double rel = (globalMaxEur > 0 && hasData) ? (maxEur / globalMaxEur).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
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
                    if (hasNetData && rangeType == 'gross')
                      const Text(
                        'Net salaries available after you submit',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                  ],
                ),
              ),
              if (hasData)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(rangeType == 'net' ? 'Net Salary Range' : 'Gross Salary Range', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmt(minEur)} – ${_fmt(maxEur)} EUR',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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
          if (hasData) ...<Widget>[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: rel,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent.withValues(alpha: 0.7)),
                minHeight: 4,
              ),
            ),
          ],
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

String _normAmtType(String? t) =>
    (t == null || t.isEmpty || t.toLowerCase().startsWith('gross')) ? 'gross' : 'net';

int _countSimilarPilots(List<Map<String, dynamic>> salaries, Map<String, dynamic> s) {
  final String airline = s['airline'] as String? ?? '';
  final String rank = s['rank'] as String? ?? '';
  final String aircraft = s['aircraftType'] as String? ?? '';
  final String amt = _normAmtType(s['amountType'] as String?);
  return salaries.where((Map<String, dynamic> p) =>
    p['airline'] == airline &&
    p['rank'] == rank &&
    p['aircraftType'] == aircraft &&
    _normAmtType(p['amountType'] as String?) == amt
  ).length;
}

class _PeerCard extends StatelessWidget {
  final Map<String, dynamic> salary;
  final VoidCallback onTap;
  final Map<String, double> rates;
  const _PeerCard({required this.salary, required this.onTap, required this.rates});

  @override
  Widget build(BuildContext context) {
    final double primarySalary = (salary['guaranteedMonthlyPay'] as num?)?.toDouble()
        ?? (salary['fixedMonthlyTotal'] as num?)?.toDouble()
        ?? (salary['baseSalary'] as num?)?.toDouble() ?? 0;
    final String currency = salary['currency'] as String? ?? '';
    final String country = salary['country'] as String? ?? '-';
    final int seniority = (salary['seniorityYears'] as num?)?.toInt() ?? 0;
    final int? totalFlightHours = (salary['totalFlightHours'] as num?)?.toInt();
    final double eurSalary = _toEur(primarySalary, currency, rates);
    final double? allInMonthlyEstimate = (salary['allInMonthlyEstimate'] as num?)?.toDouble()
        ?? (salary['typicalMonthlyTotal'] as num?)?.toDouble();
    final double? eurAllIn = allInMonthlyEstimate != null ? _toEur(allInMonthlyEstimate, currency, rates) : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(height: 2, color: AppColors.accent),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${_fmt(primarySalary)} $currency',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const Text(
                    'Monthly Guaranteed',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                  if (currency != 'EUR' && eurSalary > 0)
                    Text(
                      '≈ ${_fmt(eurSalary)} EUR',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  if (allInMonthlyEstimate != null && allInMonthlyEstimate > primarySalary) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      '${_fmt(allInMonthlyEstimate)} $currency',
                      style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const Text(
                      'Total Pay ~',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                    if (currency != 'EUR' && eurAllIn != null && eurAllIn > 0)
                      Text(
                        '≈ ${_fmt(eurAllIn)} EUR',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                  ],
                  const SizedBox(height: 6),
                  Text(country, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  if (seniority > 0)
                    Text('$seniority yr seniority', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  if (totalFlightHours != null && totalFlightHours > 0)
                    Text('${_fmt(totalFlightHours.toDouble())} hrs', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
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

  Color _rankColor(int rank) {
    if (rank == 0) return const Color(0xFFD4A017);
    if (rank == 1) return const Color(0xFF9EA0A5);
    if (rank == 2) return const Color(0xFFC17F40);
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final double maxEur = countries.isEmpty
        ? 1
        : (countries.first['salaryEur'] as double? ?? 1);

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
          final Color rankColor = _rankColor(idx);
          final double rel = maxEur > 0 ? (salaryEur / maxEur).clamp(0.0, 1.0) : 0.0;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
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
                      '${idx + 1}',
                      style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 12),
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
                            child: Text(
                              country,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currency == 'EUR' ? '${_fmt(salary)} EUR' : '${_fmt(salary)} $currency',
                            style: TextStyle(
                              color: rankColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (currency != 'EUR' && salaryEur > 0)
                        Text(
                          '≈ ${_fmt(salaryEur)} EUR',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: rel,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(rankColor.withValues(alpha: 0.65)),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
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

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accent : AppColors.textMuted,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}


class _SearchableFilterDrop extends StatelessWidget {
  final String hint;
  final String? placeholder;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool searchable;

  const _SearchableFilterDrop({
    required this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder,
    this.searchable = true,
  });

  @override
  Widget build(BuildContext context) {
    final String displayText = value ?? placeholder ?? hint;
    final bool hasValue = value != null;
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hasValue ? AppColors.accent : AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  color: hasValue ? AppColors.textPrimary : AppColors.textMuted,
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
      builder: (_) => _FilterSearchSheet(hint: hint, items: options, searchable: searchable),
    );
    if (picked != null) onChanged(picked);
  }
}

class _FilterSearchSheet extends StatefulWidget {
  final String hint;
  final List<String> items;
  final bool searchable;
  const _FilterSearchSheet({required this.hint, required this.items, this.searchable = true});

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
          if (widget.searchable) ...<Widget>[
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
          ],
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

class _FiltersSheet extends StatelessWidget {
  final SalaryController c;
  const _FiltersSheet({required this.c});

  Widget _chip(String chip, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.15) : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          chip,
          style: TextStyle(
            color: selected ? AppColors.accent : AppColors.textMuted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: <Widget>[
              const Text(
                'Filters',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const Spacer(),
              GestureDetector(
                onTap: c.clearAllFilters,
                child: const Text(
                  'Clear all',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Obx(() => _SearchableFilterDrop(
                        hint: 'Rank',
                        value: c.filterRank.value.isEmpty ? null : c.filterRank.value,
                        options: const <String>['SO', 'FO', 'Captain'],
                        onChanged: (String? v) => c.filterRank.value = v ?? '',
                        searchable: false,
                      )),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Obx(() => _SearchableFilterDrop(
                        hint: 'Country',
                        placeholder: 'All Countries',
                        value: c.filterCountry.value.isEmpty ? null : c.filterCountry.value,
                        options: c.availableCountries,
                        onChanged: (String? v) => c.filterCountry.value = v ?? '',
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Obx(() => _SearchableFilterDrop(
                        hint: 'Aircraft',
                        placeholder: 'All Aircraft',
                        value: c.filterAircraftType.value.isEmpty ? null : c.filterAircraftType.value,
                        options: kAircraftTypes,
                        onChanged: (String? v) => c.filterAircraftType.value = v ?? '',
                      )),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Obx(() => _SearchableFilterDrop(
                        hint: 'Base/City',
                        placeholder: 'All Bases',
                        value: c.filterBase.value.isEmpty ? null : c.filterBase.value,
                        options: c.availableBases,
                        onChanged: (String? v) => c.filterBase.value = v ?? '',
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Seniority',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  const List<String> chips = <String>['<3y', '3-6y', '7-10y', '11-15y', '16-20y', '20+y'];
                  return Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: chips
                        .map((String ch) => _chip(
                              ch,
                              c.filterSeniority.value == ch,
                              () => c.filterSeniority.value =
                                  c.filterSeniority.value == ch ? '' : ch,
                            ))
                        .toList(),
                  );
                }),
                const SizedBox(height: 16),
                const Text(
                  'Flight Hours',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  const List<String> chips = <String>[
                    '<500h', '500-1500h', '1500-3000h', '3000-5000h', '5000+h'
                  ];
                  return Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: chips
                        .map((String ch) => _chip(
                              ch,
                              c.filterFlightHours.value == ch,
                              () => c.filterFlightHours.value =
                                  c.filterFlightHours.value == ch ? '' : ch,
                            ))
                        .toList(),
                  );
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Show Results',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SalaryCard extends StatelessWidget {
  final Map<String, dynamic> salary;
  final Map<String, double> rates;
  final int confirmedCount;
  const _SalaryCard({required this.salary, required this.rates, required this.confirmedCount});

  @override
  Widget build(BuildContext context) {
    final String airline = salary['airline'] as String? ?? '-';
    final String rank = salary['rank'] as String? ?? '-';
    final int seniority = (salary['seniorityYears'] as num?)?.toInt() ?? 0;
    final int? totalFlightHours = (salary['totalFlightHours'] as num?)?.toInt();
    final String aircraft = salary['aircraftType'] as String? ?? '-';
    final String contract = salary['contractType'] as String? ?? '-';
    final double primarySalary = (salary['guaranteedMonthlyPay'] as num?)?.toDouble()
        ?? (salary['fixedMonthlyTotal'] as num?)?.toDouble()
        ?? (salary['baseSalary'] as num?)?.toDouble()
        ?? 0;
    final String country = salary['country'] as String? ?? '-';
    final String base = salary['base'] as String? ?? '-';
    final String currency = salary['currency'] as String? ?? '';
    final double eurPrimary = _toEur(primarySalary, currency, rates);
    final double? allInMonthlyEstimate = (salary['allInMonthlyEstimate'] as num?)?.toDouble()
        ?? (salary['typicalMonthlyTotal'] as num?)?.toDouble();
    final double? eurAllIn = allInMonthlyEstimate != null ? _toEur(allInMonthlyEstimate, currency, rates) : null;
    final String amountType = salary['amountType'] as String? ?? '';
    final bool isGross = _normAmtType(amountType) == 'gross';
    const Color grossColor = Color(0xFF4DB87A);
    const Color netColor = Color(0xFF5B9CF6);
    final Color amtColor = isGross ? grossColor : netColor;

    return Container(
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
                    // Header: airline · rank badge · gross/net badge
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            airline,
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(rank, style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: amtColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isGross ? 'Gross' : 'Net',
                            style: TextStyle(color: amtColor, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Aircraft + experience
                    Text(
                      '$aircraft${seniority > 0 ? ' · $seniority yr' : ''}${totalFlightHours != null && totalFlightHours > 0 ? ' · ${_fmt(totalFlightHours.toDouble())} hrs' : ''}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    // Contract + location
                    Text(
                      '$contract · $country · $base',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 14),

                    // Hero salary (no divider — whitespace provides separation)
                    Center(
                      child: Column(
                        children: <Widget>[
                          Text(
                            '${_fmt(primarySalary)} $currency / month',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_fmt(primarySalary * 12)} $currency / year',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Guaranteed',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          if (currency != 'EUR' && eurPrimary > 0)
                            Text(
                              '≈ ${_fmt(eurPrimary)} EUR',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          if (allInMonthlyEstimate != null) ...<Widget>[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Text('Total Pay  ≈  ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  Text(
                                    '${_fmt(allInMonthlyEstimate)} $currency',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  if (currency != 'EUR' && eurAllIn != null && eurAllIn > 0)
                                    Text(
                                      '  ≈ ${_fmt(eurAllIn)} EUR',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (confirmedCount > 0) ...<Widget>[
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          '$confirmedCount $rank submission${confirmedCount == 1 ? '' : 's'} at this airline',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
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

