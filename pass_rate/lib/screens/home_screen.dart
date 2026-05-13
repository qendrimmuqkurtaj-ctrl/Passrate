import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'submit_screen.dart';
import 'statistics_screen.dart';
import 'submissions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF0D2B5E),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            ),
            padding: const EdgeInsets.only(top: 60, bottom: 28, left: 24, right: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', height: 44,
                  errorBuilder: (c, e, s) => Row(children: [
                    const Icon(Icons.flight, color: Color(0xFF1A9EF5), size: 32),
                    const SizedBox(width: 8),
                    const Text('PassRate', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ])),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Menu buttons
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _MenuButton(
                    icon: Icons.touch_app_outlined,
                    label: 'Submit Assessment',
                    onTap: () => Get.to(() => const SubmitScreen()),
                  ),
                  const SizedBox(height: 14),
                  _MenuButton(
                    icon: Icons.bar_chart_outlined,
                    label: 'Statistics',
                    onTap: () => Get.to(() => const StatisticsScreen()),
                  ),
                  const SizedBox(height: 14),
                  _MenuButton(
                    icon: Icons.description_outlined,
                    label: 'Your Submissions',
                    onTap: () => Get.to(() => const SubmissionsScreen()),
                  ),
                ],
              ),
            ),
          ),
          // Help Us Grow button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: GestureDetector(
              onTap: () => Get.to(() => const SupportScreen()),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1D9E75), width: 1.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/icons/support.png', width: 24,
                      errorBuilder: (c, e, s) => const Icon(Icons.favorite_border, color: Color(0xFF1D9E75), size: 22)),
                    const SizedBox(width: 10),
                    const Text('Help Us Grow!', style: TextStyle(color: Color(0xFF1D9E75), fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF0D2B5E).withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0D2B5E), size: 26),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(color: Color(0xFF0D2B5E), fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
