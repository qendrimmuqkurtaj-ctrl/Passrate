import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/firebase_service.dart';
import '../../../features/assessment/controllers/assessment_controller.dart';

class StatisticsController extends GetxController {
  final RxBool isLoadingPassRate = false.obs;
  final RxBool isLoadingSubmission = false.obs;
  final RxBool isLoadingSearch = false.obs;

  final RxList<Map<String, dynamic>> topByPassRate = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> topBySubmission = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> airlineStats = Rxn<Map<String, dynamic>>();

  final RxString selectedAirlineName = ''.obs;
  final RxInt filterYearPassRate = DateTime.now().year.obs;
  final RxInt filterYearSubmission = DateTime.now().year.obs;
  final RxInt searchYear = DateTime.now().year.obs;

  late AssessmentController assessmentController;

  @override
  void onInit() {
    super.onInit();
    assessmentController = Get.put(AssessmentController());
    refresh();
  }

  // Called every time screen is shown
  @override
  void onReady() {
    super.onReady();
    refresh();
  }

  Future<void> refresh() async {
    airlineStats.value = null;
    await Future.wait(<Future<void>>[
      loadTopByPassRate(),
      loadTopBySubmission(),
    ]);
  }

  Future<void> loadTopByPassRate() async {
    isLoadingPassRate.value = true;
    topByPassRate.value = await FirebaseService.getTopAirlinesByPassRate(filterYearPassRate.value);
    isLoadingPassRate.value = false;
  }

  Future<void> loadTopBySubmission() async {
    isLoadingSubmission.value = true;
    topBySubmission.value = await FirebaseService.getTopAirlinesBySubmission(filterYearSubmission.value);
    isLoadingSubmission.value = false;
  }

  Future<void> searchStatistics() async {
    if (selectedAirlineName.value.isEmpty) {
      Get.snackbar('Error', 'Please select an airline', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    isLoadingSearch.value = true;
    airlineStats.value = await FirebaseService.getAirlineStatistics(
      airlineName: selectedAirlineName.value,
      year: searchYear.value,
    );
    isLoadingSearch.value = false;
  }
}
