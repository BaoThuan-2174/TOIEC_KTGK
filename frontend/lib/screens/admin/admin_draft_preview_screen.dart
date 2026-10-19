import 'package:flutter/material.dart';
import '../../models/exam_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

class AdminDraftPreviewScreen extends StatefulWidget {
  final int examId;
  final String examTitle;

  const AdminDraftPreviewScreen({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<AdminDraftPreviewScreen> createState() => _AdminDraftPreviewScreenState();
}

class _AdminDraftPreviewScreenState extends State<AdminDraftPreviewScreen> {
  final ApiService _apiService = ApiService();
  late Future<ExamDetail> _examFuture;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _examFuture = _apiService.getExamForAdminPreview(widget.examId);
  }

  Future<void> _publishExam() async {
    setState(() => _isPublishing = true);
    try {
      final success = await _apiService.publishExam(widget.examId, true);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đề thi đã được xuất bản cho học viên thành công!'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 3),
          ),
        );
        // Pop với true để admin layout biết cần refresh danh sách
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Xuất bản thất bại. Vui lòng kiểm tra kết nối và thử lại.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Admin Preview • ',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            Text(
              widget.examTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'TEACHER REVIEW MODE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _isPublishing ? null : _publishExam,
              icon: _isPublishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, size: 16),
              label: Text(_isPublishing ? 'Đang xuất bản...' : 'Publish this exam'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<ExamDetail>(
        future: _examFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final exam = snapshot.data;
          if (exam == null) {
            return const Center(child: Text('Không tìm thấy nội dung đề thi.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                exam.title,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${exam.totalQuestions} Questions · ${exam.durationMinutes} Minutes',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            exam.description,
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Groups List
                    ...exam.questionGroups.map((group) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'PART ${group.partType == 1 ? '5' : (group.partType == 2 ? '6' : '7')} · ORDER ${group.orderIndex}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.8),
                                ),
                                const Spacer(),
                                if (group.allowShuffleQuestions)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.shuffle, size: 12, color: Color(0xFF2563EB)),
                                        SizedBox(width: 4),
                                        Text(
                                          'Hoán vị câu hỏi: BẬT',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            if (group.passageText != null && group.passageText!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: SelectableText(
                                  group.passageText!,
                                  style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),

                            // Questions in Group
                            ...group.questions.map((q) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryDark,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Q${q.questionNumber}',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            q.content,
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                          ),
                                        ),
                                        if (q.allowShuffleAnswers)
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0FDF4),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: const Color(0xFFBBF7D0)),
                                            ),
                                            child: const Text(
                                              'Đảo đáp án: BẬT',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Answer Options
                                    ...q.answerOptions.map((opt) {
                                      final isCorrect = opt.isCorrect == true;
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isCorrect ? AppColors.surfaceSubtle : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isCorrect ? AppColors.borderActive : AppColors.borderLight,
                                            width: isCorrect ? 1.5 : 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              '(${opt.label})',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: isCorrect ? AppColors.primary : AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                opt.content,
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: isCorrect ? FontWeight.w600 : FontWeight.w400,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (isCorrect)
                                              Row(
                                                children: const [
                                                  Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Correct key',
                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      );
                                    }),

                                    if (q.explanation != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Explanation: ${q.explanation}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
