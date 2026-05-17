import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/services/firebase_service.dart';

class SubmitSalaryController extends GetxController {
  final RxBool loadingAirlines = true.obs;
  final RxBool submitting = false.obs;
  String? existingDocId;

  final RxList<Map<String, dynamic>> airlines = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>?> selectedAirline = Rx<Map<String, dynamic>?>(null);
  final RxString selectedRank = ''.obs;
  final RxString selectedAircraftType = ''.obs;
  final RxString selectedContractType = ''.obs;
  final RxString selectedCurrency = ''.obs;

  final TextEditingController seniorityController = TextEditingController();
  final TextEditingController baseSalaryController = TextEditingController();
  final TextEditingController perDiemController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  bool get allCompleted =>
      selectedAirline.value != null &&
      selectedRank.value.isNotEmpty &&
      seniorityController.text.isNotEmpty &&
      selectedAircraftType.value.isNotEmpty &&
      selectedContractType.value.isNotEmpty &&
      baseSalaryController.text.isNotEmpty &&
      perDiemController.text.isNotEmpty &&
      countryController.text.trim().isNotEmpty &&
      selectedCurrency.value.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _loadAirlines();
  }

  @override
  void onClose() {
    seniorityController.dispose();
    baseSalaryController.dispose();
    perDiemController.dispose();
    countryController.dispose();
    super.onClose();
  }

  Future<void> _loadAirlines() async {
    loadingAirlines.value = true;
    airlines.value = await FirebaseService.getAirlines();
    loadingAirlines.value = false;
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
        seniorityYears: int.tryParse(seniorityController.text) ?? 0,
        aircraftType: selectedAircraftType.value,
        contractType: selectedContractType.value,
        baseSalary: double.tryParse(baseSalaryController.text) ?? 0,
        perDiem: double.tryParse(perDiemController.text) ?? 0,
        country: countryController.text.trim(),
        currency: selectedCurrency.value,
        existingDocId: existingDocId,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      submitting.value = false;
    }
  }
}

class SubmitSalaryScreen extends StatelessWidget {
  final String? existingDocId;
  const SubmitSalaryScreen({super.key, this.existingDocId});

  @override
  Widget build(BuildContext context) {
    final SubmitSalaryController c = Get.put(SubmitSalaryController());
    c.existingDocId = existingDocId;

    final String title = existingDocId != null ? 'Update Salary' : 'Submit Salary';

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),

            // Airline
            const _FieldLabel('Airline'),
            Obx(() => c.loadingAirlines.value
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : _Dropdown<Map<String, dynamic>>(
                  hint: 'Select Airline',
                  value: c.selectedAirline.value,
                  items: c.airlines.map((Map<String, dynamic> a) => DropdownMenuItem<Map<String, dynamic>>(
                    value: a,
                    child: Text(a['name'] as String, style: const TextStyle(color: AppColors.textPrimary)),
                  )).toList(),
                  onChanged: (Map<String, dynamic>? v) { c.selectedAirline.value = v; },
                )),
            const SizedBox(height: 16),

            // Rank
            const _FieldLabel('Rank'),
            Obx(() => _Dropdown<String>(
              hint: 'Select Rank',
              value: c.selectedRank.value.isEmpty ? null : c.selectedRank.value,
              items: <String>['SO', 'FO', 'Captain'].map((String r) => DropdownMenuItem<String>(
                value: r,
                child: Text(r, style: const TextStyle(color: AppColors.textPrimary)),
              )).toList(),
              onChanged: (String? v) { if (v != null) c.selectedRank.value = v; },
            )),
            const SizedBox(height: 16),

            // Seniority
            const _FieldLabel('Seniority (years)'),
            _NumberField(
              controller: c.seniorityController,
              hint: 'Enter years of seniority',
              onChanged: (_) => c.update(),
            ),
            const SizedBox(height: 16),

            // Aircraft type
            const _FieldLabel('Aircraft Type'),
            Obx(() => _Dropdown<String>(
              hint: 'Select Aircraft Type',
              value: c.selectedAircraftType.value.isEmpty ? null : c.selectedAircraftType.value,
              items: <String>['Narrowbody', 'Widebody'].map((String a) => DropdownMenuItem<String>(
                value: a,
                child: Text(a, style: const TextStyle(color: AppColors.textPrimary)),
              )).toList(),
              onChanged: (String? v) { if (v != null) c.selectedAircraftType.value = v; },
            )),
            const SizedBox(height: 16),

            // Contract type
            const _FieldLabel('Contract Type'),
            Obx(() => _Dropdown<String>(
              hint: 'Select Contract Type',
              value: c.selectedContractType.value.isEmpty ? null : c.selectedContractType.value,
              items: <String>['Permanent', 'Contractor'].map((String ct) => DropdownMenuItem<String>(
                value: ct,
                child: Text(ct, style: const TextStyle(color: AppColors.textPrimary)),
              )).toList(),
              onChanged: (String? v) { if (v != null) c.selectedContractType.value = v; },
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

            // Per diem
            const _FieldLabel('Per Diem'),
            _NumberField(
              controller: c.perDiemController,
              hint: 'Enter per diem',
              decimal: true,
              onChanged: (_) => c.update(),
            ),
            const SizedBox(height: 16),

            // Country
            const _FieldLabel('Country'),
            _TextField(
              controller: c.countryController,
              hint: 'Enter country',
              onChanged: (_) => c.update(),
            ),
            const SizedBox(height: 16),

            // Currency
            const _FieldLabel('Currency'),
            Obx(() => _Dropdown<String>(
              hint: 'Select Currency',
              value: c.selectedCurrency.value.isEmpty ? null : c.selectedCurrency.value,
              items: <String>['NOK', 'EUR', 'GBP', 'USD', 'SEK', 'DKK'].map((String cur) => DropdownMenuItem<String>(
                value: cur,
                child: Text(cur, style: const TextStyle(color: AppColors.textPrimary)),
              )).toList(),
              onChanged: (String? v) { if (v != null) c.selectedCurrency.value = v; },
            )),
            const SizedBox(height: 32),

            // Submit button
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: c.submitting.value ? null : () => _submit(c),
                child: c.submitting.value
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            )),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(SubmitSalaryController c) async {
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
      Get.back();
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

class _Dropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.accent),
          dropdownColor: AppColors.bgCard,
          items: items,
          onChanged: onChanged,
        ),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
  );
}
