import 'dart:async';
import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/question_palette.dart';
import '../widgets/submit_confirmation_dialog.dart';
import 'exam_result_screen.dart';

class ExamWorkspaceScreen extends StatefulWidget {
  final int examId;
  final String examTitle;
  final int durationMinutes;

  const ExamWorkspaceScreen({
    super.key,
    required this.examId,
    required this.examTitle,
    this.durationMinutes = 75,
  });

  @override
  State<ExamWorkspaceScreen> createState() => _ExamWorkspaceScreenState();
}

class _ExamWorkspaceScreenState extends State<ExamWorkspaceScreen> {
  final ApiService _apiService = ApiService();
  ExamDetail? _exam;
  bool _isLoading = true;

  // Test state
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // questionId -> optionId
  final Set<int> _flaggedQuestionIds = {}; // set of questionId

  // Timer
  late int _remainingSeconds;
  Timer? _timer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationMinutes * 60;
    _loadExam();
  }

  void _loadExam() async {
    final exam = await _apiService.getExamForStudent(widget.examId);
    if (mounted) {
      setState(() {
        _exam = exam;
        _isLoading = false;
        // Start 75-min countdown timer
        _startTimer();
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _autoSubmitOnTimeUp();
      }
    });
  }

  void _autoSubmitOnTimeUp() {
    if (_isSubmitting) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thời gian làm bài đã hết! Hệ thống đang tự động nộp bài...'),
        backgroundColor: AppColors.danger,
      ),
    );
    _performSubmit();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _selectOption(int questionId, int optionId) {
    setState(() {
      if (_selectedAnswers[questionId] == optionId) {
        // Toggle/deselect if clicked again
        _selectedAnswers.remove(questionId);
      } else {
        _selectedAnswers[questionId] = optionId;
      }
    });
  }

  void _toggleFlag(int questionId) {
    setState(() {
      if (_flaggedQuestionIds.contains(questionId)) {
        _flaggedQuestionIds.remove(questionId);
      } else {
        _flaggedQuestionIds.add(questionId);
      }
    });
  }

  void _goToQuestion(int index) {
    final all = _exam?.getAllQuestions() ?? [];
    if (index >= 0 && index < all.length) {
      setState(() {
        _currentQuestionIndex = index;
      });
    }
  }

  void _openSubmitDialog() {
    if (_exam == null) return;
    final all = _exam!.getAllQuestions();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SubmitConfirmationDialog(
        totalQuestions: all.length,
        answeredCount: _selectedAnswers.length,
        flaggedCount: _flaggedQuestionIds.length,
        onCancel: () => Navigator.of(ctx).pop(),
        onConfirm: () {
          Navigator.of(ctx).pop();
          _performSubmit();
        },
      ),
    );
  }

  void _performSubmit() async {
    if (_isSubmitting || _exam == null) return;
    setState(() {
      _isSubmitting = true;
    });

    _timer?.cancel();
    final timeSpent = (widget.durationMinutes * 60) - _remainingSeconds;

    final result = await _apiService.submitExam(
      examId: widget.examId,
      studentName: 'Jamie Kim',
      timeSpentSeconds: timeSpent,
      selectedAnswers: _selectedAnswers,
    );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ExamResultScreen(
            submissionId: result.id,
            exam: _exam!,
            userAnswers: _selectedAnswers,
            score: result.score,
            correctCount: result.correctCount,
            wrongCount: result.wrongCount,
            skippedCount: result.skippedCount,
            timeSpentSeconds: timeSpent,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _exam == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final allQuestions = _exam!.getAllQuestions();
    final currentQ = allQuestions.isNotEmpty ? allQuestions[_currentQuestionIndex] : null;
    final isWarningTime = _remainingSeconds <= 300; // less than 5 mins

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildWorkspaceAppBar(isWarningTime),
      body: Row(
        children: [
          // Left Accordion Palette
          QuestionPalette(
            exam: _exam!,
            currentQuestionIndex: _currentQuestionIndex,
            selectedAnswers: _selectedAnswers,
            flaggedQuestionIds: _flaggedQuestionIds,
            onQuestionSelected: (idx) => _goToQuestion(idx),
          ),

          // Main Center Workspace
          Expanded(
            child: Column(
              children: [
                // Workspace Content Area
                Expanded(
                  child: currentQ != null
                      ? _buildQuestionWorkspace(currentQ, allQuestions)
                      : const SizedBox.shrink(),
                ),

                // Bottom Navigation Bar
                _buildWorkspaceBottomBar(allQuestions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildWorkspaceAppBar(bool isWarningTime) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(68.0),
      child: Container(
        height: 68.0,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(color: AppColors.borderLight, width: 1.0),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Logo
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Reading Room',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'TOEIC READING EXAMS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Center Title
            Text(
              'TOEIC Reading • ${widget.examTitle}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            // Right Timer & Submit
            Row(
              children: [
                // Timer Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isWarningTime ? AppColors.dangerBg : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isWarningTime ? AppColors.danger : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: isWarningTime ? AppColors.danger : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'TIME REMAINING',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isWarningTime ? AppColors.danger : AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            _formatTimer(_remainingSeconds),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isWarningTime ? AppColors.danger : AppColors.textPrimary,
                              fontFeatures: const [],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // Submit Button
                OutlinedButton(
                  onPressed: _openSubmitDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Submit exam',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionWorkspace(ExamQuestion currentQ, List<ExamQuestion> allQuestions) {
    // Find question group
    QuestionGroup? currentGroup;
    for (var g in _exam!.questionGroups) {
      if (g.questions.any((q) => q.id == currentQ.id)) {
        currentGroup = g;
        break;
      }
    }

    final partType = currentGroup?.partType ?? 1;
    final hasPassage = currentGroup?.passageText != null && currentGroup!.passageText!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Part Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                partType == 1
                    ? 'Part 5   Incomplete sentences · 101–130'
                    : partType == 2
                        ? 'Part 6   Text completion · 131–146'
                        : 'Part 7   Reading comprehension · 147–200',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                partType == 1
                    ? 'Take your time. Read carefully.'
                    : partType == 2
                        ? 'Read the text and complete the sentences.'
                        : 'Questions ${currentGroup?.questions.first.questionNumber}–${currentGroup?.questions.last.questionNumber} · Related texts',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Content Area
          Expanded(
            child: hasPassage
                ? _buildSplitPassageAndQuestions(currentGroup, currentQ)
                : _buildSingleQuestionCard(currentQ),
          ),
        ],
      ),
    );
  }

  /// Single Question Card for Part 5
  Widget _buildSingleQuestionCard(ExamQuestion q) {
    final isFlagged = _flaggedQuestionIds.contains(q.id);
    final selectedOptId = _selectedAnswers[q.id];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category tag & Instructions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'INCOMPLETE SENTENCES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'Choose the best answer.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 24),

          // Question Number & Flag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUESTION ${q.questionNumber}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
              IconButton(
                onPressed: () => _toggleFlag(q.id),
                icon: Icon(
                  isFlagged ? Icons.flag : Icons.flag_outlined,
                  color: isFlagged ? AppColors.flagged : AppColors.textSecondary,
                  size: 20,
                ),
                tooltip: 'Flag for review',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Question Content
          Text(
            q.content,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          // Options List
          Expanded(
            child: ListView.separated(
              itemCount: q.answerOptions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final opt = q.answerOptions[idx];
                final isSelected = selectedOptId == opt.id;
                return _buildOptionRow(
                  label: opt.label,
                  content: opt.content,
                  isSelected: isSelected,
                  onTap: () => _selectOption(q.id, opt.id),
                );
              },
            ),
          ),

          // Saved Indicator & Helper text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (selectedOptId != null)
                Row(
                  children: const [
                    Icon(Icons.check, size: 16, color: AppColors.success),
                    SizedBox(width: 6),
                    Text(
                      'Answer saved',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),
              const Text(
                'Select one answer for each question. You can change it before submitting.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Split Layout for Part 6 & Part 7 (Independent pane scrolling)
  Widget _buildSplitPassageAndQuestions(QuestionGroup group, ExamQuestion currentQ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Pane: Passage
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUESTIONS ${group.questions.first.questionNumber}–${group.questions.last.questionNumber} / ${group.partType == 2 ? 'TEXT COMPLETION' : 'READING COMPREHENSION'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    group.passageText ?? '',
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                      height: 1.6,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 18),

        // Right Pane: Questions in this group
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(24),
            child: ListView.separated(
              itemCount: group.questions.length,
              separatorBuilder: (_, _) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(color: AppColors.borderLight),
              ),
              itemBuilder: (context, idx) {
                final q = group.questions[idx];
                final isFlagged = _flaggedQuestionIds.contains(q.id);
                final selectedOptId = _selectedAnswers[q.id];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'QUESTION ${q.questionNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _toggleFlag(q.id),
                          icon: Icon(
                            isFlagged ? Icons.flag : Icons.flag_outlined,
                            color: isFlagged ? AppColors.flagged : AppColors.textSecondary,
                            size: 18,
                          ),
                          tooltip: 'Flag for review',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      q.content,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...q.answerOptions.map((opt) {
                      final isSelected = selectedOptId == opt.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildOptionRow(
                          label: opt.label,
                          content: opt.content,
                          isSelected: isSelected,
                          onTap: () => _selectOption(q.id, opt.id),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionRow({
    required String label,
    required String content,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceSubtle : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.borderActive : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceBottomBar(List<ExamQuestion> allQuestions) {
    final currentQ = allQuestions.isNotEmpty ? allQuestions[_currentQuestionIndex] : null;
    final isFlagged = currentQ != null && _flaggedQuestionIds.contains(currentQ.id);
    final isLast = _currentQuestionIndex == allQuestions.length - 1;

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          OutlinedButton.icon(
            onPressed: _currentQuestionIndex > 0 ? () => _goToQuestion(_currentQuestionIndex - 1) : null,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Previous', style: TextStyle(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),

          // Flag button & Question status
          Row(
            children: [
              if (currentQ != null)
                TextButton.icon(
                  onPressed: () => _toggleFlag(currentQ.id),
                  icon: Icon(
                    isFlagged ? Icons.flag : Icons.flag_outlined,
                    size: 16,
                    color: isFlagged ? AppColors.flagged : AppColors.textSecondary,
                  ),
                  label: Text(
                    isFlagged ? 'Flagged for review' : 'Flag for review',
                    style: TextStyle(
                      color: isFlagged ? AppColors.flagged : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(width: 24),
              Text(
                'Question ${currentQ?.questionNumber ?? 1} · ${_currentQuestionIndex + 1} of ${allQuestions.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          // Next / Review button
          ElevatedButton.icon(
            onPressed: isLast ? _openSubmitDialog : () => _goToQuestion(_currentQuestionIndex + 1),
            icon: Text(
              isLast ? 'Review answers' : 'Next question',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            label: Icon(isLast ? Icons.check_circle_outline : Icons.arrow_forward, size: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }
}
