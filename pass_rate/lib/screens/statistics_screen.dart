import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/firebase_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String? selectedAirline;
  int? selectedYear;
  bool loading = false;
  bool loadingAirlines = true;
  List<String> airlines = [];
  Map<String, dynamic>? stats;
  final years = List.generate(10, (i) => DateTime.now().year - i);

  @override
  void initState() {
    super.initState();
    _loadAirlines();
    _search();
  }

  Future<void> _loadAirlines() async {
    final list = await FirebaseService.getAirlines();
    setState(() {
      airlines = list.map((a) => a['name'] as String).toList();
      loadingAirlines = false;
    });
  }

  Future<void> _search() async {
    setState(() => loading = true);
    final result = await FirebaseService.getStatistics(airline: selectedAirline, year: selectedYear);
    setState(() { stats = result; loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF0D2B5E)), onPressed: () => Get.back()),
        title: const Text('Statistics Overview', style: TextStyle(color: Color(0xFF0D2B5E), fontWeight: FontWeight.w600, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Check Pass Rates &\nAssessment Content',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D2B5E))),
            const SizedBox(height: 20),

            // Airline dropdown
            _buildDropdown('Airline Name', 'Choose the Airline Name', selectedAirline,
              loadingAirlines ? [] : ['', ...airlines],
              (v) => setState(() => selectedAirline = v?.isEmpty == true ? null : v)),
            const SizedBox(height: 14),

            // Year dropdown
            _buildDropdown('Select Year and Month', 'Choose the year of assessment', selectedYear?.toString(),
              ['', ...years.map((y) => y.toString())],
              (v) => setState(() => selectedYear = v?.isEmpty == true ? null : int.tryParse(v ?? ''))),
            const SizedBox(height: 16),

            // Search button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.search, size: 20),
                label: const Text('Search', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D2B5E),
                  side: const BorderSide(color: Color(0xFF0D2B5E), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 28),

            const Text('Top Results', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D2B5E))),
            const SizedBox(height: 16),

            if (loading)
              const Center(child: CircularProgressIndicator(color: Color(0xFF0D2B5E)))
            else if (stats != null) ...[
              // Total & pass rate summary
              if (stats!['total'] > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF0D2B5E).withOpacity(0.1))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem('Total', '${stats!['total']}'),
                      _StatItem('Pass Rate', '${stats!['passRate']}%'),
                      _StatItem('Passed', '${stats!['passed']}'),
                    ],
                  ),
                ),

              // Top 5 by pass rate
              _TopList('Top 5 Airlines by Pass Rate', stats!['top5PassRate'] as List, 'passRate', '%'),
              const SizedBox(height: 14),
              _TopList('Top Airlines by Submission Count', stats!['top5Count'] as List, 'total', ' submissions'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String hint, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0D2B5E).withOpacity(0.2))),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(label, style: const TextStyle(color: Color(0xFF1A9EF5), fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text(hint, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              value: value,
              icon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF0D2B5E), size: 18),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.isEmpty ? hint : e, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D2B5E))),
    Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
  ]);
}

class _TopList extends StatelessWidget {
  final String title;
  final List items;
  final String valueKey, suffix;
  const _TopList(this.title, this.items, this.valueKey, this.suffix);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0D2B5E).withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0D2B5E))),
            ]),
          ),
          if (items.isEmpty)
            const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text('Ingen data ennå', style: TextStyle(color: Colors.grey, fontSize: 13)))
          else
            ...items.map((item) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(children: [
                Expanded(child: Text(item['airline'] ?? '', style: const TextStyle(fontSize: 14, color: Color(0xFF0D2B5E)))),
                Text('${item[valueKey]}$suffix', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0D2B5E))),
              ]),
            )),
        ],
      ),
    );
  }
}
