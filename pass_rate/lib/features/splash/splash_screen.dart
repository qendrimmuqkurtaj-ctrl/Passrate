import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home/screens/home_screen.dart';
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
    Future<void>.delayed(const Duration(seconds: 2), () {
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
      backgroundColor: const Color(0xFF002454),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Image.asset(
            'assets/images/logo_with_text.png',
            width: 220,
            errorBuilder: (BuildContext c, Object e, StackTrace? s) => const Text(
              'PassRate',
              style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
