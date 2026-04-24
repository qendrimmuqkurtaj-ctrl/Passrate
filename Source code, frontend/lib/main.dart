import 'package:flutter/material.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:pass_rate/core/routes/app_routes.dart';
import 'core/design/app_theme.dart';
import 'core/routes/app_navigation.dart';
import 'features/home/screens/home_screen.dart';
import 'features/splash_screen/screens/next_splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: AppTheme.defaultThemeData,
      navigatorKey: navigatorKey,
      initialRoute: AppRoutes.splashScreen,
      getPages: AppNavigation.routes,

      initialBinding: ControllerBinder(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ControllerBinder extends Bindings {
  /// GLOBAL controller ====>
  @override
  void dependencies() {}
}
