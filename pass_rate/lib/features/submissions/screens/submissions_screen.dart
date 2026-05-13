import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/services/firebase_service.dart';

class SubmissionsController extends GetxController {
  final RxBool loading = false.obs;
  final RxList<Map<String, dynamic>> submissions = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filtered = <Map<String, dynamic>>[].obs;
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadSubmissions();
    searchQuery.listen((_) => _filter());
  }

  Future<void> loadSubmissions() async {
    loading.value = true;
    final String deviceId = await FirebaseService.getDeviceId();
    submissions.value = await FirebaseService.getMySubmissions(deviceId);
    _filter();
    loading.value = false;
  }

  void _filter() {
    if (searchQuery.value.isEmpty) {
      filtered.value = submissions;
    } else {
      final String q = searchQuery.value.toLowerCase();
      filtered.value = submissions.where((Map<String, dynamic> s) {
        final String airline = (s['airline'] as String? ?? '').toLowerCase();
        final List<dynamic> tasks = s['assessments'] as List<dynamic>? ?? <dynamic>[];
        return airline.contains(q) || tasks.any((dynamic t) => t.toString().toLowerCase().contains(q));
      }).toList();
    }
  }

  Future<void> deleteSubmission(Map<String, dynamic> submission) async {
    final bool success = await FirebaseService.deleteSubmission(submission['id'] as String);
    if (success) {
      submissions.remove(submission);
      _filter();
      Get.snackbar('Slettet', 'Submission slettet', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }
}

class SubmissionsScreen extends StatelessWidget {
  const SubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SubmissionsController c = Get.put(SubmissionsController());

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor), onPressed: () => Get.back()),
        title: const Text('My Submissions', style: TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.w600, fontSize: 16)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Obx(() => TextField(
              controller: c.searchController,
              onChanged: (String v) => c.searchQuery.value = v,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(CupertinoIcons.search, color: AppColors.primaryColor),
                suffixIcon: c.searchQuery.value.isNotEmpty
                  ? IconButton(icon: const Icon(CupertinoIcons.clear, color: AppColors.primaryColor), onPressed: c.clearSearch)
                  : null,
              ),
            )),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(CupertinoIcons.search, color: Colors.white),
                label: const Text('Search', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (c.loading.value) return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
                if (c.filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(CupertinoIcons.airplane, size: 60, color: AppColors.primaryColor.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(c.searchQuery.value.isNotEmpty ? 'Ingen treff' : 'Ingen submissions ennå', style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: c.filtered.length,
                  separatorBuilder: (BuildContext _, int __) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int i) {
                    final Map<String, dynamic> sub = c.filtered[i];
                    return _SubmissionTile(submission: sub, onDelete: () => _confirmDelete(context, c, sub));
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SubmissionsController c, Map<String, dynamic> sub) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Vil du slette denne?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Row(children: <Widget>[
              Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(ctx); c.deleteSubmission(sub); }, child: const Text('Ja'))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Nei'))),
            ]),
          ],
        ),
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  final Map<String, dynamic> submission;
  final VoidCallback onDelete;
  const _SubmissionTile({required this.submission, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bool isPassed = submission['passed'] == true || submission['result'] == 'passed' || submission['status'] == 'passed';
    final dynamic createdAt = submission['createdAt'];
    DateTime? date;
    if (createdAt is Timestamp) {
      date = createdAt.toDate();
    }
    final String formattedDate = date != null ? DateFormat('yyyy - MMMM').format(date) : '${submission['year'] ?? '—'}';
    final List<dynamic> assessments = submission['assessments'] as List<dynamic>? ?? <dynamic>[];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primaryColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
            Expanded(child: Text(submission['airline'] as String? ?? '—', style: Theme.of(context).textTheme.titleMedium)),
            IconButton(icon: const Icon(CupertinoIcons.delete, color: AppColors.red, size: 20), onPressed: onDelete),
          ]),
          Text(formattedDate, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
            const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isPassed ? AppColors.green.withOpacity(0.1) : AppColors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isPassed ? AppColors.green : AppColors.red),
              ),
              child: Text(isPassed ? 'passed' : 'failed', style: TextStyle(color: isPassed ? AppColors.green : AppColors.red, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ]),
          if (assessments.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            const Text('Assessment:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            ...assessments.map((dynamic a) => Text('- ${a.toString()[0].toUpperCase()}${a.toString().substring(1)}', style: const TextStyle(fontSize: 13))),
          ],
        ],
      ),
    );
  }
}
