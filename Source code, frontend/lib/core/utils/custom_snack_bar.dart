import 'package:flutter/material.dart';

import '../../main.dart';


class ToastManager {
  /// Add this in the main.dart ======> [final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();]

  static OverlayEntry? _currentToast;

  static void show({
    required String message,
    Widget icon = const Icon(Icons.error_outline),
    Color backgroundColor = const Color(0xFF222222),
    Color iconColor = Colors.white,
    Color textColor = Colors.white,
    double borderRadius = 12.0,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    Duration duration = const Duration(seconds: 3),
    Duration animationDuration = const Duration(milliseconds: 300),
    Curve animationCurve = Curves.easeInOut,
  }) {
    final OverlayState? overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) {
      return;
    }

    _currentToast?.remove();

    _currentToast = OverlayEntry(
      builder:
          (BuildContext context) => Positioned(
        bottom: 50,
        left: 20,
        right: 20,
        child: SafeArea(
          child: ToastAnimation(
            duration: animationDuration,
            curve: animationCurve,
            child: CustomToast(
              icon: icon,
              message: message,
              backgroundColor: backgroundColor,
              iconColor: iconColor,
              textColor: textColor,
              borderRadius: borderRadius,
              padding: padding,
            ),
          ),
        ),
      ),
    );

    overlayState.insert(_currentToast!);

    Future.delayed(duration + animationDuration, () {
      _currentToast?.remove();
      _currentToast = null;
    });
  }
}

class ToastAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const ToastAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  State<ToastAnimation> createState() => _ToastAnimationState();
}

class _ToastAnimationState extends State<ToastAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(_fadeAnimation);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.reverse(); // Fade out when disposed
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

class CustomToast extends StatelessWidget {
  final Widget icon;
  final String message;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final double borderRadius;
  final EdgeInsets padding;

  const CustomToast({
    super.key,
    required this.icon,
    required this.message,
    this.backgroundColor = const Color(0xFF222222),
    this.iconColor = Colors.white,
    this.textColor = Colors.white,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            icon,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*ToastManager.show(
message: "Sohan is the best Developper ",
icon: Icons.wifi_off,
// backgroundColor: Colors.red.shade700,
backgroundColor: Colors.black,
animationDuration: const Duration(milliseconds: 500),
animationCurve: Curves.easeInSine,
duration: const Duration(seconds: 1),
);*/
