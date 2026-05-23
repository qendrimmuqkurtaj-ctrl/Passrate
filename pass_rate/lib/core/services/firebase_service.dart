import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<String> getDeviceId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cached = prefs.getString('persistent_device_id');
    if (cached != null && cached.isNotEmpty) return cached;

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String id = '';
    try {
      if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        id = iosInfo.identifierForVendor ?? '';
      } else {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        id = androidInfo.id;
      }
    } catch (_) {}

    if (id.isEmpty) {
      final Random rng = Random.secure();
      final List<int> bytes = List<int>.generate(16, (_) => rng.nextInt(256));
      id = bytes.map((int b) => b.toRadixString(16).padLeft(2, '0')).join();
    }

    await prefs.setString('persistent_device_id', id);
    return id;
  }

  // Propagates exceptions — callers are responsible for error handling.
  static Future<List<Map<String, dynamic>>> getAirlines() async {
    final QuerySnapshot snap = await _db.collection('airlines').get();
    final List<Map<String, dynamic>> list = snap.docs
        .map((DocumentSnapshot d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
    list.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
        (a['name'] as String).compareTo(b['name'] as String));
    return list;
  }

  // Propagates exceptions — callers are responsible for error handling.
  static Future<List<Map<String, dynamic>>> getTasks() async {
    final QuerySnapshot snap = await _db.collection('tasks').get();
    final List<Map<String, dynamic>> list = snap.docs
        .map((DocumentSnapshot d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
    list.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
        (a['name'] as String).compareTo(b['name'] as String));
    return list;
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

  // Propagates exceptions — callers are responsible for error handling.
  static Future<List<Map<String, dynamic>>> getMySubmissions(String deviceId) async {
    final QuerySnapshot snap = await _db
        .collection('submissions')
        .where('deviceId', isEqualTo: deviceId)
        .get();
    final List<Map<String, dynamic>> list = snap.docs
        .map((DocumentSnapshot d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
    // Sort client-side by assessment date (YYYY-MM string) newest first.
    list.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final String da = a['date'] as String? ?? '';
      final String db = b['date'] as String? ?? '';
      return db.compareTo(da);
    });
    return list;
  }

  static Future<bool> deleteSubmission(String id) async {
    try {
      await _db.collection('submissions').doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteSalary(String id) async {
    try {
      await _db.collection('salaries').doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getAirlineStatistics({
    required String airlineName,
    required int year, // 0 = all time
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db.collection('submissions');
      if (airlineName.isNotEmpty) query = query.where('airline', isEqualTo: airlineName);
      if (year != 0) query = query.where('year', isEqualTo: year);
      final QuerySnapshot snap = await query.get();

      if (snap.docs.isEmpty) return null;

      final List<Map<String, dynamic>> docs = snap.docs
          .map((DocumentSnapshot d) => d.data() as Map<String, dynamic>)
          .toList();

      final int total = docs.length;
      final int passedCount = docs.where((Map<String, dynamic> d) => d['passed'] == true).length;
      final int failedCount = total - passedCount;
      final double successRate = total > 0 ? double.parse((passedCount / total * 100).toStringAsFixed(2)) : 0;

      final Map<int, int> monthlyData = <int, int>{};
      for (int i = 1; i <= 12; i++) { monthlyData[i] = 0; }
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
        'airlineName': airlineName.isEmpty ? 'All Airlines' : airlineName,
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
      final Query<Map<String, dynamic>> q = year == 0
          ? _db.collection('submissions')
          : _db.collection('submissions').where('year', isEqualTo: year);
      final QuerySnapshot snap = await q.get();
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

  static Future<Map<String, dynamic>?> getDeviceSalarySubmission(String deviceId) async {
    try {
      final QuerySnapshot snap = await _db
          .collection('salaries')
          .where('deviceId', isEqualTo: deviceId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final DocumentSnapshot doc = snap.docs.first;
      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      final dynamic ts = data['createdAt'];
      final dynamic updatedTs = data['updatedAt'];
      return <String, dynamic>{
        'id': doc.id,
        ...data,
        'createdAt': ts != null ? (ts as Timestamp).toDate() : null,
        'updatedAt': updatedTs != null ? (updatedTs as Timestamp).toDate() : null,
      };
    } catch (e) {
      return null;
    }
  }

  // Propagates exceptions — callers are responsible for error handling.
  static Future<List<String>> getAircraftTypes() async {
    final QuerySnapshot snap = await _db.collection('aircraftTypes').get();
    final List<String> list = snap.docs
        .map((DocumentSnapshot d) => (d.data() as Map<String, dynamic>)['name'] as String? ?? '')
        .where((String s) => s.isNotEmpty)
        .toList()
      ..sort();
    return list;
  }

  // Propagates exceptions — callers are responsible for error handling.
  static Future<Map<String, List<String>>> getCountries() async {
    final QuerySnapshot snap = await _db.collection('countries').get();
    final Map<String, List<String>> result = <String, List<String>>{};
    for (final DocumentSnapshot d in snap.docs) {
      final Map<String, dynamic> data = d.data() as Map<String, dynamic>;
      final String name = data['name'] as String? ?? '';
      final List<dynamic> cities = data['cities'] as List<dynamic>? ?? <dynamic>[];
      if (name.isNotEmpty) {
        result[name] = cities.map((dynamic c) => c.toString()).toList();
      }
    }
    return result;
  }

  static Future<List<Map<String, dynamic>>> getAllSalaries() async {
    try {
      final QuerySnapshot snap = await _db.collection('salaries').get();
      final List<Map<String, dynamic>> list = snap.docs
          .map((DocumentSnapshot d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList();
      list.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
          (a['airline'] as String? ?? '').compareTo(b['airline'] as String? ?? ''));
      return list;
    } catch (e) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> submitSalary({
    required String deviceId,
    required String airlineId,
    required String airlineName,
    required String rank,
    required int seniorityYears,
    required String aircraftType,
    required String contractType,
    required double guaranteedMonthlyPay,
    required String country,
    required String base,
    required String currency,
    String? existingDocId,
    double? allInMonthlyEstimate,
    String? amountType,
    int? totalFlightHours,
  }) async {
    final Map<String, dynamic> data = <String, dynamic>{
      'deviceId': deviceId,
      'airlineId': airlineId,
      'airline': airlineName,
      'rank': rank,
      'seniorityYears': seniorityYears,
      'aircraftType': aircraftType,
      'contractType': contractType,
      'guaranteedMonthlyPay': guaranteedMonthlyPay,
      'country': country,
      'base': base,
      'currency': currency,
      'createdAt': FieldValue.serverTimestamp(),
      if (allInMonthlyEstimate != null) 'allInMonthlyEstimate': allInMonthlyEstimate,
      if (amountType != null && amountType.isNotEmpty) 'amountType': amountType,
      if (totalFlightHours != null) 'totalFlightHours': totalFlightHours,
    };
    final DocumentReference docRef;
    if (existingDocId != null) {
      docRef = _db.collection('salaries').doc(existingDocId);
      await docRef.set(data);
    } else {
      docRef = await _db.collection('salaries').add(data);
    }

    final String? flagReason = await _checkSalaryFlags(
      airlineName: airlineName,
      rank: rank,
      aircraftType: aircraftType,
      guaranteedMonthlyPay: guaranteedMonthlyPay,
      currency: currency,
      currentDocId: docRef.id,
      amountType: amountType ?? '',
    );
    if (flagReason != null) {
      await docRef.update(<String, dynamic>{
        'flagged': true,
        'flagReason': flagReason,
      });
    }
  }

  // Fetches EUR exchange rates with SharedPreferences cache fallback.
  static Future<Map<String, double>> _fetchRates() async {
    bool apiSuccess = false;
    Map<String, double> rates = <String, double>{};
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
      } catch (_) {}
    }

    return rates;
  }

  static double _toEurAmount(double amount, String currency, Map<String, double> rates) {
    if (currency == 'EUR') return amount;
    final double rate = rates[currency] ?? 0;
    return rate > 0 ? amount / rate : 0;
  }

  static String _normalizeAmountType(String? t) =>
      (t == null || t.isEmpty || t.toLowerCase().startsWith('gross')) ? 'gross' : 'net';

  static Future<String?> _checkSalaryFlags({
    required String airlineName,
    required String rank,
    required String aircraftType,
    required double guaranteedMonthlyPay,
    required String currency,
    required String currentDocId,
    required String amountType,
  }) async {
    final Map<String, double> rates = await _fetchRates();

    // Skip all EUR-conversion checks if rates are unavailable.
    if (rates.isEmpty && currency != 'EUR') return null;

    final double guaranteedEur = _toEurAmount(guaranteedMonthlyPay, currency, rates);

    if (guaranteedEur < 1000) return 'Salary unusually low (under 1,000 EUR)';

    final QuerySnapshot snap = await _db
        .collection('salaries')
        .where('airline', isEqualTo: airlineName)
        .get();

    final String normalizedType = _normalizeAmountType(amountType);
    final List<Map<String, dynamic>> others = snap.docs
        .where((DocumentSnapshot d) => d.id != currentDocId)
        .map((DocumentSnapshot d) => d.data() as Map<String, dynamic>)
        .where((Map<String, dynamic> s) =>
            _normalizeAmountType(s['amountType'] as String?) == normalizedType)
        .toList();

    if (rank == 'SO') {
      final Iterable<double> foSalaries = others
          .where((Map<String, dynamic> s) => s['rank'] == 'FO')
          .map((Map<String, dynamic> s) => _toEurAmount(
                (s['guaranteedMonthlyPay'] as num?)?.toDouble()
                    ?? (s['fixedMonthlyTotal'] as num?)?.toDouble()
                    ?? (s['baseSalary'] as num?)?.toDouble() ?? 0,
                s['currency'] as String? ?? 'EUR',
                rates,
              ));
      if (foSalaries.any((double fo) => guaranteedEur > fo)) {
        return 'SO salary higher than FO at same airline';
      }
    }

    if (rank == 'Captain') {
      final Iterable<double> foSalaries = others
          .where((Map<String, dynamic> s) => s['rank'] == 'FO')
          .map((Map<String, dynamic> s) => _toEurAmount(
                (s['guaranteedMonthlyPay'] as num?)?.toDouble()
                    ?? (s['fixedMonthlyTotal'] as num?)?.toDouble()
                    ?? (s['baseSalary'] as num?)?.toDouble() ?? 0,
                s['currency'] as String? ?? 'EUR',
                rates,
              ));
      if (foSalaries.any((double fo) => guaranteedEur < fo)) {
        return 'Captain salary lower than FO at same airline';
      }
    }

    final List<double> peerSalaries = others
        .where((Map<String, dynamic> s) => s['rank'] == rank && s['aircraftType'] == aircraftType)
        .map((Map<String, dynamic> s) => _toEurAmount(
              (s['guaranteedMonthlyPay'] as num?)?.toDouble()
                  ?? (s['fixedMonthlyTotal'] as num?)?.toDouble()
                  ?? (s['baseSalary'] as num?)?.toDouble() ?? 0,
              s['currency'] as String? ?? 'EUR',
              rates,
            ))
        .toList();
    if (peerSalaries.isNotEmpty) {
      final double avg = peerSalaries.reduce((double a, double b) => a + b) / peerSalaries.length;
      if (avg > 0 && (guaranteedEur - avg).abs() / avg > 0.30) {
        return 'Salary deviates more than 30% from peers';
      }
    }

    return null;
  }

  static Future<void> updateSalaryTimestamp(String docId) async {
    try {
      await _db.collection('salaries').doc(docId).update(<String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  static Future<void> seedAircraftTypes() async {
    const List<Map<String, String>> types = <Map<String, String>>[
      // Airbus – Narrowbody
      {'name': 'A220', 'manufacturer': 'Airbus', 'category': 'Narrowbody'},
      {'name': 'A318', 'manufacturer': 'Airbus', 'category': 'Narrowbody'},
      {'name': 'A319', 'manufacturer': 'Airbus', 'category': 'Narrowbody'},
      {'name': 'A320', 'manufacturer': 'Airbus', 'category': 'Narrowbody'},
      {'name': 'A321', 'manufacturer': 'Airbus', 'category': 'Narrowbody'},
      // Airbus – Widebody
      {'name': 'A330', 'manufacturer': 'Airbus', 'category': 'Widebody'},
      {'name': 'A340', 'manufacturer': 'Airbus', 'category': 'Widebody'},
      {'name': 'A350', 'manufacturer': 'Airbus', 'category': 'Widebody'},
      {'name': 'A380', 'manufacturer': 'Airbus', 'category': 'Widebody'},
      // Boeing – Narrowbody
      {'name': '737-700', 'manufacturer': 'Boeing', 'category': 'Narrowbody'},
      {'name': '737-800', 'manufacturer': 'Boeing', 'category': 'Narrowbody'},
      {'name': '737-900', 'manufacturer': 'Boeing', 'category': 'Narrowbody'},
      {'name': '737 MAX', 'manufacturer': 'Boeing', 'category': 'Narrowbody'},
      {'name': '757',     'manufacturer': 'Boeing', 'category': 'Narrowbody'},
      // Boeing – Widebody
      {'name': '767', 'manufacturer': 'Boeing', 'category': 'Widebody'},
      {'name': '777', 'manufacturer': 'Boeing', 'category': 'Widebody'},
      {'name': '787', 'manufacturer': 'Boeing', 'category': 'Widebody'},
      // Embraer – Regional
      {'name': 'E170', 'manufacturer': 'Embraer', 'category': 'Regional'},
      {'name': 'E175', 'manufacturer': 'Embraer', 'category': 'Regional'},
      {'name': 'E190', 'manufacturer': 'Embraer', 'category': 'Regional'},
      {'name': 'E195', 'manufacturer': 'Embraer', 'category': 'Regional'},
      // Bombardier – Regional
      {'name': 'Q400',    'manufacturer': 'Bombardier', 'category': 'Regional'},
      {'name': 'CRJ-900', 'manufacturer': 'Bombardier', 'category': 'Regional'},
      // ATR – Regional
      {'name': 'ATR-42', 'manufacturer': 'ATR', 'category': 'Regional'},
      {'name': 'ATR-72', 'manufacturer': 'ATR', 'category': 'Regional'},
    ];

    try {
      final CollectionReference col = _db.collection('aircraftTypes');
      final QuerySnapshot existing = await col.get();
      final Set<String> existingIds = existing.docs.map((DocumentSnapshot d) => d.id).toSet();

      final WriteBatch batch = _db.batch();
      int added = 0;
      for (final Map<String, String> type in types) {
        final String name = type['name']!;
        if (!existingIds.contains(name)) {
          batch.set(col.doc(name), type);
          added++;
        }
      }
      if (added > 0) await batch.commit();
    } catch (_) {}
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
      final Query<Map<String, dynamic>> q = year == 0
          ? _db.collection('submissions')
          : _db.collection('submissions').where('year', isEqualTo: year);
      final QuerySnapshot snap = await q.get();
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
