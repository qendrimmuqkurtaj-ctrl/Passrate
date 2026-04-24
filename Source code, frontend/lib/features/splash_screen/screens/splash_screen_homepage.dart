/*
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:pass_rate/core/design/app_colors.dart';
import 'package:pass_rate/core/routes/app_routes.dart';
import 'package:pass_rate/core/utils/logger_utils.dart';

import '../../../core/design/app_images.dart';

class SplashScreenHomepage extends StatefulWidget {
  const SplashScreenHomepage({super.key});

  @override
  State createState() => _SplashScreenHomepageState();
}

class _SplashScreenHomepageState extends State<SplashScreenHomepage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(duration: const Duration(seconds: 1), vsync: this);

    // Define the animation (from 0 to 1)
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // Add a status listener to redirect after animation completes
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        Get.offAllNamed(AppRoutes.splashScreen);
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
    LoggerUtils.debug(_animation.value);
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (BuildContext context, Widget? child) {
            return Row(
              // alignment: Alignment.center,
              children: <Widget>[
                Transform.translate(
                  offset: Offset(-50 * (_animation.value - 1), 0),

                  child: Image.asset(AppImages.logoImage, width: 200),
                ),
                Transform.translate(
                  offset: Offset(50 * (_animation.value - 1), 0),
                  // Slide effect
                  child: Image.asset(AppImages.logoTextImage, width: 200),
                  // child: Text('PassRate',style: context.textTheme.headlineLarge,),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
*/
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pass_rate/core/design/app_colors.dart';
import 'package:pass_rate/core/extensions/context_extensions.dart';
import 'package:pass_rate/core/routes/app_routes.dart';

import '../../../core/design/app_images.dart';

class SplashScreenHomepage extends StatefulWidget {
  const SplashScreenHomepage({super.key});

  @override
  State createState() => _SplashScreenHomepageState();
}

class _SplashScreenHomepageState extends State<SplashScreenHomepage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);

    // Define the animation (from 0 to 1)
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Add a status listener to redirect after animation completes
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        Get.offAllNamed(AppRoutes.nextSplashScreen);
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
              alignment: Alignment.center,
              children: <Widget>[
                // First Image: Static in the center initially, moves left
                Positioned(
                  left: 50,
                  child: Opacity(
                    opacity: 1, // Decreases opacity as it moves
                    child: Transform.translate(
                      offset: Offset(-50 * _animation.value, 0),
                      // Moves the image left
                      child: Image.asset(AppImages.logoImage, width: 200),
                    ),
                  ),
                ),

                // Second Image: Initially hidden, appears after the first image moves left
                Positioned(
                  right: 50,
                  child: Opacity(
                    // opacity: _animation.value > 0.5 ? (_animation.value - 0.5) * 2 : 0,
                    opacity: ((_animation.value - 0.3) * 2).clamp(0.0, 1.0),
                    // Increases opacity as it appears
                    child: Transform.translate(
                      offset: Offset(-25 * (1 - _animation.value), 0),
                      // Moves the image right
                      // child: Image.asset(AppImages.logoTextImage, width: 200),
                      child: Text(
                        'PassRate',
                        // context.screenWidth.toString(),
                        style: TextStyle(
                          fontSize:
                              context.screenWidth < 300
                                  ? 32
                                  : context.screenWidth < 400
                                  ? 38
                                  : context.screenWidth < 600
                                  ? 40
                                  : context.screenWidth < 1024
                                  ? 44
                                  : 50,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
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
