import 'package:get/get.dart';

import '../../../core/common/widgets/custom_dropdown.dart';

class AssessmentController extends GetxController {
  // Airline Names Demo Data
  final RxList<DropdownItem<String>> airlineNames =
      <DropdownItem<String>>[
        const DropdownItem<String>(value: 'emirates', label: 'Emirates'),
        const DropdownItem<String>(value: 'qatar', label: 'Qatar Airways'),
        const DropdownItem<String>(value: 'lufthansa', label: 'Lufthansa'),
        const DropdownItem<String>(value: 'british', label: 'British Airways'),
        const DropdownItem<String>(value: 'singapore', label: 'Singapore Airlines'),
        const DropdownItem<String>(value: 'american', label: 'American Airlines'),
        const DropdownItem<String>(value: 'delta', label: 'Delta Air Lines'),
        const DropdownItem<String>(value: 'united', label: 'United Airlines'),
        const DropdownItem<String>(value: 'air_france', label: 'Air France'),
        const DropdownItem<String>(value: 'klm', label: 'KLM Royal Dutch Airlines'),
        const DropdownItem<String>(value: 'turkish', label: 'Turkish Airlines'),
        const DropdownItem<String>(value: 'etihad', label: 'Etihad Airways'),
        const DropdownItem<String>(value: 'cathay', label: 'Cathay Pacific'),
        const DropdownItem<String>(value: 'ana', label: 'All Nippon Airways'),
        const DropdownItem<String>(value: 'jal', label: 'Japan Airlines'),
      ].obs;

  // Assessment Items Demo Data
  final RxList<DropdownItem<String>> assessmentItems =
      <DropdownItem<String>>[
        const DropdownItem<String>(value: 'safety_briefing', label: 'Safety Briefing'),
        const DropdownItem<String>(value: 'emergency_procedures', label: 'Emergency Procedures'),
        const DropdownItem<String>(value: 'customer_service', label: 'Customer Service'),
        const DropdownItem<String>(value: 'cabin_preparation', label: 'Cabin Preparation'),
        const DropdownItem<String>(value: 'food_service', label: 'Food & Beverage Service'),
        const DropdownItem<String>(value: 'boarding_process', label: 'Boarding Process'),
        const DropdownItem<String>(value: 'communication_skills', label: 'Communication Skills'),
        const DropdownItem<String>(value: 'conflict_resolution', label: 'Conflict Resolution'),
        const DropdownItem<String>(value: 'first_aid', label: 'First Aid Knowledge'),
        const DropdownItem<String>(value: 'uniform_grooming', label: 'Uniform & Grooming'),
        const DropdownItem<String>(value: 'teamwork', label: 'Teamwork'),
        const DropdownItem<String>(value: 'punctuality', label: 'Punctuality'),
        const DropdownItem<String>(value: 'language_skills', label: 'Language Skills'),
        const DropdownItem<String>(value: 'cultural_awareness', label: 'Cultural Awareness'),
        const DropdownItem<String>(value: 'technical_knowledge', label: 'Technical Knowledge'),
      ].obs;

  RxString result = ''.obs;

  void buttonState(String status) {
    result.value = status;
  }
}
