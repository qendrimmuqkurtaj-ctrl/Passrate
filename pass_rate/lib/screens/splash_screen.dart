import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), () {
      Get.off(() => const OnboardingScreen(), transition: Transition.fade);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2B5E),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 200, errorBuilder: (c, e, s) =>
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 60, height: 60, decoration: BoxDecoration(color: const Color(0xFF1A9EF5), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.flight, color: Colors.white, size: 36)),
                  const SizedBox(width: 12),
                  const Text('PassRate', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
