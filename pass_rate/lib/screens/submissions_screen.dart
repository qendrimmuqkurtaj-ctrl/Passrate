import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/firebase_service.dart';

class SubmissionsScreen extends StatefulWidget {
  const SubmissionsScreen({super.key});

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  List<Map<String, dynamic>> submissions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await FirebaseService.getSubmissions();
    setState(() { submissions = list; loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF0D2B5E)), onPressed: () => Get.back()),
        title: const Text('Your Submissions', style: TextStyle(color: Color(0xFF0D2B5E), fontWeight: FontWeight.w600, fontSize: 16)),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D2B5E)))
          : submissions.isEmpty
              ? const Center(child: Text('Ingen innsendte resultater ennå', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: submissions.length,
                  itemBuilder: (context, i) {
                    final s = submissions[i];
                    final passed = s['passed'] == true || s['result'] == 'passed';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s['airline'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF0D2B5E))),
                          const SizedBox(height: 4),
                          Text('${s['year'] ?? '—'}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: passed ? const Color(0xFF1D9E75).withOpacity(0.1) : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(passed ? '✅ Passed' : '❌ Failed',
                            style: TextStyle(color: passed ? const Color(0xFF1D9E75) : Colors.red.shade400, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ]),
                    );
                  },
                ),
    );
  }
}
