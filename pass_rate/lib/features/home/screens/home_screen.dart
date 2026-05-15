import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../assessment/screens/submit_assessment_screen.dart';
import '../../statistics/screens/statistics_screen.dart';
import '../../submissions/screens/submissions_screen.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/services/firebase_service.dart';

class HomeController extends GetxController {
  final RxInt totalSubmissions = 0.obs;
  final RxBool loading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    totalSubmissions.value = await FirebaseService.getTotalSubmissionsCount();
    loading.value = false;
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController c = Get.put(HomeController());

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            padding: const EdgeInsets.only(top: 60, bottom: 28, left: 24, right: 24),
            child: Center(
              child: Image.asset(
                'assets/images/logo_with_text.png',
                height: 300,
                fit: BoxFit.contain,
                color: const Color(0xFF071525),
                colorBlendMode: BlendMode.dstIn,
                errorBuilder: (BuildContext ctx, Object e, StackTrace? s) => const Text(
                  'PassRate',
                  style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Obx(() => c.loading.value
            ? const SizedBox(height: 48)
            : Column(
                children: <Widget>[
                  Text(
                    '${c.totalSubmissions.value}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'pilot reports',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ],
              ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: <Widget>[
                  _HomeTile(
                    label: 'Submit Assessment',
                    icon: Icons.touch_app_outlined,
                    onTap: () => Get.to(() => const SubmitAssessmentScreen()),
                  ),
                  const SizedBox(height: 16),
                  _HomeTile(
                    label: 'Statistics',
                    icon: Icons.bar_chart_outlined,
                    onTap: () => Get.to(() => const StatisticsScreen()),
                  ),
                  const SizedBox(height: 16),
                  _HomeTile(
                    label: 'Your Submissions',
                    icon: Icons.description_outlined,
                    onTap: () => Get.to(() => const SubmissionsScreen()),
                  ),
                  const SizedBox(height: 16),
                  _HomeTile(
                    label: 'Contact & Feedback',
                    icon: Icons.camera_alt_outlined,
                    onTap: () => launchUrl(Uri.parse('https://www.instagram.com/passrate.pilot')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeTile({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.accent.withValues(alpha: 0.1),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: AppColors.accent, size: 28),
              const SizedBox(width: 16),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
