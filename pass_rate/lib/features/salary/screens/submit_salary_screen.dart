import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/services/firebase_service.dart';

const List<String> kAircraftTypes = <String>[
  'A220', 'A318', 'A319', 'A320', 'A321',
  'A330', 'A340', 'A350', 'A380',
  '737-700', '737-800', '737-900', '737 MAX',
  '757', '767', '777', '787',
  'E170', 'E175', 'E190', 'E195',
  'Q400', 'CRJ-900', 'ATR-42', 'ATR-72',
];

class SubmitSalaryController extends GetxController {
  final RxBool loadingAirlines = true.obs;
  final RxBool loadingCountries = true.obs;
  final RxBool loadingAircraftTypes = true.obs;
  final RxBool submitting = false.obs;
  final RxBool loadingAirlinesError = false.obs;
  final RxBool loadingCountriesError = false.obs;
  String? existingDocId;

  final RxList<String> aircraftTypeOptions = <String>[].obs;
  final RxMap<String, List<String>> countries = <String, List<String>>{}.obs;
  final RxList<Map<String, dynamic>> airlines = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>?> selectedAirline = Rx<Map<String, dynamic>?>(null);
  final RxString selectedRank = ''.obs;
  final RxString selectedAircraftType = ''.obs;
  final RxString selectedContractType = ''.obs;
  final RxString selectedCurrency = ''.obs;
  final RxString selectedCountry = ''.obs;
  final RxString selectedBase = ''.obs;
  final RxString selectedAmountType = ''.obs;

  final RxString selectedSeniority = ''.obs;
  final TextEditingController baseSalaryController = TextEditingController();
  final TextEditingController baseController = TextEditingController();
  final TextEditingController fixedMonthlyTotalController = TextEditingController();
  final TextEditingController typicalMonthlyTotalController = TextEditingController();

  bool get _baseCompleted {
    if (selectedCountry.value == 'Other') return baseController.text.trim().isNotEmpty;
    return selectedBase.value.isNotEmpty;
  }

  bool get allCompleted =>
      selectedAirline.value != null &&
      selectedRank.value.isNotEmpty &&
      selectedSeniority.value.isNotEmpty &&
      selectedAircraftType.value.isNotEmpty &&
      selectedContractType.value.isNotEmpty &&
      baseSalaryController.text.isNotEmpty &&
      selectedCountry.value.isNotEmpty &&
      _baseCompleted &&
      selectedCurrency.value.isNotEmpty &&
      selectedAmountType.value.isNotEmpty;

  // Step completion for the progress header
  bool get step1Done =>
      selectedAirline.value != null &&
      selectedRank.value.isNotEmpty &&
      selectedSeniority.value.isNotEmpty &&
      selectedAircraftType.value.isNotEmpty;

  bool get step2Done =>
      selectedContractType.value.isNotEmpty &&
      selectedCountry.value.isNotEmpty &&
      _baseCompleted;

  bool get step3Done =>
      selectedCurrency.value.isNotEmpty &&
      selectedAmountType.value.isNotEmpty &&
      baseSalaryController.text.isNotEmpty;

  Map<String, dynamic>? _prefillData;

  void prefillWith(Map<String, dynamic> data) {
    _prefillData = data;
    if (!loadingAirlines.value && airlines.isNotEmpty) _applyPrefill();
  }

  void _applyPrefill() {
    final Map<String, dynamic>? data = _prefillData;
    if (data == null) return;
    _prefillData = null;

    final String airlineName = data['airline'] as String? ?? '';
    if (airlineName.isNotEmpty) {
      try {
        final Map<String, dynamic> match = airlines.firstWhere(
          (Map<String, dynamic> a) => (a['name'] as String? ?? '') == airlineName,
        );
        selectedAirline.value = match;
      } catch (_) {}
    }
    selectedRank.value = data['rank'] as String? ?? '';
    final int sen = (data['seniorityYears'] as num?)?.toInt() ?? 0;
    if (sen > 0) selectedSeniority.value = sen.toString();
    selectedAircraftType.value = data['aircraftType'] as String? ?? '';
    selectedContractType.value = data['contractType'] as String? ?? '';
    selectedCurrency.value = data['currency'] as String? ?? '';
    selectedAmountType.value = data['amountType'] as String? ?? '';
    selectedCountry.value = data['country'] as String? ?? '';
    final String base = data['base'] as String? ?? '';
    selectedBase.value = base;
    baseController.text = base;
    final double baseSalary = (data['baseSalary'] as num?)?.toDouble() ?? 0;
    if (baseSalary > 0) baseSalaryController.text = _fmtNum(baseSalary);
    final double? fixed = (data['fixedMonthlyTotal'] as num?)?.toDouble();
    final double? typical = (data['typicalMonthlyTotal'] as num?)?.toDouble();
    if (fixed != null && fixed > 0) fixedMonthlyTotalController.text = _fmtNum(fixed);
    if (typical != null && typical > 0) typicalMonthlyTotalController.text = _fmtNum(typical);
    update();
  }

  String _fmtNum(double v) =>
      v == v.truncateToDouble() ? v.truncate().toString() : v.toString();

  void selectCountry(String? country) {
    selectedCountry.value = country ?? '';
    selectedBase.value = '';
    baseController.clear();
    update();
  }

  @override
  void onInit() {
    super.onInit();
    fetchAirlines();
    fetchCountries();
    fetchAircraftTypes();
  }

  @override
  void onClose() {
    baseSalaryController.dispose();
    baseController.dispose();
    fixedMonthlyTotalController.dispose();
    typicalMonthlyTotalController.dispose();
    super.onClose();
  }

  Future<void> fetchAirlines() async {
    loadingAirlines.value = true;
    loadingAirlinesError.value = false;
    try {
      airlines.value = await FirebaseService.getAirlines();
      if (_prefillData != null) _applyPrefill();
    } catch (_) {
      loadingAirlinesError.value = true;
    } finally {
      loadingAirlines.value = false;
    }
  }

  Future<void> fetchCountries() async {
    loadingCountries.value = true;
    loadingCountriesError.value = false;
    try {
      countries.value = await FirebaseService.getCountries();
    } catch (_) {
      loadingCountriesError.value = true;
    } finally {
      loadingCountries.value = false;
    }
  }

  Future<void> fetchAircraftTypes() async {
    loadingAircraftTypes.value = true;
    try {
      final List<String> types = await FirebaseService.getAircraftTypes();
      aircraftTypeOptions.value = types.isNotEmpty ? types : kAircraftTypes;
    } catch (_) {
      aircraftTypeOptions.value = kAircraftTypes;
    } finally {
      loadingAircraftTypes.value = false;
    }
  }

  Future<bool> submit() async {
    if (!allCompleted) return false;
    submitting.value = true;
    try {
      final String deviceId = await FirebaseService.getDeviceId();
      await FirebaseService.submitSalary(
        deviceId: deviceId,
        airlineId: selectedAirline.value!['id'] as String,
        airlineName: selectedAirline.value!['name'] as String,
        rank: selectedRank.value,
        seniorityYears: int.tryParse(selectedSeniority.value) ?? 0,
        aircraftType: selectedAircraftType.value,
        contractType: selectedContractType.value,
        baseSalary: double.tryParse(baseSalaryController.text) ?? 0,
        country: selectedCountry.value,
        base: selectedCountry.value == 'Other'
            ? baseController.text.trim()
            : selectedBase.value,
        currency: selectedCurrency.value,
        existingDocId: existingDocId,
        fixedMonthlyTotal: double.tryParse(fixedMonthlyTotalController.text),
        typicalMonthlyTotal: double.tryParse(typicalMonthlyTotalController.text),
        amountType: selectedAmountType.value.isEmpty ? null : selectedAmountType.value,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      submitting.value = false;
    }
  }
}

// ── Submit salary screen ───────────────────────────────────────────────────────

class SubmitSalaryScreen extends StatefulWidget {
  final String? existingDocId;
  final Map<String, dynamic>? initialData;
  final VoidCallback? onDone;
  const SubmitSalaryScreen({super.key, this.existingDocId, this.initialData, this.onDone});

  @override
  State<SubmitSalaryScreen> createState() => _SubmitSalaryScreenState();
}

class _SubmitSalaryScreenState extends State<SubmitSalaryScreen> {
  @override
  void initState() {
    super.initState();
    final SubmitSalaryController c = Get.put(SubmitSalaryController());
    c.existingDocId = widget.existingDocId;
    if (widget.initialData != null) c.prefillWith(widget.initialData!);
  }

  @override
  Widget build(BuildContext context) {
    final SubmitSalaryController c = Get.find<SubmitSalaryController>();
    final String title = widget.existingDocId != null ? 'Update Salary' : 'Submit Salary';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.accent),
          onPressed: () => Get.back(),
        ),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: GetBuilder<SubmitSalaryController>(
        builder: (SubmitSalaryController ctrl) => Column(
          children: <Widget>[
            _buildStepHeader(ctrl),
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.opaque,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[

                    // ── POSITION ─────────────────────────────────────────────

                    // Airline
                    const _FieldLabel('Airline'),
                    Obx(() {
                      if (c.loadingAirlines.value) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                      }
                      if (c.loadingAirlinesError.value) {
                        return _ErrorRetry(message: 'Could not load airlines.', onRetry: c.fetchAirlines);
                      }
                      return _AirlineSearchableDropdown(
                        hint: 'Select Airline',
                        value: c.selectedAirline.value,
                        items: c.airlines,
                        onChanged: (Map<String, dynamic>? v) {
                          c.selectedAirline.value = v;
                          c.update();
                        },
                      );
                    }),
                    const SizedBox(height: 16),

                    // Rank
                    const _FieldLabel('Rank'),
                    Obx(() => _OptionDrop(
                      hint: 'Select Rank',
                      value: c.selectedRank.value.isEmpty ? null : c.selectedRank.value,
                      options: const <String>['SO', 'FO', 'Captain'],
                      onChanged: (String? v) {
                        if (v != null) { c.selectedRank.value = v; c.update(); }
                      },
                    )),
                    const SizedBox(height: 16),

                    // Seniority
                    const _FieldLabel('Seniority (years)'),
                    Obx(() => _SimpleDrop(
                      hint: 'Select years of seniority',
                      value: c.selectedSeniority.value.isEmpty ? null : c.selectedSeniority.value,
                      count: 30,
                      onChanged: (String? v) {
                        if (v != null) { c.selectedSeniority.value = v; c.update(); }
                      },
                    )),
                    const SizedBox(height: 16),

                    // Aircraft type
                    const _FieldLabel('Aircraft Type'),
                    Obx(() {
                      if (c.loadingAircraftTypes.value) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                      }
                      return _SearchableDropdown(
                        hint: 'Select Aircraft Type',
                        value: c.selectedAircraftType.value.isEmpty ? null : c.selectedAircraftType.value,
                        items: c.aircraftTypeOptions,
                        onChanged: (String? v) {
                          if (v != null) { c.selectedAircraftType.value = v; c.update(); }
                        },
                      );
                    }),
                    const SizedBox(height: 24),

                    // ── CONTRACT ──────────────────────────────────────────────

                    // Contract type
                    const _FieldLabel('Contract Type'),
                    Obx(() => _OptionDrop(
                      hint: 'Select Contract Type',
                      value: c.selectedContractType.value.isEmpty ? null : c.selectedContractType.value,
                      options: const <String>['Permanent', 'Contractor'],
                      onChanged: (String? v) {
                        if (v != null) { c.selectedContractType.value = v; c.update(); }
                      },
                    )),
                    const SizedBox(height: 16),

                    // Country
                    const _FieldLabel('Country'),
                    Obx(() {
                      if (c.loadingCountries.value && c.countries.isEmpty) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                      }
                      if (c.loadingCountriesError.value && c.countries.isEmpty) {
                        return _ErrorRetry(message: 'Could not load countries.', onRetry: c.fetchCountries);
                      }
                      final List<String> countryList = c.countries.keys.toList()..sort();
                      return _SearchableDropdown(
                        hint: 'Select Country',
                        value: c.selectedCountry.value.isEmpty ? null : c.selectedCountry.value,
                        items: <String>[...countryList, 'Other'],
                        onChanged: (String? v) => c.selectCountry(v),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Base / City
                    const _FieldLabel('Base/City'),
                    Obx(() {
                      final String country = c.selectedCountry.value;
                      final List<String>? cities = c.countries[country];
                      if (country.isEmpty) {
                        return _SearchableDropdown(
                          hint: 'Select base or city',
                          value: null,
                          items: const <String>[],
                          onChanged: (_) {},
                        );
                      }
                      if (cities != null) {
                        return _SearchableDropdown(
                          hint: 'Select base or city',
                          value: c.selectedBase.value.isEmpty ? null : c.selectedBase.value,
                          items: cities,
                          onChanged: (String? v) {
                            c.selectedBase.value = v ?? '';
                            c.update();
                          },
                        );
                      }
                      return _TextField(
                        controller: c.baseController,
                        hint: 'Enter base or city',
                        onChanged: (_) => c.update(),
                      );
                    }),
                    const SizedBox(height: 24),

                    // ── COMPENSATION ──────────────────────────────────────────

                    // Amount type
                    const _FieldLabel('Amount Type'),
                    Obx(() => _OptionDrop(
                      hint: 'Gross or Net?',
                      value: c.selectedAmountType.value.isEmpty ? null : c.selectedAmountType.value,
                      options: const <String>['Gross (before tax)', 'Net (after tax)'],
                      onChanged: (String? v) {
                        if (v != null) { c.selectedAmountType.value = v; c.update(); }
                      },
                    )),
                    const SizedBox(height: 16),

                    // Currency
                    const _FieldLabel('Currency'),
                    Obx(() => _OptionDrop(
                      hint: 'Select Currency',
                      value: c.selectedCurrency.value.isEmpty ? null : c.selectedCurrency.value,
                      options: const <String>['NOK', 'EUR', 'GBP', 'USD', 'SEK', 'DKK'],
                      onChanged: (String? v) {
                        if (v != null) { c.selectedCurrency.value = v; c.update(); }
                      },
                    )),
                    const SizedBox(height: 16),

                    // Base salary
                    const _FieldLabel('Base Salary'),
                    _NumberField(
                      controller: c.baseSalaryController,
                      hint: 'Enter base salary',
                      decimal: true,
                      onChanged: (_) => c.update(),
                    ),
                    const SizedBox(height: 16),

                    // Other fixed monthly (optional)
                    const _FieldLabel('Other Fixed Monthly (optional)'),
                    const _SubLabel('Any guaranteed monthly allowances e.g. housing, per diem, command bonus, seniority bonus'),
                    _NumberField(
                      controller: c.fixedMonthlyTotalController,
                      hint: 'Enter fixed monthly total',
                      decimal: true,
                      onChanged: (_) => c.update(),
                    ),
                    const SizedBox(height: 16),

                    // Typical monthly total (optional)
                    const _FieldLabel('Typical Monthly Total (optional)'),
                    const _SubLabel('Your own estimate of what you typically take home per month'),
                    _NumberField(
                      controller: c.typicalMonthlyTotalController,
                      hint: 'Enter typical monthly total',
                      decimal: true,
                      onChanged: (_) => c.update(),
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    Obx(() => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: c.submitting.value ? null : () => _submit(c, title),
                        child: c.submitting.value
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    )),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  // ── Step progress header ──────────────────────────────────────────────────

  Widget _buildStepHeader(SubmitSalaryController c) {
    final List<bool> done = <bool>[c.step1Done, c.step2Done, c.step3Done];
    const List<String> labels = <String>['Position', 'Contract', 'Pay'];
    final int doneCount = done.where((bool d) => d).length;

    return Container(
      color: AppColors.bgSecondary,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        children: <Widget>[
          Row(
            children: List<Widget>.generate(5, (int i) {
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
              value: doneCount / 3,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(SubmitSalaryController c, String title) async {
    if (!c.allCompleted) {
      Get.snackbar(
        'Missing Fields',
        'Please fill in all fields.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.bgCard,
        colorText: AppColors.textPrimary,
      );
      return;
    }
    final bool ok = await c.submit();
    if (ok) {
      final Map<String, dynamic> submitted = <String, dynamic>{
        'airlineName': c.selectedAirline.value!['name'] as String,
        'rank': c.selectedRank.value,
        'aircraftType': c.selectedAircraftType.value,
        'contractType': c.selectedContractType.value,
        'country': c.selectedCountry.value,
        'base': c.selectedCountry.value == 'Other'
            ? c.baseController.text.trim()
            : c.selectedBase.value,
        'currency': c.selectedCurrency.value,
        'baseSalary': double.tryParse(c.baseSalaryController.text) ?? 0.0,
        'seniority': int.tryParse(c.selectedSeniority.value) ?? 0,
        'fixedMonthlyTotal': double.tryParse(c.fixedMonthlyTotalController.text),
        'typicalMonthlyTotal': double.tryParse(c.typicalMonthlyTotalController.text),
        'amountType': c.selectedAmountType.value,
        'isUpdate': widget.existingDocId != null,
      };
      await Get.off<void>(() => SubmitSalaryConfirmScreen(
        data: submitted,
        onDone: widget.onDone,
      ));
    } else {
      Get.snackbar(
        'Error',
        'Could not submit. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.bgCard,
        colorText: AppColors.textPrimary,
      );
    }
  }
}

// ── Confirmation screen ────────────────────────────────────────────────────────

class SubmitSalaryConfirmScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onDone;
  const SubmitSalaryConfirmScreen({super.key, required this.data, this.onDone});

  @override
  Widget build(BuildContext context) {
    final String airlineName = data['airlineName'] as String;
    final String rank = data['rank'] as String;
    final String aircraft = data['aircraftType'] as String;
    final String contract = data['contractType'] as String;
    final String country = data['country'] as String;
    final String base = data['base'] as String;
    final String currency = data['currency'] as String;
    final double baseSalary = data['baseSalary'] as double;
    final int seniority = data['seniority'] as int;
    final bool isUpdate = data['isUpdate'] as bool;
    final double? fixedMonthlyTotal = data['fixedMonthlyTotal'] as double?;
    final double? typicalMonthlyTotal = data['typicalMonthlyTotal'] as double?;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          isUpdate ? 'Update Salary' : 'Submit Salary',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 24),
            const Icon(CupertinoIcons.check_mark_circled_solid, color: AppColors.green, size: 72),
            const SizedBox(height: 14),
            Text(
              isUpdate ? 'Salary updated!' : 'Salary submitted!',
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thank you for contributing to the community.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 28),

            // Summary card with accent left border
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
                              airlineName,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '$rank · $aircraft · $seniority yr',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Column(
                                children: <Widget>[
                                  Text(
                                    '${_fmt(baseSalary)} $currency',
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 44,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -1,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'Base Salary',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                  if (fixedMonthlyTotal != null) ...<Widget>[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        'Other Fixed  ${_fmt(fixedMonthlyTotal)} $currency',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                  if (typicalMonthlyTotal != null) ...<Widget>[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        'Typical  ~${_fmt(typicalMonthlyTotal)} $currency',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: AppColors.border, height: 1),
                            const SizedBox(height: 12),
                            _InfoRow('Contract', contract),
                            _InfoRow('Country', country),
                            _InfoRow('Base/City', base),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onDone?.call();
                  Get.back();
                },
                child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: <Widget>[
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ),
      ],
    ),
  );
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
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry', style: TextStyle(color: AppColors.accent, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// Bottom-sheet option picker — replaces native DropdownButton everywhere
class _OptionDrop extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _OptionDrop({
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
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: value != null ? AppColors.accent : AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                value ?? hint,
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
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SearchSheet(hint: hint, items: options),
    );
    if (picked != null) onChanged(picked);
  }
}

// ── Simple picker (no search, no keyboard) ────────────────────────────────

class _SimpleDrop extends StatelessWidget {
  final String hint;
  final String? value;
  final int count;
  final ValueChanged<String?> onChanged;

  const _SimpleDrop({
    required this.hint,
    required this.value,
    required this.count,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final String? display = value != null ? '$value yr' : null;
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: value != null ? AppColors.accent : AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                display ?? hint,
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
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SimplePickerSheet(selected: value, count: count),
    );
    if (picked != null) onChanged(picked);
  }
}

class _SimplePickerSheet extends StatelessWidget {
  final String? selected;
  final int count;

  const _SimplePickerSheet({required this.selected, required this.count});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
          const Text(
            'Seniority (years)',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: count,
              itemBuilder: (BuildContext ctx, int i) {
                final String item = '${i + 1}';
                final bool isSelected = selected == item;
                return ListTile(
                  title: Text(
                    '$item yr',
                    style: TextStyle(
                      color: isSelected ? AppColors.accent : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.accent, size: 20)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool decimal;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.controller,
    required this.hint,
    this.decimal = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool filled = controller.text.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: filled ? AppColors.accent : AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        keyboardType: decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          decimal
              ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
              : FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          border: InputBorder.none,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _TextField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool filled = controller.text.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: filled ? AppColors.accent : AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          border: InputBorder.none,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _SearchableDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _SearchableDropdown({
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
          border: Border.all(color: value != null ? AppColors.accent : AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                value ?? hint,
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
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SearchSheet(hint: hint, items: items),
    );
    if (picked != null) onChanged(picked);
  }
}

class _SearchSheet extends StatefulWidget {
  final String hint;
  final List<String> items;
  const _SearchSheet({required this.hint, required this.items});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
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
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
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
              itemCount: _visible.length,
              itemBuilder: (BuildContext ctx, int i) => InkWell(
                onTap: () => Navigator.of(ctx).pop(_visible[i]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  child: Text(_visible[i], style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
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
          border: Border.all(color: value != null ? AppColors.accent : AppColors.border),
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
              .where((Map<String, dynamic> a) => (a['name'] as String).toLowerCase().contains(q))
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
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
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
      style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
    ),
  );
}

class _SubLabel extends StatelessWidget {
  final String text;
  const _SubLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
    ),
  );
}
