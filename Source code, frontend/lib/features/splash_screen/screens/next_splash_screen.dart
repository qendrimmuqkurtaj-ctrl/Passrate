import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pass_rate/core/config/app_sizes.dart';
import 'package:pass_rate/core/design/app_colors.dart';
import 'package:pass_rate/core/extensions/context_extensions.dart';
import 'package:pass_rate/core/routes/app_routes.dart';

import '../../../core/design/app_images.dart';

class NextSplashScreen extends StatefulWidget {
  const NextSplashScreen({super.key});

  @override
  State createState() => _NextSplashScreenState();
}

class _NextSplashScreenState extends State<NextSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Add a status listener to redirect after animation completes
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        Get.offAllNamed(AppRoutes.initialRoute);
      }
    });

    // Start the animation
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
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (BuildContext context, Widget? child) {
            return Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    SizedBox(height: context.screenHeight * 0.2),
                    Stack(
                      children: <Widget>[
                        Opacity(opacity: 0.5, child: Image.asset(AppImages.worldMap)),
                        Padding(
                          padding: const EdgeInsets.all(AppSizes.md),
                          child: Opacity(
                            opacity: _animation.value,
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Know Before You Go!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 30,
                                    color: AppColors.white,
                                  ),
                                ),
                                Text(
                                  'Explore real airline assessments and pass rates',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 20,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 150,
                  left: 400,
                  child: Transform.translate(
                    offset: Offset(-250 * _animation.value, -50 * _animation.value),
                    // Moves the image left
                    child: Image.asset(AppImages.aeroplaneImage, width: 600),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
