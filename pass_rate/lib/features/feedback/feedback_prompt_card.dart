import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/services/firebase_service.dart';
import 'feedback_sheet.dart';

class FeedbackPromptCard extends StatefulWidget {
  const FeedbackPromptCard({super.key});

  @override
  State<FeedbackPromptCard> createState() => _FeedbackPromptCardState();
}

class _FeedbackPromptCardState extends State<FeedbackPromptCard> {
  bool _visible = false;
  Map<String, dynamic>? _lastSubmission;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('feedback_prompt_v1_shown') == true) return;
    final String deviceId = await FirebaseService.getDeviceId();
    final List<Map<String, dynamic>> subs =
        await FirebaseService.getMySubmissions(deviceId);
    if (!mounted || subs.isEmpty) return;
    setState(() {
      _lastSubmission = subs.first;
      _visible = true;
    });
  }

  Future<void> _dismiss() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('feedback_prompt_v1_shown', true);
    if (mounted) setState(() => _visible = false);
  }

  Future<void> _shareFeedback() async {
    if (_lastSubmission == null) {
      await _dismiss();
      return;
    }
    await _dismiss();
    if (!mounted) return;
    final String deviceId = await FirebaseService.getDeviceId();
    if (!mounted) return;
    await FeedbackBottomSheet.show(
      context,
      airlineId: _lastSubmission!['airlineId'] as String? ?? '',
      airlineName: _lastSubmission!['airline'] as String? ?? '',
      deviceId: deviceId,
      submissionId: _lastSubmission!['id'] as String?,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final String airlineName =
        _lastSubmission?['airline'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('💬', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Share your experience',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (airlineName.isNotEmpty)
                        Text(
                          airlineName,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _dismiss,
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _dismiss,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Not now'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _shareFeedback,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Give Feedback'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
