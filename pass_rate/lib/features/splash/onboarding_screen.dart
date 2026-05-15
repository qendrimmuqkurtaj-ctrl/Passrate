import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home/screens/home_screen.dart';
import '../../../core/design/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideAnim = Tween<Offset>(begin: const Offset(1.5, 0.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: CustomPaint(painter: _DotMapPainter())),
          // Fly høyere opp
          Positioned(
            bottom: 200,
            right: -20,
            child: SlideTransition(
              position: _slideAnim,
              child: Image.asset(
                'assets/images/aeroplane_image.png',
                width: 280,
                errorBuilder: (BuildContext c, Object e, StackTrace? s) =>
                    const Icon(Icons.flight, color: Colors.white24, size: 160),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 40),
                  const Text(
                    'Know Before\nYou Go!',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 38, fontWeight: FontWeight.bold, height: 1.15),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Explore real airline assessments\nand pass rates',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 16, height: 1.5),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.off(() => const HomeScreen(), transition: Transition.fadeIn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = AppColors.accent.withValues(alpha: 0.07)..strokeWidth = 1.5;
    for (double x = 0; x < size.width; x += 14) {
      for (double y = 0; y < size.height; y += 14) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }
  @override
  bool shouldRepaint(CustomPainter _) => false;
}
