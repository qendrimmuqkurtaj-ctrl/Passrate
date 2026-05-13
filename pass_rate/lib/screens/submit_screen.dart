import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/firebase_service.dart';

class SubmitScreen extends StatefulWidget {
  const SubmitScreen({super.key});

  @override
  State<SubmitScreen> createState() => _SubmitScreenState();
}

class _SubmitScreenState extends State<SubmitScreen> {
  String? selectedAirline;
  int? selectedYear;
  String? selectedTasks;
  bool? passed;
  bool loading = false;
  bool loadingAirlines = true;
  List<String> airlines = [];

  final taskOptions = ['Simulator', 'Technical Interview', 'HR Interview', 'Medical', 'Psychomotor', 'Group Exercise', 'Other'];
  final years = List.generate(10, (i) => DateTime.now().year - i);

  @override
  void initState() {
    super.initState();
    _loadAirlines();
  }

  Future<void> _loadAirlines() async {
    try {
      final list = await FirebaseService.getAirlines();
      print('Airlines loaded: ${list.length}');
      setState(() {
        airlines = list.map((a) => a['name'] as String).toList();
        loadingAirlines = false;
      });
    } catch (e) {
      print('Error loading airlines: $e');
      setState(() => loadingAirlines = false);
    }
  }

  Future<void> _submit() async {
    if (selectedAirline == null || selectedYear == null || passed == null) {
      Get.snackbar('Mangler info', 'Velg flyselskap, år og resultat',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800);
      return;
    }
    setState(() => loading = true);
    try {
      await FirebaseService.submitAssessment(
        airline: selectedAirline!,
        year: selectedYear!,
        tasks: selectedTasks ?? '',
        passed: passed!,
      );
      Get.back();
      Get.snackbar('Sendt inn! ✅', 'Takk for ditt bidrag!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800);
    } catch (e) {
      Get.snackbar('Feil', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0D2B5E)),
            onPressed: () => Get.back()),
        title: const Text('Submit Result',
            style: TextStyle(color: Color(0xFF0D2B5E), fontWeight: FontWeight.w600, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Submit Result',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D2B5E))),
            const SizedBox(height: 24),

            _FieldLabel('Airline Name'),
            loadingAirlines
                ? const Center(child: CircularProgressIndicator())
                : airlines.isEmpty
                    ? const Text('Ingen flyselskaper funnet', style: TextStyle(color: Colors.red, fontSize: 13))
                    : _Dropdown(
                        hint: 'Choose the Airline Name',
                        value: selectedAirline,
                        items: airlines,
                        onChanged: (v) => setState(() => selectedAirline = v),
                      ),
            const SizedBox(height: 16),

            _FieldLabel('Select Year and Month'),
            _Dropdown(
              hint: 'Choose the year of assessment',
              value: selectedYear?.toString(),
              items: years.map((y) => y.toString()).toList(),
              onChanged: (v) => setState(() => selectedYear = int.tryParse(v ?? '')),
            ),
            const SizedBox(height: 16),

            _FieldLabel('What was included in your assessment?'),
            _Dropdown(
              hint: 'Choose tasks',
              value: selectedTasks,
              items: taskOptions,
              onChanged: (v) => setState(() => selectedTasks = v),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => passed = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: passed == true ? const Color(0xFF1D9E75).withOpacity(0.1) : Colors.white,
                        border: Border.all(color: passed == true ? const Color(0xFF1D9E75) : Colors.grey.shade300, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF1D9E75), size: 22),
                        const SizedBox(width: 8),
                        const Text('Passed', style: TextStyle(color: Color(0xFF1D9E75), fontWeight: FontWeight.w600, fontSize: 15)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => passed = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: passed == false ? Colors.red.shade50 : Colors.white,
                        border: Border.all(color: passed == false ? Colors.red.shade400 : Colors.grey.shade300, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.cancel_outlined, color: Colors.red.shade400, size: 22),
                        const SizedBox(width: 8),
                        Text('Failed', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600, fontSize: 15)),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2B5E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
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
        child: Text(text, style: const TextStyle(color: Color(0xFF1A9EF5), fontSize: 13, fontWeight: FontWeight.w500)),
      );
}

class _Dropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _Dropdown({required this.hint, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0D2B5E).withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0D2B5E)),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
