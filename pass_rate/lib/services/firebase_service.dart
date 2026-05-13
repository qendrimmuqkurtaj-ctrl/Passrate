import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Airlines
  static Future<List<Map<String, dynamic>>> getAirlines() async {
    final snap = await _db.collection('airlines').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  // Submit assessment
  static Future<void> submitAssessment({
    required String airline,
    required int year,
    required String tasks,
    required bool passed,
  }) async {
    await _db.collection('submissions').add({
      'airline': airline,
      'year': year,
      'tasks': tasks,
      'result': passed ? 'passed' : 'failed',
      'passed': passed,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all submissions
  static Future<List<Map<String, dynamic>>> getSubmissions() async {
    final snap = await _db.collection('submissions').orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  // Get statistics
  static Future<Map<String, dynamic>> getStatistics({String? airline, int? year}) async {
    Query query = _db.collection('submissions');
    if (airline != null && airline.isNotEmpty) query = query.where('airline', isEqualTo: airline);
    if (year != null) query = query.where('year', isEqualTo: year);
    final snap = await query.get();
    final docs = snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
    final total = docs.length;
    final passed = docs.where((d) => d['passed'] == true || d['result'] == 'passed').length;
    final passRate = total > 0 ? (passed / total * 100).round() : 0;

    // Top 5 by pass rate
    final byAirline = <String, Map<String, int>>{};
    for (final d in docs) {
      final a = d['airline'] as String? ?? 'Unknown';
      byAirline[a] ??= {'pass': 0, 'total': 0};
      byAirline[a]!['total'] = byAirline[a]!['total']! + 1;
      if (d['passed'] == true || d['result'] == 'passed') {
        byAirline[a]!['pass'] = byAirline[a]!['pass']! + 1;
      }
    }
    final top5PassRate = byAirline.entries
        .where((e) => e.value['total']! >= 1)
        .map((e) => {'airline': e.key, 'passRate': e.value['total']! > 0 ? (e.value['pass']! / e.value['total']! * 100).round() : 0, 'total': e.value['total']})
        .toList()
      ..sort((a, b) => (b['passRate'] as int).compareTo(a['passRate'] as int));

    final top5Count = byAirline.entries
        .map((e) => {'airline': e.key, 'total': e.value['total'], 'passRate': e.value['total']! > 0 ? (e.value['pass']! / e.value['total']! * 100).round() : 0})
        .toList()
      ..sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));

    return {
      'total': total,
      'passed': passed,
      'passRate': passRate,
      'top5PassRate': top5PassRate.take(5).toList(),
      'top5Count': top5Count.take(5).toList(),
    };
  }
}
