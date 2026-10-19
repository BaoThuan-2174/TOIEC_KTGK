import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/reading_room_header.dart';
import 'exam_workspace_screen.dart';
import 'exam_result_screen.dart';
import 'admin/admin_layout_screen.dart';

class ExamSelectionScreen extends StatefulWidget {
  const ExamSelectionScreen({super.key});

  @override
  State<ExamSelectionScreen> createState() => _ExamSelectionScreenState();
}

class _ExamSelectionScreenState extends State<ExamSelectionScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<ExamListItem>> _examsFuture;

  @override
  void initState() {
    super.initState();
    _examsFuture = _apiService.getPublishedExams();
  }

  void _startExam(ExamListItem examItem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExamWorkspaceScreen(
          examId: examItem.id,
          examTitle: examItem.title,
          durationMinutes: examItem.durationMinutes,
        ),
      ),
    );
  }

  void _openRecentResult() {
    // Open mock recent result for Practice 02
    final mockExam = ApiService.getMockExamDetail(2);
    final mockAnswers = <int, int>{};
    // Simulate 78 answers
    int counter = 0;
    for (var q in mockExam.getAllQuestions()) {
      if (counter++ < 78) {
        mockAnswers[q.id] = q.answerOptions.first.id;
      }
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExamResultScreen(
          submissionId: 102,
          exam: mockExam,
          userAnswers: mockAnswers,
          score: 78.0,
          correctCount: 78,
          wrongCount: 14,
          skippedCount: 8,
          timeSpentSeconds: 4210,
        ),
      ),
    );
  }

  void _openAdminPortal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AdminLayoutScreen(),
      ),
    ).then((_) {
      // Refresh danh sách bài thi đã xuất bản khi quay từ Admin portal
      // Học sinh sẽ thấy ngay bài thi mới được giảng viên vừa publish
      setState(() {
        _examsFuture = _apiService.getPublishedExams();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ReadingRoomHeader(
        onPracticeExamsTap: () {},
        onMyResultsTap: _openRecentResult,
        onAdminTap: _openAdminPortal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Hero Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'YOUR NEXT CHAPTER',
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
                            'Make room for progress.',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Welcome back, Jamie. Choose an exam and focus on what matters.',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right Score Metric Card
                    Container(
                      width: 220,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YOUR BEST READING SCORE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: const [
                              Text(
                                '86',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '/ 100',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.north_east,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Info Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Set aside 75 uninterrupted minutes. Your answers are saved automatically, and you can review them before submitting.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {},
                        child: Row(
                          children: const [
                            Text(
                              'How it works',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.north_east, size: 14, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Section Title Row
                FutureBuilder<List<ExamListItem>>(
                  future: _examsFuture,
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Choose your practice',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          snapshot.connectionState == ConnectionState.waiting
                              ? 'Đang tải...'
                              : '$count exam${count != 1 ? 's' : ''} available · All levels',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Exam Cards Grid
                FutureBuilder<List<ExamListItem>>(
                  future: _examsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      );
                    }

                    final exams = snapshot.data ?? ApiService.getMockExams();

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 0.88,
                          ),
                          itemCount: exams.length,
                          itemBuilder: (context, index) {
                            final exam = exams[index];
                            final isRecommended = index == 0;
                            return _buildExamCard(exam, isRecommended);
                          },
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Bottom Attempt Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.bar_chart_outlined, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Your latest attempt · Practice 02',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '12 Oct 2026 · 78 correct of 100 · 78% accuracy',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _openRecentResult,
                        icon: const Text(
                          'Review results',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                        label: const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamCard(ExamListItem exam, bool isRecommended) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRecommended ? AppColors.borderActive : AppColors.border,
          width: isRecommended ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Icon & Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu_book_outlined, color: AppColors.primary, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isRecommended ? AppColors.surfaceSubtle : AppColors.background,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isRecommended ? 'RECOMMENDED' : 'FULL PRACTICE TEST',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isRecommended ? AppColors.primary : AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Text(
            'TOEIC READING',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            exam.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              exam.description.isNotEmpty ? exam.description : 'Build confidence with authentic workplace passages, grammar and vocabulary.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 12),

          // Duration & Questions row
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${exam.durationMinutes} minutes',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.format_list_bulleted, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${exam.totalQuestions} questions',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 14),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Parts 5, 6 & 7',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _startExam(exam),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Text(
                  'Start exam',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                label: const Icon(Icons.arrow_forward, size: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
