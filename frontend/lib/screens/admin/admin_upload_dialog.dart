import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import 'admin_draft_preview_screen.dart';

class AdminUploadDialog extends StatefulWidget {
  final VoidCallback onExamCreated;

  const AdminUploadDialog({super.key, required this.onExamCreated});

  static Future<void> show(BuildContext context, {required VoidCallback onExamCreated}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AdminUploadDialog(onExamCreated: onExamCreated),
    );
  }

  @override
  State<AdminUploadDialog> createState() => _AdminUploadDialogState();
}

class _AdminUploadDialogState extends State<AdminUploadDialog>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  PlatformFile? _selectedFile;
  bool _isUploading = false;
  bool _isDownloadingSample = false;
  List<String> _errorList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDocxFile() async {
    setState(() {
      _errorList.clear();
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx'],
        withData: true, // Required for Web & Desktop to get bytes in memory
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (!file.name.toLowerCase().endsWith('.docx')) {
          setState(() {
            _errorList = ['Chỉ chấp nhận file Word định dạng .docx.'];
          });
          return;
        }

        setState(() {
          _selectedFile = file;
        });
      }
    } catch (e) {
      setState(() {
        _errorList = ['Lỗi khi mở trình chọn file: $e'];
      });
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedFile == null) {
      setState(() {
        _errorList = ['Vui lòng chọn một file Word (.docx) trước khi tải lên.'];
      });
      return;
    }

    final bytes = _selectedFile!.bytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() {
        _errorList = ['File được chọn không chứa dữ liệu. Vui lòng chọn lại.'];
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorList.clear();
    });

    final result = await _apiService.uploadExamDocx(
      fileName: _selectedFile!.name,
      fileBytes: bytes,
    );

    if (!mounted) return;

    setState(() {
      _isUploading = false;
    });

    if (result.isSuccess && result.examId != null) {
      widget.onExamCreated();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Import thành công: ${result.examTitle ?? "Đề thi mới"} (${result.totalQuestions} câu hỏi)!',
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 4),
        ),
      );

      // Mở màn hình Teacher Review đề thi vừa import
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminDraftPreviewScreen(
            examId: result.examId!,
            examTitle: result.examTitle ?? 'Bản nháp đề thi',
          ),
        ),
      );
    } else {
      setState(() {
        _errorList = result.errors.isNotEmpty
            ? result.errors
            : ['Đã xảy ra lỗi không xác định trong quá trình xử lý đề thi.'];
      });
    }
  }

  Future<void> _handleDownloadSample() async {
    setState(() {
      _isDownloadingSample = true;
    });

    final bytes = await _apiService.downloadSampleDocx();

    setState(() {
      _isDownloadingSample = false;
    });

    if (!mounted) return;

    if (bytes != null && bytes.isNotEmpty) {
      try {
        if (!kIsWeb) {
          final savePath = await FilePicker.platform.saveFile(
            dialogTitle: 'Chọn nơi lưu file Word mẫu TOEIC',
            fileName: 'Mau_De_Thi_TOEIC_Reading_Chuan.docx',
            type: FileType.custom,
            allowedExtensions: ['docx'],
            bytes: Uint8List.fromList(bytes),
          );

          if (savePath != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã lưu file mẫu thành công: $savePath'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã tải file mẫu về máy thành công!'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu file: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tải file mẫu từ backend. Vui lòng kiểm tra kết nối.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Tab navigation
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.cloud_upload_outlined, size: 18), text: 'Tải Lên File Word (.docx)'),
                  Tab(icon: Icon(Icons.code, size: 18), text: 'Quy Chuẩn Bộ Thẻ (Tags a-e)'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUploadTab(),
                  _buildTagSpecificationTab(),
                ],
              ),
            ),

            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.article_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Import Đề Thi TOEIC Reading Từ File Word',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Chuyển đổi file đề thi PDF sang Word .docx có định nghĩa bộ thẻ tags chuẩn',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              border: Border.all(color: const Color(0xFFBBF7D0)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_outlined, color: Color(0xFF16A34A), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Yêu cầu chuẩn TOEIC Reading (.docx)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'File Word cần được gắn các thẻ quy chuẩn: [EXAM_TITLE], [PART: 5/6/7], [Q: 101], [A]..[D], [KEY: A/B/C/D], [HINT: ...], cùng các thẻ hoán vị câu hỏi [SHUFFLE_QUESTIONS] và đáp án [SHUFFLE_ANSWERS].',
                        style: TextStyle(fontSize: 12, color: Color(0xFF15803D), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pick Box Area
          InkWell(
            onTap: _pickDocxFile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                border: Border.all(
                  color: _selectedFile != null ? AppColors.primary : AppColors.border,
                  width: _selectedFile != null ? 2 : 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _selectedFile != null ? Icons.check_circle : Icons.upload_file_outlined,
                      size: 36,
                      color: _selectedFile != null ? const Color(0xFF10B981) : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _selectedFile != null
                        ? 'Đã chọn: ${_selectedFile!.name}'
                        : 'Bấm vào đây để chọn file Word (.docx) đề thi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _selectedFile != null ? AppColors.textPrimary : AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedFile != null
                        ? 'Dung lượng: ${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB • Bấm để đổi file khác'
                        : 'Chấp nhận định dạng chuẩn Microsoft Word (.docx)',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Download sample button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _isDownloadingSample ? null : _handleDownloadSample,
                icon: _isDownloadingSample
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(Icons.download_for_offline_outlined, size: 16, color: AppColors.primary),
                label: const Text(
                  'Tải file Word mẫu chuẩn (.docx)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
              if (_selectedFile != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedFile = null;
                      _errorList.clear();
                    });
                  },
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text(
                    'Hủy chọn',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
            ],
          ),

          // Errors list if any
          if (_errorList.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: const Color(0xFFFECACA)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Phát hiện ${_errorList.length} lỗi cấu trúc trong file:',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._errorList.map(
                    (err) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              err,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D), height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Lưu ý: Hệ thống đã huỷ bỏ toàn bộ và KHÔNG lưu đề thi bị lỗi vào CSDL nhằm đảm bảo tính toàn vẹn dữ liệu.',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF991B1B)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagSpecificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quy Định Bộ Thẻ (Tags) Chuẩn Cho Đề Thi TOEIC Reading (.docx)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chương trình yêu cầu tuân thủ cấu trúc thẻ sau để hệ thống tự động đọc và phân tích đề thi:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          _buildTagCard(
            category: 'a) Nội dung đề thi & Câu trả lời',
            tags: [
              '[EXAM_TITLE: <Tên đề thi>] (Bắt buộc ở đầu file)',
              '[EXAM_DURATION: <Số phút>] (Mặc định: 75)',
              '[PART: 5], [PART: 6], [PART: 7] (Phần thi)',
              '[GROUP_START] & [GROUP_END] (Nhóm bài đọc Part 6, 7)',
              '[PASSAGE_START] ... [PASSAGE_END] (Nội dung đoạn văn)',
              '[IMAGE: <đường_dẫn_ảnh>] (Hình ảnh đính kèm bài đọc)',
              '[Q: 101] <Nội dung câu hỏi>',
              '[A] <Nội dung phương án A>',
              '[B] <Nội dung phương án B>',
              '[C] <Nội dung phương án C>',
              '[D] <Nội dung phương án D>',
            ],
            example: '[PART: 5]\n[Q: 101] Ms. Durkin asked for volunteers to help --------.\n[A] she\n[B] her\n[C] hers\n[D] herself',
          ),
          const SizedBox(height: 14),

          _buildTagCard(
            category: 'b) Đáp án đúng',
            tags: [
              '[KEY: A | B | C | D]',
              'Hỗ trợ thẻ tương đương: [CORRECT: A], [ANSWER: A], [DAP_AN: A]',
              'Quy định: Mỗi câu hỏi BẮT BUỘC có duy nhất 1 đáp án đúng.',
            ],
            example: '[KEY: D]',
          ),
          const SizedBox(height: 14),

          _buildTagCard(
            category: 'c) Gợi ý câu trả lời & Giải thích',
            tags: [
              '[HINT: <Nội dung giải thích / từ vựng / ngữ pháp>]',
              'Hỗ trợ thẻ tương đương: [EXPLAIN: ...], [GOI_Y: ...]',
              'Chức năng: Cung cấp giải thích chi tiết khi học viên xem lại bài thi sau khi nộp.',
            ],
            example: '[HINT: Đại từ phản thân "herself" làm tân ngữ cho động từ help khi chủ ngữ tự giúp mình.]',
          ),
          const SizedBox(height: 14),

          _buildTagCard(
            category: 'd) Tags cho phép hoán vị câu hỏi',
            tags: [
              '[SHUFFLE_QUESTIONS: TRUE | FALSE]',
              'Hỗ trợ thẻ tương đương: [HOAN_VI_CAU_HOI: TRUE | FALSE]',
              'Vị trí đặt: Đặt ở đầu Part hoặc bên trong từng nhóm [GROUP_START].',
              'Tác dụng: Khi sinh viên bắt đầu làm bài, danh sách câu hỏi sẽ được xáo trộn ngẫu nhiên.',
            ],
            example: '[SHUFFLE_QUESTIONS: TRUE]',
          ),
          const SizedBox(height: 14),

          _buildTagCard(
            category: 'e) Tags cho phép hoán vị câu trả lời',
            tags: [
              '[SHUFFLE_ANSWERS: TRUE | FALSE]',
              'Hỗ trợ thẻ tương đương: [HOAN_VI_DAP_AN: TRUE | FALSE]',
              'Vị trí đặt: Đặt ở đầu Part hoặc trước từng câu hỏi [Q: ...].',
              'Tác dụng: Tự động xáo trộn vị trí 4 phương án A, B, C, D khi làm bài và vẫn giữ đúng đáp án chấm điểm.',
            ],
            example: '[SHUFFLE_ANSWERS: TRUE]',
          ),
        ],
      ),
    );
  }

  Widget _buildTagCard({
    required String category,
    required List<String> tags,
    required String example,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          ...tags.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              example,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _selectedFile != null ? '1 file đã sẵn sàng để thẩm định' : 'Chưa có file nào được chọn',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Row(
            children: [
              TextButton(
                onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isUploading || _selectedFile == null ? null : _handleUpload,
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload, size: 16),
                label: Text(_isUploading ? 'Đang phân tích file...' : 'Tải lên & Thẩm định đề thi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
