import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../theme/app_colors.dart';

class QuestionPalette extends StatefulWidget {
  final ExamDetail exam;
  final int currentQuestionIndex;
  final Map<int, int> selectedAnswers; // questionId -> optionId
  final Set<int> flaggedQuestionIds;
  final ValueChanged<int> onQuestionSelected;

  const QuestionPalette({
    super.key,
    required this.exam,
    required this.currentQuestionIndex,
    required this.selectedAnswers,
    required this.flaggedQuestionIds,
    required this.onQuestionSelected,
  });

  @override
  State<QuestionPalette> createState() => _QuestionPaletteState();
}

class _QuestionPaletteState extends State<QuestionPalette> {
  // Track expanded state for each part
  final Map<int, bool> _expandedParts = {
    1: true, // Part 5
    2: true, // Part 6
    3: true, // Part 7
  };

  @override
  Widget build(BuildContext context) {
    final allQuestions = widget.exam.getAllQuestions();
    final total = allQuestions.length;
    final answered = widget.selectedAnswers.length;
    final progress = total > 0 ? answered / total : 0.0;

    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.borderLight, width: 1.0),
        ),
      ),
      child: Column(
        children: [
          // Top Progress Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$answered / $total',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.borderLight),

          // Scrollable Parts Accordion
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildPartSection(1, 'Part 5', '101–130', allQuestions),
                const SizedBox(height: 12),
                _buildPartSection(2, 'Part 6', '131–146', allQuestions),
                const SizedBox(height: 12),
                _buildPartSection(3, 'Part 7', '147–200', allQuestions),
              ],
            ),
          ),

          // Legend Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderLight, width: 1.0)),
              color: AppColors.background,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _legendItem(AppColors.surfaceSubtle, AppColors.border, 'Answered'),
                    const SizedBox(width: 14),
                    _legendItem(AppColors.surface, AppColors.borderLight, 'Unanswered'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _legendItem(AppColors.primaryDark, AppColors.primaryDark, 'Current', textColor: Colors.white),
                    const SizedBox(width: 14),
                    Row(
                      children: const [
                        Icon(Icons.flag, size: 14, color: AppColors.flagged),
                        SizedBox(width: 4),
                        Text(
                          'Flagged',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartSection(int partNumber, String partTitle, String rangeStr, List<ExamQuestion> allQuestions) {
    final isExpanded = _expandedParts[partNumber] ?? true;

    // Filter questions belonging to this part
    List<ExamQuestion> partQuestions = [];
    for (var group in widget.exam.questionGroups) {
      if (group.partType == partNumber) {
        partQuestions.addAll(group.questions);
      }
    }
    partQuestions.sort((a, b) => a.questionNumber.compareTo(b.questionNumber));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Accordion header
        InkWell(
          onTap: () {
            setState(() {
              _expandedParts[partNumber] = !isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  partTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      rangeStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Grid of Numbers
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: partQuestions.map((q) {
                final globalIdx = allQuestions.indexOf(q);
                final isCurrent = globalIdx == widget.currentQuestionIndex;
                final isAnswered = widget.selectedAnswers.containsKey(q.id);
                final isFlagged = widget.flaggedQuestionIds.contains(q.id);

                return _buildQuestionBadge(
                  questionNumber: q.questionNumber,
                  isCurrent: isCurrent,
                  isAnswered: isAnswered,
                  isFlagged: isFlagged,
                  onTap: () => widget.onQuestionSelected(globalIdx),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionBadge({
    required int questionNumber,
    required bool isCurrent,
    required bool isAnswered,
    required bool isFlagged,
    required VoidCallback onTap,
  }) {
    Color bg = AppColors.surface;
    Color border = AppColors.borderLight;
    Color textColor = AppColors.textSecondary;

    if (isCurrent) {
      bg = AppColors.primaryDark;
      border = AppColors.primaryDark;
      textColor = Colors.white;
    } else if (isAnswered) {
      bg = AppColors.surfaceSubtle;
      border = AppColors.border;
      textColor = AppColors.textPrimary;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isFlagged && !isCurrent ? AppColors.flagged : border,
                width: isFlagged && !isCurrent ? 1.5 : 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$questionNumber',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          if (isFlagged)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.flagged,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendItem(Color fill, Color border, String label, {Color? textColor}) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
