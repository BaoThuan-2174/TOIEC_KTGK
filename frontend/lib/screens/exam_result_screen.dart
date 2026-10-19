import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/reading_room_header.dart';
import 'exam_selection_screen.dart';

class ExamResultScreen extends StatefulWidget {
  final int submissionId;
  final ExamDetail exam;
  final Map<int, int> userAnswers;
  final double score;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final int timeSpentSeconds;

  const ExamResultScreen({
    super.key,
    required this.submissionId,
    required this.exam,
    required this.userAnswers,
    required this.score,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.timeSpentSeconds,
  });

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  final ApiService _apiService = ApiService();
  late Future<SubmissionReview> _reviewFuture;
  int _selectedDetailIndex = 0;
  String _activeFilter = 'All'; // 'All', 'Incorrect', 'Skipped'

  @override
  void initState() {
    super.initState();
    _reviewFuture = _apiService.getSubmissionReview(
      widget.submissionId,
      widget.exam,
      widget.userAnswers,
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m minutes $s seconds';
  }

  void _returnHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ExamSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ReadingRoomHeader(
        showNav: true,
        isPracticeActive: false,
        onPracticeExamsTap: _returnHome,
        onMyResultsTap: () {},
      ),
      body: FutureBuilder<SubmissionReview>(
        future: _reviewFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final review = snapshot.data;
          if (review == null) {
            return const Center(child: Text('Không thể tải kết quả bài thi.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Hero & Score summary
                    _buildResultHero(review),

                    const SizedBox(height: 28),

                    // Stats Cards Row
                    _buildStatsCardsRow(review),

                    const SizedBox(height: 36),

                    // Section Title & Filter Tabs
                    _buildReviewFilterHeader(review),

                    const SizedBox(height: 20),

                    // Review Details Workspace
                    _buildReviewWorkspace(review),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultHero(SubmissionReview review) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'EXAM COMPLETED · 17 OCT 2026',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'A good step forward, Jamie.',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'TOEIC Reading • ${review.examTitle} · Completed in ${_formatTime(widget.timeSpentSeconds)}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),

        // Return to home button
        OutlinedButton.icon(
          onPressed: _returnHome,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Return to home', style: TextStyle(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCardsRow(SubmissionReview review) {
    final accuracy = review.totalQuestions > 0 ? (review.correctCount / review.totalQuestions * 100).round() : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // Dark score card
            Container(
              width: 220,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR READING SCORE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${review.score.round()}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '/ 100',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Practice score · Not an official TOEIC scaled score',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Correct
            _buildStatCard(
              title: 'Correct answers',
              value: '${review.correctCount}',
              subtext: '${(review.correctCount / review.totalQuestions * 100).round()}% of all questions',
              isSuccess: true,
            ),

            // Incorrect
            _buildStatCard(
              title: 'Incorrect answers',
              value: '${review.wrongCount}',
              subtext: '${(review.wrongCount / review.totalQuestions * 100).round()}% of all questions',
            ),

            // Skipped
            _buildStatCard(
              title: 'Skipped',
              value: '${review.skippedCount}',
              subtext: '${(review.skippedCount / review.totalQuestions * 100).round()}% of all questions',
            ),

            // Accuracy
            _buildStatCard(
              title: 'Accuracy',
              value: '$accuracy%',
              subtext: '${review.correctCount} correct ÷ ${review.totalQuestions} questions',
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtext,
    bool isSuccess = false,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSuccess ? FontWeight.w600 : FontWeight.w400,
              color: isSuccess ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewFilterHeader(SubmissionReview review) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Learn from every answer',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        Row(
          children: [
            _filterTab('All', 'All · ${review.totalQuestions}'),
            const SizedBox(width: 8),
            _filterTab('Incorrect', 'Incorrect · ${review.wrongCount}'),
            const SizedBox(width: 8),
            _filterTab('Skipped', 'Skipped · ${review.skippedCount}'),
          ],
        ),
      ],
    );
  }

  Widget _filterTab(String key, String label) {
    final isSelected = _activeFilter == key;
    return InkWell(
      onTap: () {
        setState(() {
          _activeFilter = key;
          _selectedDetailIndex = 0;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.border : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewWorkspace(SubmissionReview review) {
    // Filter questions
    final filteredDetails = review.details.where((d) {
      if (_activeFilter == 'Incorrect') return !d.isCorrect && d.selectedOptionId != null;
      if (_activeFilter == 'Skipped') return d.selectedOptionId == null;
      return true;
    }).toList();

    if (filteredDetails.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: const Text('Không có câu hỏi nào trong mục này.'),
      );
    }

    if (_selectedDetailIndex >= filteredDetails.length) {
      _selectedDetailIndex = 0;
    }

    final currentDetail = filteredDetails[_selectedDetailIndex];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Questions List
        Container(
          width: 280,
          height: 600,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'PART ${currentDetail.partNumber == 1 ? '5' : (currentDetail.partNumber == 2 ? '6' : '7')} · READING',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              Expanded(
                child: ListView.separated(
                  itemCount: filteredDetails.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (context, idx) {
                    final item = filteredDetails[idx];
                    final isSelected = idx == _selectedDetailIndex;
                    final isSkipped = item.selectedOptionId == null;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDetailIndex = idx;
                        });
                      },
                      child: Container(
                        color: isSelected ? AppColors.surfaceSubtle : Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Question ${item.questionNumber}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSkipped
                                    ? AppColors.background
                                    : item.isCorrect
                                        ? AppColors.surfaceSubtle
                                        : AppColors.dangerBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isSkipped
                                    ? '— Skipped'
                                    : item.isCorrect
                                        ? '✓ Correct'
                                        : '✕ Incorrect',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSkipped
                                      ? AppColors.textSecondary
                                      : item.isCorrect
                                          ? AppColors.primary
                                          : AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // Right Question Detail Review
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'QUESTION ${currentDetail.questionNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: currentDetail.selectedOptionId == null
                            ? AppColors.background
                            : currentDetail.isCorrect
                                ? AppColors.surfaceSubtle
                                : AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentDetail.selectedOptionId == null
                            ? '• Skipped'
                            : currentDetail.isCorrect
                                ? '• Correct'
                                : '• Incorrect',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: currentDetail.selectedOptionId == null
                              ? AppColors.textSecondary
                              : currentDetail.isCorrect
                                  ? AppColors.primary
                                  : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Question Content
                Text(
                  currentDetail.questionContent,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // Option Feedback List
                ...currentDetail.options.map((opt) {
                  final isChosen = currentDetail.selectedOptionId == opt.id;
                  final isActualCorrect = currentDetail.correctOptionId == opt.id;

                  Color border = AppColors.border;
                  Color bg = Colors.white;
                  Widget? iconTrailing;

                  if (isActualCorrect) {
                    border = AppColors.borderActive;
                    bg = AppColors.surfaceSubtle;
                    iconTrailing = const Icon(Icons.check, color: AppColors.primary, size: 18);
                  } else if (isChosen && !isActualCorrect) {
                    border = AppColors.danger;
                    bg = AppColors.dangerBg;
                    iconTrailing = const Icon(Icons.close, color: AppColors.danger, size: 18);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: border, width: isActualCorrect || (isChosen && !isActualCorrect) ? 1.5 : 1.0),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isActualCorrect
                                ? AppColors.primary
                                : (isChosen ? AppColors.danger : Colors.white),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActualCorrect
                                  ? AppColors.primary
                                  : (isChosen ? AppColors.danger : AppColors.textMuted),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            opt.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isActualCorrect || isChosen ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            opt.content,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isActualCorrect || isChosen ? FontWeight.w600 : FontWeight.w400,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        ?iconTrailing,
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 20),

                // Explanation Box (Matching Figma!)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Correct answer: ',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          Text(
                            currentDetail.options.firstWhere((o) => o.id == currentDetail.correctOptionId, orElse: () => currentDetail.options.first).label,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                          const SizedBox(width: 24),
                          const Text(
                            'Your answer: ',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          Text(
                            currentDetail.selectedOptionId != null
                                ? currentDetail.options.firstWhere((o) => o.id == currentDetail.selectedOptionId).label
                                : 'Skipped',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: currentDetail.isCorrect ? AppColors.primary : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.borderLight),
                      const SizedBox(height: 12),
                      Text(
                        currentDetail.explanation ?? 'No explanation available for this question.',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Skill: Identifying a stated reason',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Review Navigation Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (currentDetail.passageText != null)
                      TextButton.icon(
                        onPressed: () {
                          // Show passage modal
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Passage Reference'),
                              content: SingleChildScrollView(
                                child: SelectableText(currentDetail.passageText!),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.menu_book_outlined, size: 16, color: AppColors.primary),
                        label: const Text(
                          'View related passages ↗',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _selectedDetailIndex > 0
                              ? () => setState(() => _selectedDetailIndex--)
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Previous'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _selectedDetailIndex < filteredDetails.length - 1
                              ? () => setState(() => _selectedDetailIndex++)
                              : null,
                          icon: const Text('Next question'),
                          label: const Icon(Icons.arrow_forward, size: 16),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
