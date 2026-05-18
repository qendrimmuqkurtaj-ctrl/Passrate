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
  final RxBool submitting = false.obs;
  String? existingDocId;

  final RxMap<String, List<String>> countries = <String, List<String>>{}.obs;

  final RxList<Map<String, dynamic>> airlines = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>?> selectedAirline = Rx<Map<String, dynamic>?>(null);
  final RxString selectedRank = ''.obs;
  final RxString selectedAircraftType = ''.obs;
  final RxString selectedContractType = ''.obs;
  final RxString selectedCurrency = ''.obs;
  final RxString selectedCountry = ''.obs;
  final RxString selectedBase = ''.obs;

  final TextEditingController seniorityController = TextEditingController();
  final TextEditingController baseSalaryController = TextEditingController();
  final TextEditingController perDiemController = TextEditingController();
  final TextEditingController baseController = TextEditingController();

  bool get _baseCompleted {
    if (selectedCountry.value == 'Other') return baseController.text.trim().isNotEmpty;
    return selectedBase.value.isNotEmpty;
  }

  bool get allCompleted =>
      selectedAirline.value != null &&
      selectedRank.value.isNotEmpty &&
      seniorityController.text.isNotEmpty &&
      selectedAircraftType.value.isNotEmpty &&
      selectedContractType.value.isNotEmpty &&
      baseSalaryController.text.isNotEmpty &&
      perDiemController.text.isNotEmpty &&
      selectedCountry.value.isNotEmpty &&
      _baseCompleted &&
      selectedCurrency.value.isNotEmpty;

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
  }

  @override
  void onClose() {
    seniorityController.dispose();
    baseSalaryController.dispose();
    perDiemController.dispose();
    baseController.dispose();
    super.onClose();
  }

  Future<void> fetchAirlines() async {
    loadingAirlines.value = true;
    try {
      airlines.value = await FirebaseService.getAirlines();
    } finally {
      loadingAirlines.value = false;
    }
  }

  Future<void> fetchCountries() async {
    loadingCountries.value = true;
    try {
      countries.value = await FirebaseService.getCountries();
    } finally {
      loadingCountries.value = false;
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
        seniorityYears: int.tryParse(seniorityController.text) ?? 0,
        aircraftType: selectedAircraftType.value,
        contractType: selectedContractType.value,
        baseSalary: double.tryParse(baseSalaryController.text) ?? 0,
        perDiem: double.tryParse(perDiemController.text) ?? 0,
        country: selectedCountry.value,
        base: selectedCountry.value == 'Other'
            ? baseController.text.trim()
            : selectedBase.value,
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
              : _AirlineSearchableDropdown(
                  hint: 'Select Airline',
                  value: c.selectedAirline.value,
                  items: c.airlines,
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
            Obx(() => _SearchableDropdown(
              hint: 'Select Aircraft Type',
              value: c.selectedAircraftType.value.isEmpty ? null : c.selectedAircraftType.value,
              items: kAircraftTypes,
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
            Obx(() {
              if (c.loadingCountries.value && c.countries.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accent));
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

            // Base / City — dropdown for known countries, free text for Other
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
                  onChanged: (String? v) { c.selectedBase.value = v ?? ''; },
                );
              }
              // Other — free text
              return _TextField(
                controller: c.baseController,
                hint: 'Enter base or city',
                onChanged: (_) => c.update(),
              );
            }),
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
          border: Border.all(color: AppColors.border),
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
          : widget.items.where((Map<String, dynamic> a) => (a['name'] as String).toLowerCase().contains(q)).toList();
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
              itemCount: _visible.length,
              itemBuilder: (BuildContext ctx, int i) => InkWell(
                onTap: () => Navigator.of(ctx).pop(_visible[i]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  child: Text(_visible[i]['name'] as String, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
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
    child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
  );
}
