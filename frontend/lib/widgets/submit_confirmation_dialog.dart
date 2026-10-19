import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SubmitConfirmationDialog extends StatelessWidget {
  final int totalQuestions;
  final int answeredCount;
  final int flaggedCount;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const SubmitConfirmationDialog({
    super.key,
    required this.totalQuestions,
    required this.answeredCount,
    required this.flaggedCount,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final unansweredCount = totalQuestions - answeredCount;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      backgroundColor: Colors.white,
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Icon badge
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),

              // Title
              const Text(
                'Ready to submit your exam?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Description
              Text(
                unansweredCount > 0
                    ? 'You still have $unansweredCount unanswered question${unansweredCount > 1 ? 's' : ''}. You can return to the exam or submit your current answers.'
                    : 'You have answered all questions. Are you ready to submit your exam and view your score?',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),

              // Summary Box
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    _buildStatRow('Answered', '$answeredCount of $totalQuestions', isAnswered: true),
                    const Divider(color: AppColors.borderLight, height: 16),
                    _buildStatRow(
                      'Unanswered',
                      '$unansweredCount question${unansweredCount != 1 ? 's' : ''}',
                      isWarning: unansweredCount > 0,
                    ),
                    const Divider(color: AppColors.borderLight, height: 16),
                    _buildStatRow('Flagged for review', '$flaggedCount question${flaggedCount != 1 ? 's' : ''}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Once submitted, your answers cannot be changed. Your results will be available immediately.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    child: const Text('Return to exam', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    child: const Text('Submit answers', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isWarning = false, bool isAnswered = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isWarning
                ? AppColors.danger
                : isAnswered
                    ? AppColors.primaryDark
                    : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
