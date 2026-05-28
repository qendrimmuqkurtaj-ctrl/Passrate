import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/services/firebase_service.dart';

class FeedbackBottomSheet extends StatefulWidget {
  final String airlineId;
  final String airlineName;
  final String deviceId;
  final String? submissionId;

  const FeedbackBottomSheet({
    super.key,
    required this.airlineId,
    required this.airlineName,
    required this.deviceId,
    this.submissionId,
  });

  static Future<void> show(
    BuildContext context, {
    required String airlineId,
    required String airlineName,
    required String deviceId,
    String? submissionId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FeedbackBottomSheet(
        airlineId: airlineId,
        airlineName: airlineName,
        deviceId: deviceId,
        submissionId: submissionId,
      ),
    );
  }

  @override
  State<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<FeedbackBottomSheet> {
  String? _sentiment;
  final TextEditingController _textCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sentiment == null) return;
    setState(() => _submitting = true);
    final String? id = await FirebaseService.submitFeedback(
      airlineId: widget.airlineId,
      airlineName: widget.airlineName,
      sentiment: _sentiment!,
      deviceId: widget.deviceId,
      text: _textCtrl.text.trim().isEmpty ? null : _textCtrl.text.trim(),
      submissionId: widget.submissionId,
    );
    if (!mounted) return;
    if (id == null) {
      setState(() => _submitting = false);
      Get.snackbar(
        'Could not submit',
        'Check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.bgCard,
        colorText: AppColors.textPrimary,
      );
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('feedback_prompt_v1_shown', true);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'How was the assessment?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.airlineName,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              _SentimentButton(
                emoji: '😊',
                label: 'Good',
                selected: _sentiment == 'good',
                onTap: () => setState(() => _sentiment = 'good'),
              ),
              const SizedBox(width: 8),
              _SentimentButton(
                emoji: '😐',
                label: 'Neutral',
                selected: _sentiment == 'neutral',
                onTap: () => setState(() => _sentiment = 'neutral'),
              ),
              const SizedBox(width: 8),
              _SentimentButton(
                emoji: '😓',
                label: 'Hard',
                selected: _sentiment == 'hard',
                onTap: () => setState(() => _sentiment = 'hard'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Share more details (optional)...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              filled: true,
              fillColor: AppColors.bgPrimary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
              counterStyle: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _sentiment == null || _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SentimentButton extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SentimentButton({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.15)
                : AppColors.bgPrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: <Widget>[
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.accent : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
