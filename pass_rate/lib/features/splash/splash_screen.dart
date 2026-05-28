import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home/screens/home_screen.dart';
import '../../../core/design/app_colors.dart';

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
    Future<void>.delayed(
      const Duration(seconds: 2),
      () { if (mounted) Get.off(() => const HomeScreen(), transition: Transition.fade); },
    );
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
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Image.asset(
            'assets/images/logo_with_text.png',
            width: 230,
            color: const Color(0xFF071525),
            colorBlendMode: BlendMode.dstIn,
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
