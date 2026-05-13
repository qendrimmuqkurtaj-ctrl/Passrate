import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2B5E),
      body: Stack(
        children: [
          // Dotted world map background
          Positioned.fill(
            child: CustomPaint(painter: _DotMapPainter()),
          ),
          // Airplane image
          Positioned(
            bottom: 80,
            right: -40,
            child: Image.asset('assets/images/airplane.png', width: 320,
              errorBuilder: (c, e, s) => const Icon(Icons.flight, color: Colors.white38, size: 180)),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Text('Know Before\nYou Go!',
                    style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold, height: 1.15)),
                  const SizedBox(height: 16),
                  Text('Explore real airline assessments\nand pass rates',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, height: 1.5)),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.off(() => const HomeScreen(), transition: Transition.fadeIn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A9EF5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),
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
    final paint = Paint()..color = Colors.white.withOpacity(0.06)..strokeWidth = 1.5;
    for (double x = 0; x < size.width; x += 14) {
      for (double y = 0; y < size.height; y += 14) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
