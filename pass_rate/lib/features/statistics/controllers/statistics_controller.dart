import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/firebase_service.dart';
import '../../../features/assessment/controllers/assessment_controller.dart';

class StatisticsController extends GetxController {
  final RxBool isLoadingPassRate = false.obs;
  final RxBool isLoadingSubmission = false.obs;
  final RxBool isLoadingSearch = false.obs;
  final RxBool hasSearched = false.obs;
  final RxBool hasSearchError = false.obs;
  final RxBool hasPassRateError = false.obs;
  final RxBool hasSubmissionError = false.obs;

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

  Future<void> refresh() async {
    airlineStats.value = null;
    await Future.wait(<Future<void>>[
      loadTopByPassRate(),
      loadTopBySubmission(),
    ]);
  }

  Future<void> loadTopByPassRate() async {
    isLoadingPassRate.value = true;
    hasPassRateError.value = false;
    try {
      topByPassRate.value = await FirebaseService.getTopAirlinesByPassRate(filterYearPassRate.value);
    } catch (_) {
      hasPassRateError.value = true;
    }
    isLoadingPassRate.value = false;
  }

  Future<void> loadTopBySubmission() async {
    isLoadingSubmission.value = true;
    hasSubmissionError.value = false;
    try {
      topBySubmission.value = await FirebaseService.getTopAirlinesBySubmission(filterYearSubmission.value);
    } catch (_) {
      hasSubmissionError.value = true;
    }
    isLoadingSubmission.value = false;
  }

  Future<void> searchStatistics() async {
    isLoadingSearch.value = true;
    hasSearched.value = false;
    hasSearchError.value = false;
    try {
      airlineStats.value = await FirebaseService.getAirlineStatistics(
        airlineName: selectedAirlineName.value,
        year: searchYear.value,
      );
    } catch (_) {
      hasSearchError.value = true;
    }
    hasSearched.value = true;
    isLoadingSearch.value = false;
  }
}
