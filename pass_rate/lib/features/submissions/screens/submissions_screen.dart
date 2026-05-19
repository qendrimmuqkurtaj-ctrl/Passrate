import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/services/firebase_service.dart';

class SubmissionsController extends GetxController {
  final RxBool loading = false.obs;
  final RxBool hasError = false.obs;
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

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadSubmissions() async {
    loading.value = true;
    hasError.value = false;
    try {
      final String deviceId = await FirebaseService.getDeviceId();
      submissions.value = await FirebaseService.getMySubmissions(deviceId);
      _filter();
    } catch (_) {
      hasError.value = true;
    } finally {
      loading.value = false;
    }
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
      Get.snackbar('Deleted', 'Submission deleted', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }
}

class SubmissionsScreen extends StatefulWidget {
  const SubmissionsScreen({super.key});

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(SubmissionsController());
  }

  @override
  Widget build(BuildContext context) {
    final SubmissionsController c = Get.find<SubmissionsController>();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.accent), onPressed: () => Get.back()),
        title: const Text('My Submissions', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Obx(() => TextField(
              controller: c.searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (String v) => c.searchQuery.value = v,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(CupertinoIcons.search, color: AppColors.accent),
                suffixIcon: c.searchQuery.value.isNotEmpty
                  ? IconButton(icon: const Icon(CupertinoIcons.clear, color: AppColors.accent), onPressed: c.clearSearch)
                  : null,
              ),
            )),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (c.loading.value) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }
                if (c.hasError.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(Icons.wifi_off_outlined, color: AppColors.textMuted, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Could not load submissions.\nCheck your connection and try again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: c.loadSubmissions,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (c.filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(CupertinoIcons.airplane, size: 60, color: AppColors.accent.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(c.searchQuery.value.isNotEmpty ? 'No results found' : 'No submissions yet', style: const TextStyle(color: AppColors.textMuted), textAlign: TextAlign.center),
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
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Delete this submission?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            Row(children: <Widget>[
              Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(ctx); c.deleteSubmission(sub); }, child: const Text('Yes'))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('No'))),
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
    final dynamic month = submission['month'];
    final dynamic year = submission['year'];
    String formattedDate = '—';
    if (month != null && year != null) {
      try {
        formattedDate = DateFormat('MMMM yyyy').format(DateTime(int.parse(year.toString()), int.parse(month.toString())));
      } catch (_) {
        formattedDate = '$month $year';
      }
    } else if (year != null) {
      formattedDate = year.toString();
    }
    final List<dynamic> assessments = submission['assessments'] as List<dynamic>? ?? <dynamic>[];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
            Expanded(child: Text(submission['airline'] as String? ?? '—', style: Theme.of(context).textTheme.titleMedium)),
            IconButton(icon: const Icon(CupertinoIcons.delete, color: AppColors.failText, size: 20), onPressed: onDelete),
          ]),
          Text(formattedDate, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
            const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isPassed ? AppColors.passBg : AppColors.failBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isPassed ? AppColors.passBorder : AppColors.failBorder),
              ),
              child: Text(isPassed ? 'passed' : 'failed', style: TextStyle(color: isPassed ? AppColors.passText : AppColors.failText, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ]),
          if (assessments.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            const Text('Assessment:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            ...assessments.map((dynamic a) => Text('- ${a.toString()[0].toUpperCase()}${a.toString().substring(1)}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          ],
        ],
      ),
    );
  }
}
