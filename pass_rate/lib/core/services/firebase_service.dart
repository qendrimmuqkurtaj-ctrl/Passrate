import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown-ios';
      } else {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      }
    } catch (e) {
      return 'unknown-device';
    }
  }

  static Future<List<Map<String, dynamic>>> getAirlines() async {
    try {
      final QuerySnapshot snap = await _db.collection('airlines').get();
      final List<Map<String, dynamic>> list = snap.docs
          .map((DocumentSnapshot d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList();
      list.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
          (a['name'] as String).compareTo(b['name'] as String));
      return list;
    } catch (e) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      final QuerySnapshot snap = await _db.collection('tasks').get();
      final List<Map<String, dynamic>> list = snap.docs
          .map((DocumentSnapshot d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList();
      list.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
          (a['name'] as String).compareTo(b['name'] as String));
      return list;
    } catch (e) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<Map<String, dynamic>> submitAssessment({
    required String airlineId,
    required String airlineName,
    required int year,
    required int month,
    required List<String> taskIds,
    required List<String> taskNames,
    required bool passed,
    required String deviceId,
  }) async {
    final DocumentReference ref = await _db.collection('submissions').add({
      'airlineId': airlineId,
      'airline': airlineName,
      'year': year,
      'month': month,
      'date': '$year-${month.toString().padLeft(2, '0')}',
      'taskIds': taskIds,
      'assessments': taskNames,
      'result': passed ? 'passed' : 'failed',
      'passed': passed,
      'status': passed ? 'passed' : 'failed',
      'deviceId': deviceId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final QuerySnapshot allSubs = await _db
        .collection('submissions')
        .where('airlineId', isEqualTo: airlineId)
        .where('year', isEqualTo: year)
        .get();

    final int total = allSubs.docs.length;
    final int passedCount = allSubs.docs
        .where((DocumentSnapshot d) => (d.data() as Map<String, dynamic>)['passed'] == true)
        .length;
    final double successRate = total > 0 ? (passedCount / total * 100) : 0;

    return {
      'id': ref.id,
      'airlineName': airlineName,
      'year': year,
      'month': month,
      'totalResponse': total,
      'successRate': successRate,
    };
  }

  static Future<List<Map<String, dynamic>>> getMySubmissions(String deviceId) async {
    try {
      final QuerySnapshot snap = await _db
          .collection('submissions')
          .where('deviceId', isEqualTo: deviceId)
          .get();
      return snap.docs
          .map((DocumentSnapshot d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<bool> deleteSubmission(String id) async {
    try {
      await _db.collection('submissions').doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getAirlineStatistics({
    required String airlineName,
    required int year,
  }) async {
    try {
      final QuerySnapshot snap = await _db
          .collection('submissions')
          .where('airline', isEqualTo: airlineName)
          .where('year', isEqualTo: year)
          .get();

      if (snap.docs.isEmpty) return null;

      final List<Map<String, dynamic>> docs = snap.docs
          .map((DocumentSnapshot d) => d.data() as Map<String, dynamic>)
          .toList();

      final int total = docs.length;
      final int passedCount = docs.where((Map<String, dynamic> d) => d['passed'] == true).length;
      final int failedCount = total - passedCount;
      final double successRate = total > 0 ? double.parse((passedCount / total * 100).toStringAsFixed(2)) : 0;

      final Map<int, int> monthlyData = <int, int>{};
      for (int i = 1; i <= 12; i++) monthlyData[i] = 0;
      for (final Map<String, dynamic> doc in docs) {
        final int month = (doc['month'] as int?) ?? 0;
        if (month >= 1 && month <= 12) monthlyData[month] = (monthlyData[month] ?? 0) + 1;
      }

      final Map<String, int> taskCount = <String, int>{};
      for (final Map<String, dynamic> doc in docs) {
        final List<dynamic> tasks = doc['assessments'] as List<dynamic>? ?? <dynamic>[];
        for (final dynamic task in tasks) {
          final String taskName = task.toString();
          taskCount[taskName] = (taskCount[taskName] ?? 0) + 1;
        }
      }
      final List<MapEntry<String, int>> sortedEntries = taskCount.entries.toList()
        ..sort((MapEntry<String, int> a, MapEntry<String, int> b) => b.value.compareTo(a.value));
      final List<String> assessments = sortedEntries.map((MapEntry<String, int> e) => e.key).toList();

      return <String, dynamic>{
        'airlineName': airlineName,
        'year': year,
        'totalSubmissions': total,
        'pass': passedCount,
        'fail': failedCount,
        'successRate': successRate,
        'assessments': assessments,
        'monthlyData': monthlyData,
      };
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getTopAirlinesByPassRate(int year) async {
    try {
      final QuerySnapshot snap = await _db.collection('submissions').where('year', isEqualTo: year).get();
      final Map<String, Map<String, dynamic>> byAirline = <String, Map<String, dynamic>>{};
      for (final DocumentSnapshot doc in snap.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final String airline = data['airline'] as String? ?? 'Unknown';
        byAirline[airline] ??= <String, dynamic>{'pass': 0, 'total': 0};
        byAirline[airline]!['total'] = (byAirline[airline]!['total'] as int) + 1;
        if (data['passed'] == true) byAirline[airline]!['pass'] = (byAirline[airline]!['pass'] as int) + 1;
      }
      final List<Map<String, dynamic>> result = byAirline.entries.map((MapEntry<String, Map<String, dynamic>> e) {
        final int total = e.value['total'] as int;
        final int pass = e.value['pass'] as int;
        return <String, dynamic>{'name': e.key, 'successRate': total > 0 ? double.parse((pass / total * 100).toStringAsFixed(1)) : 0.0, 'submissionCount': total};
      }).toList();
      result.sort((Map<String, dynamic> a, Map<String, dynamic> b) => (b['successRate'] as double).compareTo(a['successRate'] as double));
      return result.take(5).toList();
    } catch (e) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<int> getTotalSubmissionsCount() async {
    try {
      final AggregateQuerySnapshot snap =
          await _db.collection('submissions').count().get();
      return snap.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> getTopAirlinesBySubmission(int year) async {
    try {
      final QuerySnapshot snap = await _db.collection('submissions').where('year', isEqualTo: year).get();
      final Map<String, int> byAirline = <String, int>{};
      for (final DocumentSnapshot doc in snap.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final String airline = data['airline'] as String? ?? 'Unknown';
        byAirline[airline] = (byAirline[airline] ?? 0) + 1;
      }
      final List<Map<String, dynamic>> result = byAirline.entries.map((MapEntry<String, int> e) => <String, dynamic>{'name': e.key, 'submissionCount': e.value}).toList();
      result.sort((Map<String, dynamic> a, Map<String, dynamic> b) => (b['submissionCount'] as int).compareTo(a['submissionCount'] as int));
      return result.take(5).toList();
    } catch (e) {
      return <Map<String, dynamic>>[];
    }
  }
}
