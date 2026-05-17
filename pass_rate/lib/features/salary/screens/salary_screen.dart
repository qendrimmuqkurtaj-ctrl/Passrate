import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/services/firebase_service.dart';
import 'submit_salary_screen.dart';

class SalaryController extends GetxController {
  final RxBool loading = true.obs;
  final RxBool hasSubmitted = false.obs;
  final RxBool isOutdated = false.obs;
  final RxList<Map<String, dynamic>> salaries = <Map<String, dynamic>>[].obs;
  String? existingDocId;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    loading.value = true;
    final String deviceId = await FirebaseService.getDeviceId();
    final Map<String, dynamic>? submission = await FirebaseService.getDeviceSalarySubmission(deviceId);

    hasSubmitted.value = submission != null;
    existingDocId = submission?['id'] as String?;

    if (submission != null) {
      final DateTime? createdAt = submission['createdAt'] as DateTime?;
      isOutdated.value = createdAt == null || DateTime.now().difference(createdAt).inDays > 365;
      if (!isOutdated.value) {
        salaries.value = await FirebaseService.getAllSalaries();
      }
    }

    loading.value = false;
  }

  Future<void> reload() => _load();
}

class SalaryScreen extends StatelessWidget {
  const SalaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SalaryController c = Get.put(SalaryController());

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.accent),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Pilot Salaries',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (c.loading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        if (!c.hasSubmitted.value) {
          return _buildLockedView(
            c,
            message: 'Submit your salary to unlock all pilot salaries',
            buttonLabel: 'Submit Salary',
          );
        }
        if (c.isOutdated.value) {
          return _buildLockedView(
            c,
            message: 'Your salary data is outdated. Please update to continue viewing salaries.',
            buttonLabel: 'Update Salary',
          );
        }
        return _buildSalaryList(c);
      }),
    );
  }

  Widget _buildLockedView(SalaryController c, {required String message, required String buttonLabel}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 64),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await Get.to(() => SubmitSalaryScreen(existingDocId: c.existingDocId));
                  c.reload();
                },
                child: Text(buttonLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryList(SalaryController c) {
    return Column(
      children: <Widget>[
        Expanded(
          child: c.salaries.isEmpty
            ? const Center(child: Text('No salaries submitted yet.', style: TextStyle(color: AppColors.textMuted)))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: c.salaries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int i) => _SalaryCard(salary: c.salaries[i]),
              ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await Get.to(() => SubmitSalaryScreen(existingDocId: c.existingDocId));
                c.reload();
              },
              child: const Text('Update Salary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SalaryCard extends StatelessWidget {
  final Map<String, dynamic> salary;
  const _SalaryCard({required this.salary});

  @override
  Widget build(BuildContext context) {
    final String airline = salary['airline'] as String? ?? '-';
    final String rank = salary['rank'] as String? ?? '-';
    final int seniority = (salary['seniorityYears'] as num?)?.toInt() ?? 0;
    final String aircraft = salary['aircraftType'] as String? ?? '-';
    final String contract = salary['contractType'] as String? ?? '-';
    final double baseSalary = (salary['baseSalary'] as num?)?.toDouble() ?? 0;
    final double perDiem = (salary['perDiem'] as num?)?.toDouble() ?? 0;
    final String country = salary['country'] as String? ?? '-';
    final String currency = salary['currency'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  airline,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(rank, style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Row('Aircraft', aircraft),
          _Row('Contract', contract),
          _Row('Seniority', '$seniority yr'),
          _Row('Country', country),
          const SizedBox(height: 8),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Base Salary', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      '$currency ${_fmt(baseSalary)}',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Per Diem', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      '$currency ${_fmt(perDiem)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => v.truncate().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (Match m) => ',',
  );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: <Widget>[
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
        Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    ),
  );
}
