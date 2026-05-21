import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../assessment/screens/submit_assessment_screen.dart';
import '../../salary/screens/salary_screen.dart';
import '../../statistics/screens/statistics_screen.dart';
import '../../submissions/screens/submissions_screen.dart';
import '../../../core/design/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _anim(int index) {
    final double start = (index * 60) / 700;
    final double end = ((index * 60) + 350) / 700;
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut),
    );
  }

  Widget _animated(int index, Widget child) {
    final Animation<double> anim = _anim(index);
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: <Widget>[
          // ── Header ─────────────────────────────────────────────────────
          Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 24,
                  right: 24,
                  bottom: 16,
                ),
                child: Center(
                  // bgPrimary wrapper hides the baked-in logo background
                  child: Container(
                    color: AppColors.bgPrimary,
                    child: Image.asset(
                      'assets/images/logo_with_text.png',
                      height: 140,
                      fit: BoxFit.contain,
                      errorBuilder: (BuildContext ctx, Object e, StackTrace? s) => const Text(
                        'PassRate',
                        style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),

          // ── Tiles ───────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 20),
                  _animated(0, _HomeTile(
                    label: 'Submit Assessment',
                    icon: Icons.touch_app_outlined,
                    iconColor: AppColors.accent,
                    isPrimary: false,
                    onTap: () => Get.to(() => const SubmitAssessmentScreen()),
                  )),
                  const SizedBox(height: 12),
                  _animated(1, _HomeTile(
                    label: 'Pass Rates',
                    icon: Icons.bar_chart_outlined,
                    iconColor: AppColors.accent,
                    isPrimary: false,
                    onTap: () => Get.to(() => const StatisticsScreen()),
                  )),
                  const SizedBox(height: 12),
                  _animated(2, _HomeTile(
                    label: 'Your Submissions',
                    icon: Icons.description_outlined,
                    iconColor: AppColors.accent,
                    isPrimary: false,
                    onTap: () => Get.to(() => const SubmissionsScreen()),
                  )),
                  const SizedBox(height: 12),
                  _animated(3, _HomeTile(
                    label: 'Pilot Salaries',
                    icon: Icons.monetization_on_outlined,
                    iconColor: AppColors.accent,
                    isPrimary: false,
                    onTap: () => Get.to(() => const SalaryScreen()),
                  )),
                  const Spacer(),
                  _animated(4, _ContactLink()),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _HomeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool isPrimary;
  final VoidCallback onTap;

  const _HomeTile({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double containerSize = isPrimary ? 48 : 42;
    final double iconSize     = isPrimary ? 24 : 20;
    final double vertPad      = isPrimary ? 22 : 16;
    final double bgAlpha      = isPrimary ? 0.12 : 0.08;
    final double borderAlpha  = isPrimary ? 0.30 : 0.20;
    final double radius       = isPrimary ? 12 : 10;

    return Material(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: iconColor.withValues(alpha: 0.1),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: vertPad),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: containerSize,
                height: containerSize,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: bgAlpha),
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: iconColor.withValues(alpha: borderAlpha)),
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: iconSize),
                ),
              ),
              const SizedBox(width: 16),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Contact link ──────────────────────────────────────────────────────────────

class _ContactLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse('https://www.instagram.com/passrate.pilot')),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.open_in_new, color: AppColors.textMuted, size: 14),
            SizedBox(width: 6),
            Text(
              'Contact & Feedback',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
