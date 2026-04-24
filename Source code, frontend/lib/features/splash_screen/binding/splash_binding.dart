import 'package:get/get.dart';
import '../controller/splash_controller.dart';

class SplashScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashScreenController>(
            () => SplashScreenController()
    );
  }
}
