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
  final RxBool isLoadingReviews = false.obs;

  final RxList<Map<String, dynamic>> topByPassRate = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> topBySubmission = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> airlineStats = Rxn<Map<String, dynamic>>();
  final RxList<Map<String, dynamic>> airlineReviews = <Map<String, dynamic>>[].obs;
  final RxList<String> myUpvotedIds = <String>[].obs;

  final RxString selectedAirlineName = ''.obs;
  final RxInt filterYearPassRate = DateTime.now().year.obs;
  final RxInt filterYearSubmission = DateTime.now().year.obs;
  final RxInt searchYear = DateTime.now().year.obs;

  late AssessmentController assessmentController;
  String _deviceId = '';

  @override
  void onInit() {
    super.onInit();
    assessmentController = Get.put(AssessmentController());
    refresh();
  }

  @override
  Future<void> refresh() async {
    airlineStats.value = null;
    airlineReviews.clear();
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
    airlineReviews.clear();
    try {
      airlineStats.value = await FirebaseService.getAirlineStatistics(
        airlineName: selectedAirlineName.value,
        year: searchYear.value,
      );
      if (airlineStats.value != null && selectedAirlineName.value.isNotEmpty) {
        isLoadingReviews.value = true;
        _loadReviews();
      } else {
        isLoadingReviews.value = false;
      }
    } catch (_) {
      hasSearchError.value = true;
      isLoadingReviews.value = false;
    }
    hasSearched.value = true;
    isLoadingSearch.value = false;
  }

  Future<void> _loadReviews() async {
    isLoadingReviews.value = true;
    try {
      if (_deviceId.isEmpty) _deviceId = await FirebaseService.getDeviceId();
      final List<dynamic> results = await Future.wait(<Future<dynamic>>[
        FirebaseService.getAirlineFeedback(selectedAirlineName.value),
        FirebaseService.getMyUpvotedFeedbackIds(_deviceId),
      ]);
      airlineReviews.value = results[0] as List<Map<String, dynamic>>;
      myUpvotedIds.value = results[1] as List<String>;
    } catch (_) {}
    isLoadingReviews.value = false;
  }

  Future<void> toggleUpvote(String feedbackId) async {
    if (_deviceId.isEmpty) _deviceId = await FirebaseService.getDeviceId();
    final bool wasUpvoted = myUpvotedIds.contains(feedbackId);
    if (wasUpvoted) {
      myUpvotedIds.remove(feedbackId);
    } else {
      myUpvotedIds.add(feedbackId);
    }
    final int idx = airlineReviews.indexWhere(
      (Map<String, dynamic> r) => r['id'] == feedbackId,
    );
    if (idx != -1) {
      final Map<String, dynamic> updated =
          Map<String, dynamic>.from(airlineReviews[idx]);
      updated['upvoteCount'] =
          ((updated['upvoteCount'] as int?) ?? 0) + (wasUpvoted ? -1 : 1);
      airlineReviews[idx] = updated;
    }
    airlineReviews.refresh();
    await FirebaseService.toggleFeedbackUpvote(
      feedbackId: feedbackId,
      deviceId: _deviceId,
    );
  }
}
