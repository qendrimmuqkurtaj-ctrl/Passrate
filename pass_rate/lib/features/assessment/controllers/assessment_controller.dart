import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/firebase_service.dart';

class AssessmentController extends GetxController {
  final RxBool loadingAirlines = true.obs;
  final RxBool loadingTasks = true.obs;
  final RxBool submitting = false.obs;
  final RxBool loadingAirlinesError = false.obs;
  final RxBool loadingTasksError = false.obs;

  final RxList<Map<String, dynamic>> airlines = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> tasks = <Map<String, dynamic>>[].obs;
  final RxList<String> selectedTaskIds = <String>[].obs;
  final RxList<String> selectedTaskNames = <String>[].obs;

  Rx<Map<String, dynamic>?> selectedAirline = Rx<Map<String, dynamic>?>(null);
  final RxInt selectedYear = DateTime.now().year.obs;
  final RxInt selectedMonth = DateTime.now().month.obs;
  final RxnBool passed = RxnBool();

  final TextEditingController dateController = TextEditingController();

  // Progress tracking
  RxDouble get completionPercentage {
    int steps = 0;
    if (selectedAirline.value != null) steps++;
    if (dateController.text.isNotEmpty) steps++;
    if (selectedTaskIds.isNotEmpty) steps++;
    if (passed.value != null) steps++;
    return RxDouble(steps / 4);
  }

  bool get allCompleted =>
      selectedAirline.value != null &&
      dateController.text.isNotEmpty &&
      selectedTaskIds.isNotEmpty &&
      passed.value != null;

  @override
  void onInit() {
    super.onInit();
    loadAirlines();
    loadTasks();
  }

  @override
  void onClose() {
    dateController.dispose();
    super.onClose();
  }

  Future<void> loadAirlines() async {
    loadingAirlines.value = true;
    loadingAirlinesError.value = false;
    try {
      airlines.value = await FirebaseService.getAirlines();
    } catch (_) {
      loadingAirlinesError.value = true;
    } finally {
      loadingAirlines.value = false;
    }
  }

  Future<void> loadTasks() async {
    loadingTasks.value = true;
    loadingTasksError.value = false;
    try {
      tasks.value = await FirebaseService.getTasks();
    } catch (_) {
      loadingTasksError.value = true;
    } finally {
      loadingTasks.value = false;
    }
  }

  void selectAirline(Map<String, dynamic> airline) {
    selectedAirline.value = airline;
    update();
  }

  void toggleTask(Map<String, dynamic> task) {
    final String id = task['id'] as String;
    final String name = task['name'] as String;
    if (selectedTaskIds.contains(id)) {
      selectedTaskIds.remove(id);
      selectedTaskNames.remove(name);
    } else {
      selectedTaskIds.add(id);
      selectedTaskNames.add(name);
    }
    update();
  }

  void setPassed(bool value) {
    passed.value = value;
    update();
  }

  void onDateSelected(DateTime date) {
    selectedYear.value = date.year;
    selectedMonth.value = date.month;
    dateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    update();
  }

  Future<Map<String, dynamic>?> submitAssessment() async {
    if (!allCompleted) return null;
    submitting.value = true;
    try {
      final String deviceId = await FirebaseService.getDeviceId();
      final Map<String, dynamic> result = await FirebaseService.submitAssessment(
        airlineId: selectedAirline.value!['id'] as String,
        airlineName: selectedAirline.value!['name'] as String,
        year: selectedYear.value,
        month: selectedMonth.value,
        taskIds: List<String>.from(selectedTaskIds),
        taskNames: List<String>.from(selectedTaskNames),
        passed: passed.value!,
        deviceId: deviceId,
      );
      return result;
    } catch (_) {
      Get.snackbar(
        'Error',
        'Could not submit. Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      submitting.value = false;
    }
  }

  void reset() {
    selectedAirline.value = null;
    selectedTaskIds.clear();
    selectedTaskNames.clear();
    passed.value = null;
    dateController.clear();
    update();
  }
}
